#!/bin/zsh
# build_recording_tools.sh: compiles the input driver and the stage recorder into $DEMO_WORK/bin.
set -e
source ${0:A:h:h}/settings.sh
mkdir -p $DEMO_WORK/bin
swiftc -O $DEMO_VIDEO_TOOLS/recording/driver/main.swift -o $DEMO_WORK/bin/demo-driver
swiftc -O -parse-as-library $DEMO_VIDEO_TOOLS/recording/recorder/main.swift -o $DEMO_WORK/bin/stage-recorder
echo "built $DEMO_WORK/bin/demo-driver and $DEMO_WORK/bin/stage-recorder"
