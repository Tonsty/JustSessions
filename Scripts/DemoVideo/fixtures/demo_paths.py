"""Where the fixtures write: the demo home and the work folder, as set in settings.sh."""
import os
from pathlib import Path

if "DEMO_HOME" not in os.environ:
    raise SystemExit("Run this through Scripts/DemoVideo/demo-video, which sets DEMO_HOME and DEMO_WORK.")

HOME = Path(os.environ["DEMO_HOME"])
WORK = Path(os.environ["DEMO_WORK"])
PROJECTS = HOME / "Projects"
CLAUDE_DIRECTORY = HOME / ".claude"
MODEL_SERVER = f"http://127.0.0.1:{os.environ['DEMO_MODEL_PORT']}/v1"
# The demo user's home on the VM, built here first and copied there by recording/reset_demo.sh.
REMOTE_STAGING = WORK / "remote-home"
REMOTE_HOME_PATH = f"/home/{os.environ['DEMO_REMOTE_USER']}"
# What fixtures/other_cli_sessions.sh generated, restored before every take.
SESSION_SNAPSHOT = WORK / "session-snapshot"
