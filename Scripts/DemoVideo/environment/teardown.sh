#!/bin/zsh
# teardown.sh: undoes setup on this Mac and the VM. It quits the demo app, stops its tmux server and the background
# helpers, deletes its preferences and the demo home, then removes the VM's demo user and the devbox alias.
# The work folder stays, with the takes and renders; delete $DEMO_WORK yourself once you no longer need them.
source ${0:A:h:h}/settings.sh

$DEMO_VIDEO_TOOLS/environment/quit_demo_app.sh
$DEMO_APP/Contents/Resources/Tmux/bin/tmux -S $DEMO_TMUX_DIRECTORY/tmux-$UID/justsessions kill-server 2>/dev/null || true
tmux -S $DEMO_TMUX_DIRECTORY/probe.sock kill-server 2>/dev/null || true
pkill -f "$DEMO_HOME/.codex/packages" 2>/dev/null || true
$DEMO_VIDEO_TOOLS/environment/services.sh stop
defaults delete $DEMO_BUNDLE_IDENTIFIER >/dev/null 2>&1 && echo "deleted the demo app's preferences"

if [[ -n $DEMO_HOME && $DEMO_HOME != / && $DEMO_HOME != $HOME && -d $DEMO_HOME ]]; then
  rm -rf $DEMO_HOME && echo "deleted $DEMO_HOME"
fi
$DEMO_VIDEO_TOOLS/environment/remote/teardown_remote_host.sh
echo "kept $DEMO_WORK (takes and renders)"
