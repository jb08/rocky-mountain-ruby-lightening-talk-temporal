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

## Running the test suite

```
bin/rails test
```

## Stopping

```
docker compose down        # stop and remove containers (add -v to also wipe data volumes)
```
