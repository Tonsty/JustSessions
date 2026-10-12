"""Speaks each line in lines.json with Kokoro, locally, and saves the audio plus its sentence timings for captions.

Usage: python -m voiceover.make_voiceover [voice] [speed] [comma-separated line ids]
"""
import json
import re
import sys

import soundfile
from kokoro_onnx import Kokoro

from paths import KOKORO_MODELS, NARRATION_LINES, VOICE_AUDIO

VOICE = sys.argv[1] if len(sys.argv) > 1 else "af_heart"
SPEED = float(sys.argv[2]) if len(sys.argv) > 2 else 1.1
PUNCTUATION = set(",.;:!?—…\"“”()")


def spoken_words(timings):
    """Groups phoneme timings into words: a space token ends a word, punctuation tokens are silence."""
    words, current = [], []
    for timing in timings:
        if timing.phoneme == " " or timing.phoneme in PUNCTUATION:
            if current:
                words.append(current)
                current = []
            continue
        current.append(timing)
    if current:
        words.append(current)
    return [{"phonemes": "".join(t.phoneme for t in word), "start": word[0].start, "end": word[-1].end}
            for word in words]


def sentences(text):
    return re.split(r"(?<=[.!?])\s+", text.strip())


def spoken_sentences(timings):
    """Splits the phoneme stream at sentence-ending marks; espeak can merge words, but it keeps those marks."""
    groups, current = [], []
    for timing in timings:
        if timing.phoneme in ".!?":
            if current:
                groups.append(current)
                current = []
        else:
            current.append(timing)
    if current:
        groups.append(current)
    return [spoken_words(group) for group in groups if spoken_words(group)]


def sentence_timings(caption, timings):
    """Times each caption sentence by the matching spoken sentence."""
    caption_sentences, spoken = sentences(caption), spoken_sentences(timings)
    if len(caption_sentences) != len(spoken):
        raise SystemExit(f"{len(caption_sentences)} sentences but {len(spoken)} spoken in {caption!r}")
    timed = [{"text": text, "start": round(words[0]["start"], 3), "end": round(words[-1]["end"], 3),
              "phonemes": " ".join(word["phonemes"] for word in words)}
             for text, words in zip(caption_sentences, spoken)]
    return timed


def main():
    VOICE_AUDIO.mkdir(parents=True, exist_ok=True)
    only = set(sys.argv[3].split(",")) if len(sys.argv) > 3 else None
    kokoro = Kokoro(str(KOKORO_MODELS / "kokoro-v1.0.onnx"), str(KOKORO_MODELS / "voices-v1.0.bin"))
    for line in json.loads(NARRATION_LINES.read_text()):
        if only and line["id"] not in only:
            continue
        # "say" lets a line spell a word the way it should sound while the caption keeps the written form.
        audio, sample_rate, timings = kokoro.create_timed(
            line.get("say", line["text"]), VOICE, speed=SPEED, sentence_pause=0.2, clause_pause=0.08)
        soundfile.write(VOICE_AUDIO / f"{line['id']}.wav", audio, sample_rate)
        timed_sentences = sentence_timings(line["text"], timings)
        (VOICE_AUDIO / f"{line['id']}.timing.json").write_text(json.dumps(
            {"duration": round(len(audio) / sample_rate, 3), "sentences": timed_sentences,
             "spoken_words": [{key: round(value, 3) if isinstance(value, float) else value for key, value in word.items()}
                              for word in spoken_words(timings)]}, indent=1))
        print(f"{line['id']}: {len(audio) / sample_rate:.2f}s")
        for sentence in timed_sentences:
            print(f"  {sentence['start']:5.2f}-{sentence['end']:5.2f}  {sentence['phonemes']}")


if __name__ == "__main__":
    main()
