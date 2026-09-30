"""
Starts one background check run via DBOS -- the DBOS analog of a
`curl -X POST .../sidekiq_background_checks` or `.../temporal_background_checks`
call. Talks to worker.py only through Postgres (DBOSClient), never by
importing its code directly -- the same decoupled enqueuer/worker split as
https://docs.dbos.dev/python/examples/queue-worker. Run worker.py first, in
another terminal, then run this.
"""

import os
import sys
from pathlib import Path

from dbos import DBOSClient, EnqueueOptions
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent.parent / ".env.local")

SYSTEM_DATABASE_URL = os.environ.get(
    "DBOS_SYSTEM_DATABASE_URL",
    "postgresql://rocky_mountain_ruby:rocky_mountain_ruby@localhost:5432/postgres",
)

candidate_name = sys.argv[1] if len(sys.argv) > 1 else "Jamie Rivera"

client = DBOSClient(system_database_url=SYSTEM_DATABASE_URL)

options: EnqueueOptions = {
    "workflow_name": "background_check_workflow",
    "queue_name": "background-check-workflows",
}
handle = client.enqueue(options, candidate_name)

print(f"Enqueued workflow {handle.get_workflow_id()} for {candidate_name!r}, waiting for it to complete...")
result = handle.get_result()

print()
for key, value in result.items():
    print(f"{key}: {value}")
