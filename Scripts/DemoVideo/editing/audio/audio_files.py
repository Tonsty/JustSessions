"""Reading audio into float32 stereo arrays at the mix rate, with ffmpeg doing the decoding and resampling."""
import re
import subprocess

import numpy as np

SAMPLE_RATE = 44100


def decode(path, sample_rate=SAMPLE_RATE):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-f", "f32le", "-ac", "2", "-ar", str(sample_rate), "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.float32).reshape(-1, 2).copy()


def decode_loop(path):
    """A loop trimmed to its exact musical length, so repeats stay on the beat.

    Apple Loops are AAC with encoder priming in front; afinfo reports how many frames are real audio.
    """
    audio = decode(path)
    info = subprocess.run(["afinfo", str(path)], capture_output=True, text=True, check=True).stdout
    valid, priming = map(int, re.search(r"audio (\d+) valid frames \+ (\d+) priming", info).groups())
    # Use ffmpeg's output as-is when it already dropped the priming; otherwise skip it here.
    start = priming if len(audio) >= valid + priming else 0
    return audio[start:start + valid]


def write_wav(path, audio, sample_rate=SAMPLE_RATE):
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(sample_rate), "-ac", "2", "-i", "-",
                    "-c:a", "pcm_f32le", str(path)], input=audio.astype(np.float32).tobytes(), check=True)


def ffmpeg_filter(audio, chain, sample_rate=SAMPLE_RATE):
    """Runs a float32 stereo array through an ffmpeg audio filter chain."""
    raw = subprocess.run(["ffmpeg", "-v", "error", "-f", "f32le", "-ar", str(sample_rate), "-ac", "2", "-i", "-",
                          "-af", chain, "-f", "f32le", "-ar", str(sample_rate), "-ac", "2", "-"],
                         input=audio.astype(np.float32).tobytes(), capture_output=True, check=True).stdout
    filtered = np.frombuffer(raw, np.float32).reshape(-1, 2).copy()
    padded = np.zeros_like(audio)
    padded[:min(len(audio), len(filtered))] = filtered[:len(audio)]
    return padded
