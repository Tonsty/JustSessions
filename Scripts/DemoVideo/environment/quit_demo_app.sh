#!/bin/zsh
# quit_demo_app.sh: quits the demo app if it's running and waits for it to exit. It only sends the quit to a running
# app, so a quit never has to find the app or start it first.
source ${0:A:h:h}/settings.sh

pgrep -f $DEMO_APP_EXECUTABLE > /dev/null || exit 0
osascript -e "tell application id \"$DEMO_BUNDLE_IDENTIFIER\" to quit" > /dev/null 2>&1
for _ in {1..30}; do
  pgrep -f $DEMO_APP_EXECUTABLE > /dev/null || exit 0
  sleep 0.3
done
echo "The demo app is still running after a quit; close it and try again."
exit 1
