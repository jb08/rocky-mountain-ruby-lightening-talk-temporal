"""
DBOS worker for the background check demo. Defines every step and the
workflow that chains them, then blocks forever polling Postgres for work --
the DBOS analog of `bundle exec sidekiq` or `script/temporal_worker.rb`.

Unlike Sidekiq (needs Redis) or Temporal (needs its own server), DBOS needs
nothing but a Postgres database: durability comes from a "dbos" schema this
process creates in whatever database SYSTEM_DATABASE_URL points at. This
demo reuses the same Postgres container docker-compose already runs for the
Rails app, just the default "postgres" maintenance database instead of the
app's own one, to avoid needing a second container.
"""

import itertools
import os
import threading
from pathlib import Path

from dbos import DBOS, DBOSConfig
from dotenv import load_dotenv

# Same .env.local the Rails app's dotenv-rails loads, one directory up --
# a single shared source of truth for local secrets across every engine in
# this demo.
load_dotenv(Path(__file__).resolve().parent.parent / ".env.local")

SYSTEM_DATABASE_URL = os.environ.get(
    "DBOS_SYSTEM_DATABASE_URL",
    "postgresql://rocky_mountain_ruby:rocky_mountain_ruby@localhost:5432/postgres",
)

ALIASES = ["Jane A. Smith", "Jane Doe"]
JURISDICTIONS = ["Los Angeles County, CA", "Kings County, NY"]

config: DBOSConfig = {
    "name": "background-check-dbos-worker",
    "system_database_url": SYSTEM_DATABASE_URL,
}

# Optional: report to a self-hosted DBOS Conductor (see README) so you can
# watch workflows in its web UI instead of just the terminal. Absent these
# env vars, this is a no-op -- same pattern as the Honeycomb integration.
DBOS(
    config=config,
    conductor_url=os.environ.get("DBOS_CONDUCTOR_URL"),
    conductor_key=os.environ.get("DBOS_CONDUCTOR_KEY"),
)


@DBOS.step()
def find_former_names(candidate_name: str) -> str:
    return f"Found former names for {candidate_name}: Jane A. Smith, Jane Doe"


@DBOS.step()
def find_jurisdictions(candidate_name: str) -> str:
    return f"Jurisdictions to search for {candidate_name}: Los Angeles County CA, Kings County NY"


@DBOS.step()
def send_search(alias_name: str, jurisdiction: str) -> str:
    return f"Search complete for {alias_name} in {jurisdiction}: no records found (via Python/DBOS worker)"


@DBOS.step()
def evaluate_results(search_results: list) -> str:
    return f"Evaluation: all {len(search_results)} searches clear, no adverse records found"


@DBOS.step()
def compare_against_customer_assessments(evaluation: str) -> str:
    return f"Comparison: evaluation matches customer's stated assessment criteria ({evaluation})"


@DBOS.step()
def request_candidate_story(candidate_name: str) -> str:
    return f"Candidate story requested from {candidate_name}: awaiting response, none required based on evaluation"


@DBOS.step()
def notify_customer_and_candidate(candidate_name: str) -> str:
    return f"Notified customer and {candidate_name}: report is complete and available"


@DBOS.step()
def handle_possible_fcra_dispute(candidate_name: str) -> str:
    return f"FCRA dispute check for {candidate_name}: no dispute filed, process complete"


@DBOS.workflow()
def background_check_workflow(candidate_name: str) -> dict:
    lookup_queue = DBOS.retrieve_queue("background-check-lookups")
    names_handle = lookup_queue.enqueue(find_former_names, candidate_name)
    jurisdictions_handle = lookup_queue.enqueue(find_jurisdictions, candidate_name)
    former_names = names_handle.get_result()
    jurisdictions = jurisdictions_handle.get_result()

    search_queue = DBOS.retrieve_queue("background-check-searches")
    search_handles = [
        search_queue.enqueue(send_search, alias_name, jurisdiction)
        for alias_name, jurisdiction in itertools.product(ALIASES, JURISDICTIONS)
    ]
    search_results = [handle.get_result() for handle in search_handles]

    evaluation = evaluate_results(search_results)
    comparison = compare_against_customer_assessments(evaluation)
    candidate_story = request_candidate_story(candidate_name)
    notification = notify_customer_and_candidate(candidate_name)
    dispute_handling = handle_possible_fcra_dispute(candidate_name)

    return {
        "former_names": former_names,
        "jurisdictions": jurisdictions,
        "search_results": search_results,
        "evaluation": evaluation,
        "comparison": comparison,
        "candidate_story": candidate_story,
        "notification": notification,
        "dispute_handling": dispute_handling,
    }


if __name__ == "__main__":
    DBOS.launch()

    # Concurrency limits are declared per queue -- worker_concurrency=2 here
    # is a deliberate demo touch: watch only 2 of the 4 searches run at once.
    DBOS.register_queue("background-check-workflows")
    DBOS.register_queue("background-check-lookups")
    DBOS.register_queue("background-check-searches", worker_concurrency=2)

    print("DBOS worker launched, polling Postgres for background check workflows...")
    threading.Event().wait()
