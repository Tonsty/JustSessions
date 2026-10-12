"""Closing card: what JustSessions leaves out, then the name of the idea, then where to get it."""
from functools import lru_cache

from PIL import Image

from paths import BRANDING
from render.cards.background import card_background
from render.sprites import appear, ease_out_back, paste_sprite, text_sprite
from render.typography import sf_pro

PHRASE_FONT = sf_pro(46, weight=500, optical_size=40)
TAGLINE_FONT = sf_pro(112, weight=700, optical_size=96)
FOOTER_FONT = sf_pro(30, weight=500, optical_size=28)
LINK_FONT = sf_pro(32, weight=620, optical_size=28)
GRAY, WHITE, ORANGE = (150, 153, 165, 255), (255, 255, 255, 255), (255, 138, 31, 255)
PHRASES = ["No account.", "No import.", "Nothing extra."]
PHRASE_GAP = 44
FOOTER = "Free and open source  ·  MIT license"
LINK = "yangzichao.github.io/JustSessions"


@lru_cache(maxsize=None)
def sprites():
    icon = Image.open(BRANDING / "app-icon-1024.png").convert("RGBA").resize((168, 168), Image.LANCZOS)
    return {
        "icon": icon,
        "phrases": [text_sprite(phrase, PHRASE_FONT, GRAY) for phrase in PHRASES],
        "tagline": text_sprite("Just sessions.", TAGLINE_FONT, WHITE),
        "footer": text_sprite(FOOTER, FOOTER_FONT, GRAY),
        "link": text_sprite(LINK, LINK_FONT, ORANGE),
    }


def end_frame(time, duration, voice):
    parts = sprites()
    line = voice[0]
    sentence_starts = [line["at"] + sentence["start"] - 0.08 for sentence in line["sentences"]]
    frame = card_background().copy()
    leaving = min(1.0, max(0.0, (duration - time) / 0.45))

    icon_in = min(1.0, max(0.0, time / 0.45))
    paste_sprite(frame, parts["icon"], 960, 300, opacity=min(1.0, time / 0.2) * leaving,
                 scale=0.8 + 0.2 * ease_out_back(icon_in))

    widths = [sprite.width for sprite in parts["phrases"]]
    x = 960 - (sum(widths) + PHRASE_GAP * (len(widths) - 1)) / 2
    for sprite, at in zip(parts["phrases"], sentence_starts):
        shown = appear(time, at, 0.3)
        paste_sprite(frame, sprite, x + sprite.width / 2, 480 + 14 * (1 - shown), opacity=shown * leaving)
        x += sprite.width + PHRASE_GAP

    tagline_at = sentence_starts[3]
    shown = appear(time, tagline_at, 0.4)
    paste_sprite(frame, parts["tagline"], 960, 610, opacity=shown * leaving,
                 scale=0.92 + 0.08 * ease_out_back(min(1.0, max(0.0, (time - tagline_at) / 0.45))))

    for sprite, y, delay in ((parts["footer"], 780, 0.6), (parts["link"], 836, 0.75)):
        shown = appear(time, tagline_at + delay, 0.35)
        paste_sprite(frame, sprite, 960, y + 10 * (1 - shown), opacity=shown * leaving)
    return frame
