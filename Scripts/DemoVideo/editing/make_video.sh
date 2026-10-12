#!/bin/zsh
# make_video.sh: builds the master, $DEMO_WORK/output/JustSessions-demo.mp4, from the takes, the click positions,
# and the narration. Rerun voiceover.make_voiceover when lines.json changes, and analysis.find_click_positions
# when the takes change.
set -e
source ${0:A:h:h}/settings.sh
cd ${0:A:h}
python=$DEMO_WORK/.venv/bin/python
$python -m timeline.build_timeline
$python -m render.render_video
$python -m audio.mix_audio
$python -m delivery.mux_final
