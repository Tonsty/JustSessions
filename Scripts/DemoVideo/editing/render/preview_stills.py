"""Renders single frames at chosen video times, for checking framing and overlays without a full render.

Usage: python -m render.preview_stills <seconds> ...   writes $DEMO_WORK/build/stills/<seconds>.png
"""
import json
import sys

from paths import BUILD, TIMELINE
from render.compose_frame import card_frame, footage_frame
from render.source_frames import SourceFrames
from timeline.time_mapping import source_time


def still_at(timeline, moment):
    scene = next(scene for scene in timeline["scenes"] if scene["start"] <= moment < scene["start"] + scene["duration"])
    time = moment - scene["start"]
    if "card" in scene:
        return card_frame(scene, time)
    source_moment = source_time(scene["pieces"], time)
    source = SourceFrames(scene["take"], source_moment, source_moment + 0.05)
    try:
        return footage_frame(source.frame_at(source_moment), scene, time, timeline["captions"])
    finally:
        source.close()


def main():
    timeline = json.loads(TIMELINE.read_text())
    folder = BUILD / "stills"
    folder.mkdir(parents=True, exist_ok=True)
    for argument in sys.argv[1:]:
        path = folder / f"{float(argument):06.2f}.png"
        still_at(timeline, float(argument)).save(path)
        print(path)


if __name__ == "__main__":
    main()
