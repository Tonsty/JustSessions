#!/bin/zsh
# web_encode.sh <output.mp4>: the homepage's copy of the master, small enough to serve from GitHub Pages
# (about 7.7 MB for 53 seconds). Same 1080p60 picture and sound, H.264 at CRF 24, AAC 128 kbps, faststart.
set -e
source ${0:A:h:h:h}/settings.sh
ffmpeg -v error -y -i $DEMO_WORK/output/JustSessions-demo.mp4 -vf fps=60 -c:v libx264 -preset veryslow -crf 24 \
  -pix_fmt yuv420p -color_primaries bt709 -color_trc bt709 -colorspace bt709 -c:a aac -b:a 128k \
  -movflags +faststart $1
echo "wrote $1 ($(du -h $1 | cut -f1))"
