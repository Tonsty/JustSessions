"""Gives the Codex and Pi sample sessions short names, the way each CLI records a rename."""
import json
from datetime import datetime, timezone
from pathlib import Path

from demo_paths import HOME
CODEX_NAMES = {"Refactor the settings page": "Split settings page", "Migrate the database": "Postgres 17 migration"}
PI_NAME = "README install steps"

now = datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")
index_lines = []
for rollout in sorted((HOME / ".codex/sessions").rglob("rollout-*.jsonl")):
    text = rollout.read_text()
    session_id = json.loads(text.splitlines()[0])["payload"]["id"]
    for prompt_start, name in CODEX_NAMES.items():
        if prompt_start in text:
            index_lines.append(json.dumps({"id": session_id, "thread_name": name, "updated_at": now}))
(HOME / ".codex/session_index.jsonl").write_text("\n".join(index_lines) + "\n")
for session in (HOME / ".pi/agent/sessions").rglob("*.jsonl"):
    lines = [line for line in session.read_text().splitlines() if '"session_info"' not in line]
    last = json.loads(lines[-1])
    lines.append(json.dumps({"type": "session_info", "id": "info0001", "parentId": last.get("id"), "timestamp": now,
                             "name": PI_NAME}))
    session.write_text("\n".join(lines) + "\n")
print("\n".join(index_lines))
