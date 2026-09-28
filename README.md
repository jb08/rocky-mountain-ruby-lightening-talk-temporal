# Rocky Mountain Ruby 2026 Demo: Sidekiq vs. Temporal

A side-by-side demo comparing two ways to orchestrate a multi-step background
check process:

* **Sidekiq** -- plain jobs that chain themselves via `perform_async`, with a
  `BackgroundCheckRun` Postgres record tracking saga state.
* **Temporal** -- a single `BackgroundCheckWorkflow` orchestrating Temporal
  Activities, with no DB table needed for state.

Every step just returns a mocked string -- there's no real screening logic or
real PII here, only the orchestration plumbing.

## Requirements

* Ruby 3.4.7 (see `.ruby-version`)
* Docker (for Postgres, Redis, and the Temporal server/UI)

## 1. Install gems

```
bundle install
```

## 2. Start the infrastructure

```
docker compose up -d
```

This brings up:

| Service                | Purpose                              | Address                 |
|-------------------------|---------------------------------------|--------------------------|
| `postgres`              | App database                         | `localhost:5432`        |
| `redis`                 | Sidekiq backend                      | `localhost:6379`        |
| `temporal-postgresql`   | Temporal server's own persistence    | (internal only)         |
| `temporal`              | Temporal server                      | `localhost:7233`        |
| `temporal-ui`           | Temporal Web UI                      | `http://localhost:8080` |

Give the `temporal` container a few seconds to finish its schema auto-setup
before starting a workflow (`docker compose logs temporal` to watch it).

## 3. Prepare the database

```
bin/rails db:prepare
```

## 4. Run the app

You'll need three processes running in separate terminals:

```
bin/rails server                            # Rails app on http://localhost:3000
bundle exec sidekiq -r ./config/environment.rb   # Sidekiq worker
bundle exec ruby script/temporal_worker.rb       # Temporal worker
```

## 5. Try it out

**Sidekiq path:**

```
curl -X POST localhost:3000/sidekiq_background_checks -d candidate_name="Jamie Rivera"
# => { "id": 1, "status": "pending", ... }

curl localhost:3000/sidekiq_background_checks/1
# poll until "status": "completed" -- every step's mocked result is included
```

**Temporal path:**

```
curl -X POST localhost:3000/temporal_background_checks -d candidate_name="Jamie Rivera"
# => { "workflow_id": "background-check-...", "run_id": "..." }

curl localhost:3000/temporal_background_checks/background-check-...
# poll until "status": "completed"
```

Open `http://localhost:8080` to watch the Temporal workflow's event history
and timeline live -- this is the other half of the demo.

## Tracing with Honeycomb (optional)

The Temporal side can export a full distributed trace of each workflow run
(`StartWorkflow` -> `RunWorkflow` -> one nested `RunActivity` span per step)
to [Honeycomb.io](https://honeycomb.io) via OpenTelemetry. This is entirely
additive: with no Honeycomb key configured, tracing is simply off and
everything else behaves exactly as documented above.

1. Copy the template and fill in your real key:

   ```
   cp .env.example .env.local
   ```

   Get `HONEYCOMB_API_KEY` from Honeycomb: Team Settings -> Environments ->
   Manage API Keys. `.env.local` is git-ignored -- never commit a real key.

2. `bundle install` (pulls in `dotenv-rails`, `opentelemetry-sdk`, and
   `opentelemetry-exporter-otlp`).

3. Restart `rails server`, `sidekiq`, and `script/temporal_worker.rb` so they
   pick up the new environment variables.

4. Kick off a `/temporal_background_checks` run as usual, then open
   Honeycomb and look at the dataset named by `OTEL_SERVICE_NAME`
   (`rocky-mountain-ruby-demo` by default). Each workflow run shows up as one
   trace: `StartWorkflow` from the Rails client, then `RunWorkflow` and eight
   `RunActivity` spans from the worker, all correlated and timed.

This is wired in via the `temporalio` gem's built-in
`Temporalio::Contrib::OpenTelemetry::TracingInterceptor` -- no third-party
shim needed, just the standard OTel Ruby SDK + OTLP exporter alongside it
(see `app/temporal/telemetry.rb` and `config/initializers/opentelemetry.rb`).

Notice the Sidekiq path has no equivalent here -- getting comparable tracing
across a chain of `perform_async` calls would mean hand-rolling span
propagation across job boundaries yourself.

## Running the test suite

```
bin/rails test
```

## Stopping

```
docker compose down        # stop and remove containers (add -v to also wipe data volumes)
```
