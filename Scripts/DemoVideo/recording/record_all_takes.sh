#!/bin/zsh
# record_all_takes.sh: records the five takes in the order their starting states need. The takes move the pointer
# and type, and abort if another app comes to the front, so leave the Mac alone until it finishes.
set -e
source ${0:A:h:h}/settings.sh
recording=$DEMO_VIDEO_TOOLS/recording
driver=$DEMO_WORK/bin/demo-driver

# Sessions, search, and split view run on from one reset; each take starts where the last one ended.
$recording/reset_demo.sh
for take in A-sessions B-search C-split; do $recording/record_take.sh $take; done

# New window starts from the tabs those three leave open, in a smaller window, so the tab dragged out of it lands
# on free space. The drag's end point in D-window.json is set for this frame.
$recording/reset_demo.sh
for take in A-sessions B-search C-split; do $driver run $recording/takes/$take.json | tail -1; done
$driver setframe 0 84 170 1100 620
sleep 1.5
$recording/record_take.sh D-window

$recording/reset_demo.sh
$recording/record_take.sh E-ssh
