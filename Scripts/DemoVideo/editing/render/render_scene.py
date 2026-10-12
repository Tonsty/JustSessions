"""Renders one scene of the timeline to its own H.264 file, encoded identically so the scenes concatenate losslessly."""
import subprocess

from render.compose_frame import HEIGHT, WIDTH, card_frame, footage_frame
from render.source_frames import SourceFrames
from timeline.time_mapping import source_time

ENCODER = [
    "-c:v", "libx264", "-preset", "slow", "-crf", "14", "-pix_fmt", "yuv420p",
    "-color_primaries", "bt709", "-color_trc", "bt709", "-colorspace", "bt709", "-color_range", "tv",
]


def encoder_process(output_path, fps):
    return subprocess.Popen(
        ["ffmpeg", "-v", "error", "-y", "-f", "rawvideo", "-pix_fmt", "rgb24", "-s", f"{WIDTH}x{HEIGHT}", "-r", str(fps),
         "-i", "-", "-vf", "scale=in_range=pc:out_color_matrix=bt709:out_range=tv", *ENCODER, str(output_path)],
        stdin=subprocess.PIPE)


def render_scene(timeline, scene, output_path):
    fps = timeline["fps"]
    frame_count = round(scene["duration"] * fps)
    encoder = encoder_process(output_path, fps)
    source = None
    if "take" in scene:
        source = SourceFrames(scene["take"], scene["pieces"][0][0], scene["pieces"][-1][1])
    try:
        for index in range(frame_count):
            time = index / fps
            if source:
                image = source.frame_at(source_time(scene["pieces"], time))
                frame = footage_frame(image, scene, time, timeline["captions"])
            else:
                frame = card_frame(scene, time)
            encoder.stdin.write(frame.tobytes())
    finally:
        if source:
            source.close()
        encoder.stdin.close()
        encoder.wait()
    if encoder.returncode != 0:
        raise RuntimeError(f"encoding {scene['name']} failed")
    return frame_count
