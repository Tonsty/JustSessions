"""Gives the Codex, OpenCode, and Pi sample sessions believable ages again; resuming them on camera bumps their times."""
import json
import os
import sqlite3
import time
from datetime import datetime, timedelta, timezone

from demo_paths import HOME

CODEX_AGES_IN_MINUTES = {"Split settings page": 21, "Postgres 17 migration": 26}
OPENCODE_AGE_IN_MINUTES = 70
PI_AGE_IN_MINUTES = 120


def minutes_ago(minutes):
    return datetime.now(timezone.utc) - timedelta(minutes=minutes)


def reset_codex():
    index_path = HOME / ".codex/session_index.jsonl"
    records = [json.loads(line) for line in index_path.read_text().splitlines() if line.strip()]
    for record in records:
        moment = minutes_ago(CODEX_AGES_IN_MINUTES[record["thread_name"]])
        record["updated_at"] = moment.isoformat(timespec="milliseconds").replace("+00:00", "Z")
        for rollout in (HOME / ".codex/sessions").rglob(f"rollout-*{record['id']}.jsonl"):
            os.utime(rollout, (moment.timestamp(), moment.timestamp()))
    index_path.write_text("".join(json.dumps(record) + "\n" for record in records))


def reset_opencode():
    database = sqlite3.connect(HOME / ".local/share/opencode/opencode.db")
    updated_at = int((time.time() - OPENCODE_AGE_IN_MINUTES * 60) * 1000)
    database.execute("update session set time_updated = ?", (updated_at,))
    database.commit()


def reset_pi():
    moment = minutes_ago(PI_AGE_IN_MINUTES).timestamp()
    for session in (HOME / ".pi/agent/sessions").rglob("*.jsonl"):
        os.utime(session, (moment, moment))


if __name__ == "__main__":
    reset_codex()
    reset_opencode()
    reset_pi()
    print("session times reset")
