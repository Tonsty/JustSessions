"""Small synthesized sounds: a soft tick for clicks and a short air whoosh for cuts. Nothing sampled, nothing licensed."""
import numpy as np

from audio.audio_files import SAMPLE_RATE


def seconds(length):
    return np.arange(int(length * SAMPLE_RATE)) / SAMPLE_RATE


def stereo(mono):
    return np.stack([mono, mono], axis=1).astype(np.float32)


def click_tick():
    time = seconds(0.06)
    body = np.sin(2 * np.pi * 1750 * time) * np.exp(-time / 0.010)
    snap = np.random.default_rng(3).normal(0, 1, time.size) * np.exp(-time / 0.0025)
    return stereo(0.6 * body + 0.25 * snap)


def whoosh(length=0.42):
    time = seconds(length)
    noise = np.random.default_rng(5).normal(0, 1, time.size)
    # A one-pole low-pass whose cutoff sweeps up and back down gives the rush of air.
    cutoff = 300 + 3200 * np.sin(np.pi * time / length) ** 2
    coefficient = 1 - np.exp(-2 * np.pi * cutoff / SAMPLE_RATE)
    filtered, state = np.empty_like(noise), 0.0
    for index, (sample, amount) in enumerate(zip(noise, coefficient)):
        state += amount * (sample - state)
        filtered[index] = state
    envelope = np.sin(np.pi * np.clip(time / length, 0, 1)) ** 2
    return stereo(0.5 * filtered * envelope / np.abs(filtered).max())
