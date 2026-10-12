#!/bin/zsh
# run_isolated.sh <directory> <command...>: runs a command in the demo app's environment, with nothing from yours.
source ${0:A:h:h}/settings.sh
directory=$1; shift
cd $directory || exit 1
exec env -i USER=$USER LOGNAME=$USER SHELL=/bin/zsh TERM=xterm-256color COLORTERM=truecolor LANG=en_US.UTF-8 \
  $demo_isolated_environment "$@"
