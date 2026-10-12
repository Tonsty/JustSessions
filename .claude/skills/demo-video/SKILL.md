---
name: demo-video
description: Record, edit, and publish the JustSessions homepage demo video with Scripts/DemoVideo, from an isolated copy of the app with sample sessions and a disposable SSH host. Use when re-recording the demo for a new release, changing its takes, cut, narration, or chapters, or remaking the poster or the social card from it.
---

# Demo video

`Scripts/DemoVideo/demo-video` runs every step. Read [docs/development/demo-video.md](../../../docs/development/demo-video.md) first: requirements, what each setup step changes on the machine, take order, and teardown. This skill adds the workflow and the judgment calls.

## Ask before these

- `record`: it moves the pointer and types on the user's screen, and a take aborts if anything else comes to the front. Ask the user to step away and turn on Do Not Disturb, then run it.
- `setup remote` and `teardown`: they change the shared test VM (a `dev` user, its hostname) and `~/.ssh/config`.
- `reset`: it opens the demo app's window on the user's screen.

Everything else (`setup app|home|editing|sessions`, `clicks`, `voiceover`, `stills`, `render`, `web`, `poster`, `window-still`) runs without taking over the Mac.

## Workflow

1. `make build` at the commit to show, then `demo-video setup`. If `setup sessions` reports the wrong counts, run the CLI that fell short in the demo home with `environment/run_in_isolated_tmux.sh` and read the screen it prints. A first-run notice or a folder-trust prompt that swallows the typed prompt has been the cause; mark it as seen in `fixtures/cli_configs.py`.
2. `demo-video record all`, then `demo-video clicks`. After re-recording take A, update `REFERENCE` in `editing/analysis/find_click_positions.py` first.
3. Update `editing/timeline/scenes.py` to the new takes. Its times are seconds into a take: a line's timestamp in `$DEMO_WORK/takes/<take>.driver.log` minus `RECORDING STARTED` in `<take>.recorder.log`. The `mark` lines name the moments the cut is built around.
4. `demo-video voiceover` only for lines that changed, by id. Kokoro is not deterministic, so regenerating every line changes timing everywhere.
5. `demo-video stills` at each scene's key moments; look at every still before rendering. Then `demo-video render` and watch the master with sound.
6. Publish (below), then `demo-video teardown` once the user is done.

## Judgment calls

- **Pacing.** Moments that matter play at 1×: the click that resumes, the double-click that opens an agent, the drag, typed text. Pointer travel, CLI start-up, and waiting play faster, up to 3.2× in the published cut. Idle time before and after a take is cut.
- **Narration.** One short sentence per beat, said as the thing happens on screen. Captions come from the narration's sentence timing and are placed on the whole video's clock, so a line that runs past its scene spills its audio and caption into the next one. Keep each line shorter than the footage it describes.
- **Camera.** Zoom in when the point is small text, such as a sidebar row or a CLI's output; the published cut goes up to 1.85×. Between scenes of the same take, start at the camera the previous scene ended on. Check in stills that the pointer and the thing it acts on stay in frame.
- **Sample data.** Sessions, projects, and replies are fixtures; change them in `fixtures/` and `environment/canned_model_server.py`, never by recording real work. Before publishing, check the stills for real names, account paths, hostnames, or tokens. Everything on screen should be under `~/Projects` in the demo home or on `devbox`.
- **Honesty.** Every action is real input to the real app. Don't fake a state with an overlay or an edit; change the fixtures or the takes instead. Keep `website/media/README.md` truthful about what is canned.

## Publish

1. `demo-video web website/media/justsessions-demo.mp4` and `demo-video poster <seconds> website/media/justsessions-demo.jpg`. The poster is a frame with no caption that shows the product at its best; it was the split view at 28.0 seconds.
2. Chapter times: each chapter's `data-start`/`data-end` in `website/index.html` and the table in `website/media/README.md` come from scene starts in `$DEMO_WORK/build/timeline.json`.
3. Length: the `0:53` label and the `VideoObject` name, `duration`, and `uploadDate` in `website/index.html`, and the length in `docs/development/website.md` and `website/media/README.md`.
4. Provenance in `website/media/README.md`: recording date, app version and commit, the remote Claude Code version.
5. Social card, if the poster moment changed or the app looks different: `demo-video window-still <seconds> docs/images/demo-split-view.jpg`, then recapture `website/social/social-preview.png` from `website/social/preview.html` as `docs/development/website.md` describes, and update the row in `docs/images/README.md`.
6. Build the site with `make website-check` and check the homepage. Chapter jumps need byte-range responses, which `python3 -m http.server` doesn't send; check them on the published site after deploying.
7. `make verify`, then follow AGENTS.md for the pull request.
