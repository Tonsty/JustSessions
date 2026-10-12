#!/bin/zsh
# run_in_isolated_tmux.sh <session> <directory> <seconds> <command...>: starts a CLI in the demo app's environment,
# inside a 120x36 tmux session on its own socket, waits, then prints the screen. Send it keys with
#   tmux -S $DEMO_WORK/tmux/probe.sock send-keys -t <session> ...
source ${0:A:h:h}/settings.sh
session=$1; directory=$2; seconds=$3; shift 3
socket=$DEMO_TMUX_DIRECTORY/probe.sock
mkdir -p $DEMO_TMUX_DIRECTORY
tmux -S $socket kill-session -t $session 2>/dev/null
$DEMO_VIDEO_TOOLS/environment/run_isolated.sh $directory \
  tmux -S $socket -f /dev/null new-session -d -x 120 -y 36 -s $session -c $directory "${(j: :)${(q)@}}"
sleep $seconds
tmux -S $socket capture-pane -p -t $session | sed -e 's/[[:space:]]*$//' | cat -s
