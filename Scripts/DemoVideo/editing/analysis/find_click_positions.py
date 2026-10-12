"""Finds where the cursor was at each scripted click, so the edit can draw a ring there.

The driver logs when each step starts but not where it clicked. A click ends right before the next log line,
so the press is that time minus the click's own length; the cursor is found in that frame by its black arrow.
Writes $DEMO_WORK/clicks.json: per take, a list of {action, target, time, x, y} in seconds and stage points (1600x900).
"""
import json
import subprocess

import numpy as np

from paths import CLICKS, TAKES
from timeline.scenes import SCENES

TAKE_NAMES = sorted({scene["take"] for scene in SCENES if "take" in scene})
# One press is 70 ms down and 90 ms up, see click(at:) in recording/driver/main.swift.
PRESS_LENGTH = 0.16
# The arrow's tip in the reference frame, found by eye: take A at 3.80 s, clicking the Claude Code row.
# After re-recording take A, find a frame where the arrow sits on a light area and update this.
REFERENCE = ("A-sessions", 3.80, (339, 512))
# The arrow's fill is 0-15 gray; the darkest interface text is 32 and up, so it never joins the match.
CURSOR_BLACK = 16


def frame(take, seconds):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-ss", f"{seconds:.3f}", "-i", str(TAKES / f"{take}.mov"),
                          "-frames:v", "1", "-f", "rawvideo", "-pix_fmt", "gray", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(1800, 3200)


def arrow_template():
    take, seconds, (tip_x, tip_y) = REFERENCE
    region = frame(take, seconds)[tip_y - 12:tip_y + 50, tip_x - 12:tip_x + 40]
    body = region < CURSOR_BLACK
    ys, xs = np.nonzero(body)
    # The tip is the arrow's topmost black pixel; keep its offset inside the template.
    top = ys.min()
    tip = (int(xs[ys == top].min()), int(top))
    return body.astype(np.float32), tip


def find_arrow(gray, template, tip):
    """Correlates the frame's black pixels with the arrow's; returns the tip position and the match score."""
    black = (gray < CURSOR_BLACK).astype(np.float32)
    height, width = black.shape
    spectrum = np.fft.rfft2(black) * np.conj(np.fft.rfft2(template, s=black.shape))
    correlation = np.fft.irfft2(spectrum, s=black.shape)
    # Penalise black pixels where the template has none, so solid dark areas do not match.
    outside = np.fft.irfft2(np.fft.rfft2(black) * np.conj(np.fft.rfft2(1 - template, s=black.shape)), s=black.shape)
    score = (correlation - outside) / template.sum()
    y, x = np.unravel_index(np.argmax(score), score.shape)
    return (int(x + tip[0]) % width, int(y + tip[1]) % height), float(score[y, x])


def click_moments(take):
    started = float(next(line.split()[-1] for line in (TAKES / f"{take}.recorder.log").read_text().splitlines()
                         if "RECORDING STARTED" in line))
    lines = [line.split(" ", 2) for line in (TAKES / f"{take}.driver.log").read_text().splitlines()]
    lines = [(float(parts[0]) - started, parts[1], parts[2] if len(parts) > 2 else "") for parts in lines]
    moments = []
    for (time, action, target), following in zip(lines, lines[1:]):
        presses = {"click": 1, "rightclick": 1, "doubleclick": 2}.get(action)
        if presses:
            moments.append({"action": action, "target": target, "time": round(following[0] - PRESS_LENGTH * presses, 3)})
        elif action == "drag":
            # The drag ends with the release right before the next log line.
            moments.append({"action": "drop", "target": target, "time": round(following[0] - 0.02, 3)})
    return moments


def main():
    template, tip = arrow_template()
    found = {}
    for take in TAKE_NAMES:
        found[take] = []
        for moment in click_moments(take):
            (x, y), score = find_arrow(frame(take, moment["time"]), template, tip)
            moment.update(x=round(x / 2, 1), y=round(y / 2, 1), score=round(score, 2))
            found[take].append(moment)
            print(f"{take:11} {moment['time']:6.2f}  {moment['action']:11} ({moment['x']:6.1f}, {moment['y']:5.1f})  "
                  f"score {score:.2f}  {moment['target']}")
    CLICKS.write_text(json.dumps(found, indent=1))


if __name__ == "__main__":
    main()
