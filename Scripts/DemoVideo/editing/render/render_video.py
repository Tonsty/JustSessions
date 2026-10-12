"""Renders every scene in parallel, then joins them into $DEMO_WORK/build/video.mp4 without re-encoding.

Usage: python -m render.render_video [scene name ...]   (names re-render only those scenes)
"""
import json
import subprocess
import sys
import time
from concurrent.futures import ProcessPoolExecutor

from paths import BUILD, TIMELINE
from render.render_scene import render_scene

SCENE_FOLDER = BUILD / "scenes"


def scene_path(index, scene):
    return SCENE_FOLDER / f"{index:02d}-{scene['name']}.mp4"


def render_one(arguments):
    timeline, index = arguments
    scene = timeline["scenes"][index]
    started = time.time()
    frames = render_scene(timeline, scene, scene_path(index, scene))
    return f"{scene['name']}: {frames} frames in {time.time() - started:.0f}s"


def main():
    timeline = json.loads(TIMELINE.read_text())
    SCENE_FOLDER.mkdir(parents=True, exist_ok=True)
    only = set(sys.argv[1:])
    indexes = [index for index, scene in enumerate(timeline["scenes"]) if not only or scene["name"] in only]
    # Longest scenes first, so the pool finishes together.
    indexes.sort(key=lambda index: -timeline["scenes"][index]["duration"])
    with ProcessPoolExecutor(max_workers=5) as pool:
        for message in pool.map(render_one, [(timeline, index) for index in indexes]):
            print(message, flush=True)
    listing = BUILD / "scenes.txt"
    listing.write_text("".join(f"file '{scene_path(index, scene)}'\n" for index, scene in enumerate(timeline["scenes"])))
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", str(listing), "-c", "copy",
                    "-movflags", "+faststart", str(BUILD / "video.mp4")], check=True)
    print(f"wrote {BUILD / 'video.mp4'}")


if __name__ == "__main__":
    main()
