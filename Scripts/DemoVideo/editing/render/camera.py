"""Eased camera moves over the recorded stage."""
import math

STAGE_WIDTH, STAGE_HEIGHT = 1600, 900


def ease_in_out(t):
    return 4 * t * t * t if t < 0.5 else 1 - (-2 * t + 2) ** 3 / 2


def camera_at(keys, time):
    """Center and zoom at a scene-local output time. Zoom eases in log space so pushes in and out feel even."""
    if time <= keys[0][0]:
        return keys[0][1:]
    for (start, x0, y0, zoom0), (end, x1, y1, zoom1) in zip(keys, keys[1:]):
        if time <= end:
            t = ease_in_out((time - start) / (end - start)) if end > start else 1
            zoom = math.exp(math.log(zoom0) + (math.log(zoom1) - math.log(zoom0)) * t)
            return x0 + (x1 - x0) * t, y0 + (y1 - y0) * t, zoom
    return keys[-1][1:]


def view_rect(center_x, center_y, zoom):
    """The stage rectangle the camera shows, kept inside the stage: (left, top, width, height) in points."""
    width, height = STAGE_WIDTH / zoom, STAGE_HEIGHT / zoom
    left = min(max(center_x - width / 2, 0), STAGE_WIDTH - width)
    top = min(max(center_y - height / 2, 0), STAGE_HEIGHT - height)
    return left, top, width, height
