"""Builds the demo user's home for the VM here: one project with a long-running script, and its Claude Code sessions.

recording/reset_demo.sh copies it to the VM before every take.
"""
import json
import shutil
from datetime import datetime, timedelta, timezone

from claude_transcript import ClaudeTranscript, short_session
from cli_configs import CLAUDE_SETTINGS, claude_config
from demo_paths import REMOTE_HOME_PATH, REMOTE_STAGING

# The Claude Code version installed on the VM, which its sessions record.
REMOTE_CLAUDE_VERSION = "2.1.295"
PROJECT_PATH = f"{REMOTE_HOME_PATH}/ingest-service"

WORKER_BEFORE = """import json
from .storage import save_event


def ingest(batch):
    for line in batch:
        event = json.loads(line)
        save_event(event)
"""

WORKER_OLD = """    for line in batch:
        event = json.loads(line)
        save_event(event)"""
WORKER_NEW = """    events = [json.loads(line) for line in batch]
    save_events(events)  # one insert per batch"""

# The long job started on camera; it prints progress for about 30 seconds.
BACKFILL_SCRIPT = '''"""Replays a day of events through the ingest pipeline and reports progress."""
import time

TOTAL = 48_000
BATCH = 400
for done in range(BATCH, TOTAL + 1, BATCH):
    time.sleep(0.25)
    percent = done * 100 // TOTAL
    bar = "█" * (percent // 5) + "░" * (20 - percent // 5)
    print(f"backfill  {bar}  {done:>6,} / {TOTAL:,} events", flush=True)
print("backfill complete", flush=True)
'''


def profiling_session(started_at):
    transcript = ClaudeTranscript(PROJECT_PATH, "7b2d1f63-4e8a-4c9f-8b62-3c8d5f1e2b01", started_at)
    transcript.user("The ingest worker is slow on big batches. Profile it and fix the hot spot.")
    transcript.bash("python -m cProfile -s cumtime worker.py --batch fixtures/10k.jsonl | head -6",
                    "Profile one large batch",
                    "   ncalls  cumtime  filename:lineno(function)\n"
                    "    10000   11.902  storage.py:14(save_event)\n"
                    "    10000    0.311  __init__.py:299(loads)\n"
                    "        1   12.401  worker.py:5(ingest)")
    transcript.text("96% of the time is `save_event`: one database round trip per event. I'll batch the inserts.")
    transcript.edit("ingest/worker.py", WORKER_BEFORE, WORKER_OLD, WORKER_NEW)
    transcript.bash("python worker.py --batch fixtures/10k.jsonl --time", "Time the batch again",
                    "ingested 10000 events in 3.1s (was 12.4s)")
    transcript.text("Fixed. Inserts are batched, so 10k events take **3.1s instead of 12.4s**. Tests still pass.")
    return transcript


def main():
    if REMOTE_STAGING.exists():
        shutil.rmtree(REMOTE_STAGING)
    claude_directory = REMOTE_STAGING / ".claude"
    now = datetime.now(timezone.utc)
    for transcript, title in [
        (profiling_session(now - timedelta(minutes=35)), "Speed up ingest worker"),
        (short_session(PROJECT_PATH, "7b2d1f63-4e8a-4c9f-8b62-3c8d5f1e2b02", now - timedelta(hours=5),
                       "Rotate the nightly logs and keep two weeks.",
                       "Added a logrotate rule: daily, 14 days kept, compressed after one day."), "Rotate nightly logs"),
    ]:
        for record in transcript.records:
            record["version"] = REMOTE_CLAUDE_VERSION
        transcript.save(claude_directory, title=title)
    project = REMOTE_STAGING / "ingest-service"
    (project / "ingest").mkdir(parents=True)
    (project / "ingest/worker.py").write_text(WORKER_BEFORE)
    (project / "README.md").write_text("# ingest-service\n")
    (project / "scripts").mkdir()
    (project / "scripts/backfill.py").write_text(BACKFILL_SCRIPT)
    (REMOTE_STAGING / ".claude.json").write_text(json.dumps(claude_config([PROJECT_PATH], 9), indent=2))
    (claude_directory / "settings.json").write_text(json.dumps(CLAUDE_SETTINGS, indent=2))
    print(REMOTE_STAGING)


if __name__ == "__main__":
    main()
