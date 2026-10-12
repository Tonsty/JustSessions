"""Renders one video moment without its caption, for the website poster, saved at the size the homepage serves.

Usage: python -m render.poster_frame <seconds> <output.jpg>
"""
import json
import sys

from paths import TIMELINE
from render.compose_frame import footage_frame
from render.source_frames import SourceFrames
from timeline.time_mapping import source_time


def poster_frame(seconds):
    timeline = json.loads(TIMELINE.read_text())
    scene = next(scene for scene in timeline["scenes"] if scene["start"] <= seconds < scene["start"] + scene["duration"])
    assert "take" in scene, "posters come from footage, not the cards"
    time = seconds - scene["start"]
    wanted = source_time(scene["pieces"], time)
    source = SourceFrames(scene["take"], wanted, wanted + 0.1)
    try:
        return footage_frame(source.frame_at(wanted), scene, time, captions=[])
    finally:
        source.close()


if __name__ == "__main__":
    poster_frame(float(sys.argv[1])).save(sys.argv[2], quality=82, optimize=True, progressive=True)
    print(f"wrote {sys.argv[2]}")
