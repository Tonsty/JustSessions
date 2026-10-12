"""A music bed from Apple Loops that ship with macOS (GarageBand content, royalty-free for use in your own work).

All loops are from the Chillwave pack at 120 BPM; the Hyperlapse kit is in C#. A bar is 2 s, and the grid is set so
a downbeat lands on the cut from the title card to the app, where the drums come in.
"""
from pathlib import Path

import numpy as np

from audio.audio_files import SAMPLE_RATE, decode_loop

LOOPS = Path("/Library/Audio/Apple Loops/Apple/07 Chillwave")
BAR = 2.0


def place_loop(bed, loop, start, end, grid_origin, fade_in=0.0):
    """Repeats loop from start to end, phase-locked to the bar grid."""
    first, last = int(start * SAMPLE_RATE), min(int(end * SAMPLE_RATE), len(bed))
    if last <= first:
        return
    positions = np.arange(first, last)
    phase = (positions - int(grid_origin * SAMPLE_RATE)) % len(loop)
    part = loop[phase]
    if fade_in:
        part = part * np.clip((positions - first) / (fade_in * SAMPLE_RATE), 0, 1)[:, None]
    bed[first:last] += part


def music_bed(duration, drums_start, drums_end):
    """drums_start should be the title-to-app cut; drums_end the start of the end card."""
    loop = {name: decode_loop(LOOPS / f"{name}.caf") for name in
            ["Hyperlapse Synth", "Hyperlapse Bass", "Minimal Backbeat 01", "Minimal Backbeat 02", "Doubledown Beat 01"]}
    bed = np.zeros((int(duration * SAMPLE_RATE) + 1, 2), np.float32)
    origin = drums_start
    last_bar = origin + BAR * np.floor((drums_end - origin) / BAR)
    place_loop(bed, 0.55 * loop["Hyperlapse Synth"], 0.0, duration, origin, fade_in=1.2)
    place_loop(bed, 0.8 * loop["Hyperlapse Bass"], drums_start, duration, origin)
    # Eight bars of the minimal beat, eight of the busier one through the middle, then minimal again.
    switch_up, switch_back = origin + 8 * BAR, origin + 16 * BAR
    place_loop(bed, loop["Minimal Backbeat 01"], drums_start, switch_up, origin)
    place_loop(bed, loop["Doubledown Beat 01"], switch_up, min(switch_back, last_bar), origin)
    place_loop(bed, loop["Minimal Backbeat 02"], switch_back, last_bar, origin)
    # The last second fades out.
    tail = int(1.2 * SAMPLE_RATE)
    bed[-tail:] *= np.linspace(1, 0, tail)[:, None] ** 1.5
    return bed
