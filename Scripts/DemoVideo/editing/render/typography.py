"""SF Pro at a chosen weight and optical size, from the system's variable font."""
from functools import lru_cache

from PIL import ImageFont

SF_PRO = "/System/Library/Fonts/SFNS.ttf"


@lru_cache(maxsize=None)
def sf_pro(size, weight=400, optical_size=None):
    font = ImageFont.truetype(SF_PRO, size)
    # Axes in file order: Width, Optical Size, GRAD, Weight.
    font.set_variation_by_axes([100, optical_size or min(96, max(17, size * 0.75)), 400, weight])
    return font
