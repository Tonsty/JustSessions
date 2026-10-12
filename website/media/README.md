# Homepage demo video

`justsessions-demo.mp4` is the homepage's narrated demo. It runs 52.6 seconds at 1920 × 1080 and 60 fps. Video is H.264 (`yuv420p`, CRF 24), audio is AAC 128 kbps, and the file uses `+faststart`. `justsessions-demo.jpg` is its poster: the split-view moment at 28.0 seconds, rendered without its caption.

## Recording

The video was recorded on October 11, 2026 from an isolated build of v1.2.6 (`59d6a1771eabc8af0ad27e9abf20ef2ebdb6787c`). That build has its own bundle ID, home folder, and tmux socket. Every click and drag is a real action in the production app. The five takes cover sessions and Resume, search, tabs and split view, dragging a tab into a new window, and SSH.

- **Sample data:** the projects, sessions, and conversations are made up.
- **Local CLIs:** the CLIs are real: Claude Code, Codex, OpenCode, and Pi. Codex, OpenCode, and Pi got their saved history from a canned local model server. No reply shown came from a live model.
- **SSH:** the host `devbox` is a disposable local Ubuntu VM, reached over a live SSH connection. It runs Claude Code 2.1.295 and tmux 3.4.
- **Long job:** `scripts/backfill.py` is a sample script that prints progress. It keeps running in the remote tmux session while its tab is closed.

## Editing

Idle time is cut, and some segments play faster, at 1.15× to 3.2×. Camera moves zoom into the 2× captures. Click rings, captions, and the title and end cards are added.

- **Narration:** generated locally with Kokoro (`kokoro-v1.0`, voice `af_heart`, Apache-2.0 weights).
- **Captions:** burned in from the narration's sentence timing. The cards show their narration as on-screen text.
- **Music:** built from Apple Loops in GarageBand's Chillwave pack. Apple's terms allow the loops in original audio projects, not on their own ([Apple Support](https://support.apple.com/en-us/102034)).
- **Sound effects:** synthesized.
- **Loudness:** the mix is mastered to -16 LUFS.

The scripts that record and edit it are in `Scripts/DemoVideo/`; see [Demo video](../../docs/development/demo-video.md). Raw takes and renders stay in the ignored `dist/demo-video/`. Only the finished video and poster are published.

## Chapters

The chapter buttons in `index.html` jump to these points, and must match the video when it is replaced:

| Chapter | Seconds |
| --- | --- |
| Sessions | 3–9.5 |
| Agents | 9.5–15.8 |
| Search | 15.8–22.29 |
| Tabs & split | 22.29–28.05 |
| New window | 28.05–32.88 |
| SSH | 32.88–47.23 |

The title card runs from 0 to 3 seconds, and the end card from 47.23 seconds to the end.
