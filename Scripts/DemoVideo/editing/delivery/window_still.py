"""Cuts the app window out of the footage at one video moment, at the take's full 2x resolution, with rounded
corners on the social card's paper color. docs/images/demo-split-view.jpg, the social card's image, is 28.0.

Usage: python -m delivery.window_still <seconds> <output.jpg>
"""
import json
import os
import sys

from PIL import Image, ImageDraw

from paths import TIMELINE
from render.source_frames import SourceFrames
from timeline.time_mapping import source_time

# The window's corner radius in the 2x take, measured where the stage shows through.
CORNER_RADIUS = 31
SUPERSAMPLE = 4
PAPER = (252, 251, 248)
OUTPUT_SIZE = (2400, 1350)


def window_box():
    """The window's rectangle in take pixels, from the stage and window frames in settings.sh."""
    stage_x, stage_y = map(float, os.environ["DEMO_STAGE"].split()[:2])
    x, y, width, height = map(float, os.environ["DEMO_WINDOW_FRAME"].split())
    return tuple(round(value * 2) for value in (x - stage_x, y - stage_y, x - stage_x + width, y - stage_y + height))


def window_still(seconds):
    timeline = json.loads(TIMELINE.read_text())
    scene = next(scene for scene in timeline["scenes"] if scene["start"] <= seconds < scene["start"] + scene["duration"])
    assert "take" in scene, "stills come from footage, not the cards"
    wanted = source_time(scene["pieces"], seconds - scene["start"])
    source = SourceFrames(scene["take"], wanted, wanted + 0.1)
    try:
        window = source.frame_at(wanted).crop(window_box())
    finally:
        source.close()
    width, height = window.size
    mask = Image.new("L", (width * SUPERSAMPLE, height * SUPERSAMPLE), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, width * SUPERSAMPLE - 1, height * SUPERSAMPLE - 1),
                                           radius=CORNER_RADIUS * SUPERSAMPLE, fill=255)
    mask = mask.resize((width, height), Image.LANCZOS)
    paper = Image.new("RGB", (width, height), PAPER)
    return Image.composite(window, paper, mask).resize(OUTPUT_SIZE, Image.LANCZOS, reducing_gap=3.0)


if __name__ == "__main__":
    window_still(float(sys.argv[1])).save(sys.argv[2], quality=90, optimize=True, progressive=True, subsampling=0)
    print(f"wrote {sys.argv[2]}")
