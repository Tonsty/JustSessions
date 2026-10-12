"""Lays the scenes end to end and writes the timeline, the single plan the video and audio renders follow.

Every time in the output file is in output seconds: scene-local for camera keys and clicks (the scene renderer
works scene by scene), and from the start of the video for voice, captions, and cuts (the audio mix and captions).
"""
import json

from paths import CLICKS, TIMELINE, VOICE_AUDIO
from timeline.scenes import SCENES
from timeline.time_mapping import is_kept, output_time, scene_length

# A caption stays a moment after its sentence so it can be read, but has faded out before the next one appears.
CAPTION_HOLD = 0.35
CAPTION_FADE = 0.16


def voice_timing(line_id):
    return json.loads((VOICE_AUDIO / f"{line_id}.timing.json").read_text())


def footage_scene(scene, start, clicks):
    pieces = scene["pieces"]
    placed = {
        "name": scene["name"], "take": scene["take"], "start": start, "duration": scene_length(pieces),
        "pieces": pieces, "fade_in": scene.get("fade_in", 0), "fade_out": scene.get("fade_out", 0),
        "camera": [(round(output_time(pieces, source), 4), x, y, zoom) for source, x, y, zoom in scene["camera"]],
        "clicks": [{**click, "at": round(output_time(pieces, click["time"]), 4)}
                   for click in clicks[scene["take"]] if is_kept(pieces, click["time"])],
    }
    voice = [(line_id, start + output_time(pieces, source)) for line_id, source in scene["voice"]]
    return placed, voice


def card_scene(scene, start):
    placed = {"name": scene["name"], "card": scene["card"], "start": start, "duration": scene["duration"]}
    voice = [(line_id, start + offset) for line_id, offset in scene["voice"]]
    placed["voice"] = [{"line": line_id, "at": round(at - start, 4), **voice_timing(line_id)} for line_id, at in voice]
    return placed, voice


def captions_for(voice_cues):
    captions = []
    for line_id, at in voice_cues:
        for sentence in voice_timing(line_id)["sentences"]:
            captions.append({"text": sentence["text"], "start": round(at + sentence["start"], 4),
                             "end": round(at + sentence["end"] + CAPTION_HOLD, 4)})
    captions.sort(key=lambda caption: caption["start"])
    for caption, following in zip(captions, captions[1:]):
        caption["end"] = min(caption["end"], following["start"] - CAPTION_FADE)
    return captions


def main():
    clicks = json.loads(CLICKS.read_text())
    scenes, voice, footage_voice, start = [], [], [], 0.0
    for scene in SCENES:
        if "card" in scene:
            placed, cues = card_scene(scene, start)
        else:
            placed, cues = footage_scene(scene, start, clicks)
            footage_voice += cues
        scenes.append(placed)
        voice += cues
        start += placed["duration"]
    timeline = {
        "fps": 60, "width": 1920, "height": 1080, "duration": round(start, 4), "scenes": scenes,
        "voice": [{"line": line_id, "at": round(at, 4), "duration": voice_timing(line_id)["duration"]} for line_id, at in voice],
        # The cards set their own text, so only the footage gets caption pills.
        "captions": captions_for(footage_voice),
        "cuts": [round(scene["start"], 4) for scene in scenes[1:]],
    }
    TIMELINE.parent.mkdir(parents=True, exist_ok=True)
    TIMELINE.write_text(json.dumps(timeline, indent=1, ensure_ascii=False))
    for scene in scenes:
        print(f"{scene['name']:8} {scene['start']:6.2f} - {scene['start'] + scene['duration']:6.2f}  "
              f"({scene['duration']:.2f}s, {len(scene.get('clicks', []))} clicks)")
    for cue in timeline["voice"]:
        print(f"  voice {cue['line']:12} {cue['at']:6.2f} - {cue['at'] + cue['duration']:6.2f}")
    print(f"total {start:.2f}s")


if __name__ == "__main__":
    main()
