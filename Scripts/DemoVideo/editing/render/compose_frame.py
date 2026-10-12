"""Builds one output frame of a scene: the camera's view of the source frame plus rings, captions, and fades."""
from PIL import Image

from render.camera import STAGE_WIDTH, camera_at, view_rect
from render.cards.background import blend_to_background
from render.cards.end_card import end_frame
from render.cards.title_card import title_frame
from render.overlays.caption_pill import draw_captions
from render.overlays.click_ring import draw_click_rings
from render.source_frames import SOURCE_WIDTH

WIDTH, HEIGHT = 1920, 1080
PIXELS_PER_POINT = SOURCE_WIDTH / STAGE_WIDTH
CARDS = {"title": title_frame, "end": end_frame}


def card_frame(scene, time):
    return CARDS[scene["card"]](time, scene["duration"], scene["voice"])


def footage_frame(source_image, scene, time, captions):
    """time is scene-local output seconds."""
    center_x, center_y, zoom = camera_at(scene["camera"], time)
    left, top, width, height = view_rect(center_x, center_y, zoom)
    box = tuple(value * PIXELS_PER_POINT for value in (left, top, left + width, top + height))
    frame = source_image.resize((WIDTH, HEIGHT), Image.LANCZOS, box=box, reducing_gap=3.0)

    def to_output(x, y):
        return (x - left) * WIDTH / width, (y - top) * HEIGHT / height

    draw_click_rings(frame, scene["clicks"], time, to_output, zoom)
    draw_captions(frame, captions, scene["start"] + time)
    if scene["fade_in"] and time < scene["fade_in"]:
        frame = blend_to_background(frame, 1 - time / scene["fade_in"])
    remaining = scene["duration"] - time
    if scene["fade_out"] and remaining < scene["fade_out"]:
        frame = blend_to_background(frame, 1 - remaining / scene["fade_out"])
    return frame
