"""An expanding ring where the cursor pressed, so each click reads at a glance even when the camera moves."""
from functools import lru_cache

from PIL import Image, ImageDraw

from render.sprites import ease_out_cubic, paste_sprite

RING_LENGTH = 0.5
# A double-click shows a second ring this much later, matching the driver's two presses.
SECOND_PRESS = 0.16
COLORS = {"click": (255, 138, 31), "doubleclick": (255, 138, 31), "rightclick": (166, 77, 240), "drop": (47, 107, 255)}
SUPERSAMPLE = 4
SIZE = 120


@lru_cache(maxsize=None)
def ring_sprite(color, step, steps=30):
    """Frame `step` of the ring animation, drawn large and scaled down for clean edges."""
    progress = step / (steps - 1)
    grow = ease_out_cubic(progress)
    radius = (9 + 30 * grow) * SUPERSAMPLE
    width = (4.5 - 2.5 * grow) * SUPERSAMPLE
    ring_alpha = round(235 * (1 - progress) ** 1.4)
    dot_alpha = round(110 * max(0.0, 1 - progress / 0.35))
    canvas = Image.new("RGBA", (SIZE * SUPERSAMPLE,) * 2, color + (0,))
    draw = ImageDraw.Draw(canvas)
    middle = SIZE * SUPERSAMPLE / 2
    if dot_alpha:
        dot = 11 * SUPERSAMPLE
        draw.ellipse((middle - dot, middle - dot, middle + dot, middle + dot), fill=color + (dot_alpha,))
    draw.ellipse((middle - radius, middle - radius, middle + radius, middle + radius),
                 outline=color + (ring_alpha,), width=round(width))
    return canvas.resize((SIZE, SIZE), Image.LANCZOS)


def draw_click_rings(frame, clicks, time, to_output, scale):
    """Draws every ring alive at this scene time; to_output maps stage points to frame pixels."""
    for click in clicks:
        presses = [click["at"]] + ([click["at"] + SECOND_PRESS] if click["action"] == "doubleclick" else [])
        for pressed in presses:
            progress = (time - pressed) / RING_LENGTH
            if 0 <= progress < 1:
                x, y = to_output(click["x"], click["y"])
                sprite = ring_sprite(COLORS[click["action"]], round(progress * 29))
                paste_sprite(frame, sprite, x, y, scale=min(1.6, max(0.8, scale)))
