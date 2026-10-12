"""Opening card: the app icon, then the promise in two lines, each appearing as the narration reaches it."""
from functools import lru_cache

from PIL import Image

from paths import BRANDING
from render.cards.background import card_background
from render.sprites import appear, ease_out_back, paste_sprite, text_sprite
from render.typography import sf_pro

HEADLINE = sf_pro(82, weight=680, optical_size=80)
FIRST_LINE, SECOND_LINE = "All your coding agents.", "One native Mac app."
# The narration's fifth spoken word, "in", starts the second line.
SECOND_LINE_WORD = 4


@lru_cache(maxsize=None)
def sprites():
    icon = Image.open(BRANDING / "app-icon-1024.png").convert("RGBA").resize((230, 230), Image.LANCZOS)
    return (icon, text_sprite(FIRST_LINE, HEADLINE, (255, 255, 255, 255)),
            text_sprite(SECOND_LINE, HEADLINE, (168, 170, 182, 255)))


def title_frame(time, duration, voice):
    icon, first, second = sprites()
    line = voice[0]
    first_at = line["at"] + line["sentences"][0]["start"] - 0.1
    second_at = line["at"] + line["spoken_words"][SECOND_LINE_WORD]["start"] - 0.1
    frame = card_background().copy()
    leaving = min(1.0, max(0.0, (duration - time) / 0.3))
    icon_in = min(1.0, max(0.0, time / 0.45))
    paste_sprite(frame, icon, 960, 340, opacity=min(1.0, time / 0.2) * leaving, scale=0.8 + 0.2 * ease_out_back(icon_in))
    for sprite, at, y in ((first, first_at, 560), (second, second_at, 660)):
        shown = appear(time, at, 0.35)
        paste_sprite(frame, sprite, 960, y + 18 * (1 - shown), opacity=shown * leaving)
    return frame
