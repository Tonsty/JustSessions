"""Where the edit reads and writes. The scripts and the edit plan live here in git; everything generated lives in
the work folder (DEMO_WORK in settings.sh)."""
import os
from pathlib import Path

if "DEMO_WORK" not in os.environ:
    raise SystemExit("Run this through Scripts/DemoVideo/demo-video, which sets DEMO_WORK.")

EDITING = Path(__file__).resolve().parent
BRANDING = EDITING.parents[2] / "Branding/PNG"
NARRATION_LINES = EDITING / "voiceover/lines.json"

WORK = Path(os.environ["DEMO_WORK"])
TAKES = WORK / "takes"
CLICKS = WORK / "clicks.json"
VOICE_AUDIO = WORK / "voiceover"
KOKORO_MODELS = WORK / "models/kokoro"
BUILD = WORK / "build"
TIMELINE = BUILD / "timeline.json"
OUTPUT = WORK / "output"
MASTER = OUTPUT / "JustSessions-demo.mp4"
