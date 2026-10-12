"""Mixes narration, music, and effects to $DEMO_WORK/build/audio.wav, following the timeline.

The music sits well under the voice and dips further while a line is spoken. Loudness is mastered in delivery/mux_final.py.
"""
import json

import numpy as np

from paths import BUILD, TIMELINE, VOICE_AUDIO
from audio.audio_files import SAMPLE_RATE, decode, ffmpeg_filter, write_wav
from audio.music_bed import music_bed
from audio.sound_effects import click_tick, whoosh

SECOND_PRESS = 0.16
# Usual narration processing: drop rumble, even out the level, and catch the plosives the TTS leaves peaky.
VOICE_CHAIN = ("highpass=f=70,acompressor=threshold=-28dB:ratio=3:attack=4:release=90:knee=4:makeup=5dB,"
               "alimiter=limit=-4dB:attack=2:release=40:level=disabled")
# Relative to the narration's loudness while speaking.
MUSIC_LEVEL, MUSIC_UNDER_VOICE = 0.32, 0.16
TICK_LEVEL, WHOOSH_LEVEL = 0.16, 0.12


def rms(audio):
    return float(np.sqrt(np.mean(audio ** 2)))


def add_at(track, sound, at):
    start = int(round(at * SAMPLE_RATE))
    end = min(len(track), start + len(sound))
    if end > start:
        track[start:end] += sound[:end - start]


def voice_track(timeline, length):
    track = np.zeros((length, 2), np.float32)
    for cue in timeline["voice"]:
        add_at(track, decode(VOICE_AUDIO / f"{cue['line']}.wav"), cue["at"])
    return track


def speaking_envelope(timeline, length):
    """1 while a line plays, easing in just before it and out after, so the music dips smoothly."""
    envelope = np.zeros(length, np.float32)
    for cue in timeline["voice"]:
        start = int((cue["at"] - 0.15) * SAMPLE_RATE)
        end = int((cue["at"] + cue["duration"] + 0.25) * SAMPLE_RATE)
        envelope[max(0, start):min(length, end)] = 1
    window = int(0.12 * SAMPLE_RATE)
    kernel = np.ones(window, np.float32) / window
    return np.convolve(envelope, kernel, mode="same")


def click_track(timeline, length):
    track, tick = np.zeros((length, 2), np.float32), click_tick()
    for scene in timeline["scenes"]:
        for click in scene.get("clicks", []):
            for press in range(2 if click["action"] == "doubleclick" else 1):
                add_at(track, tick, scene["start"] + click["at"] + press * SECOND_PRESS)
    return track


def cut_track(timeline, length):
    track, rush = np.zeros((length, 2), np.float32), whoosh()
    scenes = timeline["scenes"]
    for before, after in zip(scenes, scenes[1:]):
        # Scenes cut from the same take continue one shot; only real cuts get a whoosh.
        if before.get("take") != after.get("take"):
            add_at(track, rush, after["start"] - 0.2)
    return track


def main():
    timeline = json.loads(TIMELINE.read_text())
    length = int(timeline["duration"] * SAMPLE_RATE) + 1
    voice = ffmpeg_filter(voice_track(timeline, length), VOICE_CHAIN)
    speaking = voice[np.abs(voice).max(axis=1) > 0.01]
    voice_level = rms(speaking)

    footage = [scene for scene in timeline["scenes"] if "take" in scene]
    end_card = timeline["scenes"][-1]
    music = music_bed(timeline["duration"], footage[0]["start"], end_card["start"])[:length]
    music *= voice_level / rms(music[int(footage[0]["start"] * SAMPLE_RATE):])
    ducking = MUSIC_LEVEL - (MUSIC_LEVEL - MUSIC_UNDER_VOICE) * speaking_envelope(timeline, length)
    music *= ducking[:, None]

    clicks = click_track(timeline, length) * (TICK_LEVEL * voice_level / rms(click_tick()))
    cuts = cut_track(timeline, length) * (WHOOSH_LEVEL * voice_level / rms(whoosh()))
    mix = voice + music + clicks + cuts
    write_wav(BUILD / "audio.wav", mix)
    print(f"wrote {BUILD / 'audio.wav'}: {len(mix) / SAMPLE_RATE:.2f}s, peak {20 * np.log10(np.abs(mix).max()):.1f} dBFS")


if __name__ == "__main__":
    main()
