"""The narration as a pill at the bottom of the frame, for viewers watching without sound."""
from functools import lru_cache

from PIL import Image, ImageDraw

from render.sprites import appear, paste_sprite
from render.typography import sf_pro

FONT = sf_pro(40, weight=590, optical_size=28)
TEXT_COLOR = (255, 255, 255, 255)
PILL_COLOR = (20, 22, 28, 214)
BORDER_COLOR = (255, 255, 255, 30)
PADDING_X, HEIGHT = 30, 72
BOTTOM_MARGIN = 56
FADE = 0.16
RISE = 10


@lru_cache(maxsize=None)
def pill_sprite(text):
    left, top, right, bottom = FONT.getbbox(text)
    width = right - left + 2 * PADDING_X
    sprite = Image.new("RGBA", (width + 4, HEIGHT + 4), (0, 0, 0, 0))
    draw = ImageDraw.Draw(sprite)
    draw.rounded_rectangle((2, 2, width + 1, HEIGHT + 1), radius=HEIGHT // 2, fill=PILL_COLOR, outline=BORDER_COLOR, width=1)
    # Center on the cap height so the text sits optically in the middle of the pill.
    cap_top, cap_bottom = FONT.getbbox("H")[1], FONT.getbbox("H")[3]
    draw.text((2 + PADDING_X - left, 2 + (HEIGHT - (cap_bottom - cap_top)) / 2 - cap_top), text, font=FONT, fill=TEXT_COLOR)
    return sprite


def draw_captions(frame, captions, time):
    """time is seconds from the start of the video, the clock captions are written in."""
    for caption in captions:
        if caption["start"] - 0.01 <= time < caption["end"] + FADE:
            fade_in = appear(time, caption["start"] - 0.06, FADE)
            fade_out = min(1.0, max(0.0, (caption["end"] + FADE - time) / FADE))
            opacity = min(fade_in, fade_out)
            sprite = pill_sprite(caption["text"])
            paste_sprite(frame, sprite, frame.width / 2,
                         frame.height - BOTTOM_MARGIN - HEIGHT / 2 + RISE * (1 - fade_in), opacity)
