"""The cards' backdrop: the stage's own dark color with two faint glows in the icon's orange and purple."""
from functools import lru_cache

import numpy as np
from PIL import Image

STAGE_COLOR = np.array([20, 22, 28], np.float32)
GLOWS = [((0.22, 0.18), (255, 138, 31), 0.10, 0.55), ((0.82, 0.88), (166, 77, 240), 0.12, 0.6)]


@lru_cache(maxsize=None)
def card_background(width=1920, height=1080):
    ys, xs = np.mgrid[0:height, 0:width].astype(np.float32)
    image = np.broadcast_to(STAGE_COLOR, (height, width, 3)).copy()
    for (center_x, center_y), color, strength, reach in GLOWS:
        distance = np.hypot((xs / width - center_x) * width / height, ys / height - center_y)
        weight = strength * np.exp(-(distance / reach) ** 2 * 2.2)
        image += weight[..., None] * (np.array(color, np.float32) - image)
    # A little noise keeps the gradient from banding after compression.
    image += np.random.default_rng(7).normal(0, 0.6, image.shape)
    return Image.fromarray(np.clip(image, 0, 255).astype(np.uint8), "RGB")


def blend_to_background(frame, amount):
    """amount 0 keeps the frame, 1 shows only the backdrop."""
    if amount <= 0:
        return frame
    return Image.blend(frame, card_background(frame.width, frame.height), min(1.0, amount))
