"""Pasting pre-rendered RGBA sprites onto RGB frames with opacity and scale."""
from PIL import Image, ImageDraw


def paste_sprite(frame, sprite, center_x, center_y, opacity=1.0, scale=1.0):
    if opacity <= 0.003:
        return
    if abs(scale - 1) > 0.002:
        sprite = sprite.resize((max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))),
                               Image.LANCZOS)
    mask = sprite.getchannel("A")
    if opacity < 0.997:
        mask = mask.point(lambda alpha: round(alpha * opacity))
    frame.paste(sprite.convert("RGB"), (round(center_x - sprite.width / 2), round(center_y - sprite.height / 2)), mask)


def text_sprite(text, font, color, padding=8):
    """Text on a transparent sprite sized to its ink, centered on the text box."""
    left, top, right, bottom = font.getbbox(text)
    sprite = Image.new("RGBA", (right - left + 2 * padding, bottom - top + 2 * padding), color[:3] + (0,))
    ImageDraw.Draw(sprite).text((padding - left, padding - top), text, font=font, fill=color)
    return sprite


def ease_out_cubic(t):
    t = min(max(t, 0.0), 1.0)
    return 1 - (1 - t) ** 3


def ease_out_back(t, overshoot=1.6):
    t = min(max(t, 0.0), 1.0)
    return 1 + (overshoot + 1) * (t - 1) ** 3 + overshoot * (t - 1) ** 2


def appear(time, start, length=0.3):
    """0 before start, easing to 1 over length."""
    return ease_out_cubic((time - start) / length) if time >= start else 0.0
