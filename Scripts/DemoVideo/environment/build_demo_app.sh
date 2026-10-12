#!/bin/zsh
# build_demo_app.sh: copies a built JustSessions into the work folder as the demo app, with its own bundle ID and a
# launcher that gives it the isolated environment, then writes the preferences it records with.
set -e
source ${0:A:h:h}/settings.sh

[[ -d $DEMO_SOURCE_APP ]] || { echo "No app at $DEMO_SOURCE_APP. Run make build, or set DEMO_SOURCE_APP."; exit 1; }
$DEMO_VIDEO_TOOLS/environment/quit_demo_app.sh
mkdir -p $DEMO_WORK $DEMO_TMUX_DIRECTORY
rm -rf $DEMO_APP
cp -R $DEMO_SOURCE_APP $DEMO_APP
mv $DEMO_APP/Contents/MacOS/JustSessions $DEMO_APP_EXECUTABLE

header=$DEMO_WORK/demo_launcher_environment.h
{
  echo "static const char *demo_environment[] = {"
  for assignment in CFFIXED_USER_HOME=$DEMO_HOME $demo_isolated_environment; do echo "  \"$assignment\","; done
  echo "  0,"
  echo "};"
} > $header
clang -O2 -I $DEMO_WORK -o $DEMO_APP/Contents/MacOS/JustSessions $DEMO_VIDEO_TOOLS/environment/demo_launcher.c

info=$DEMO_APP/Contents/Info.plist
plutil -replace CFBundleIdentifier -string $DEMO_BUNDLE_IDENTIFIER $info
plutil -replace SUEnableAutomaticChecks -bool NO $info
codesign --force --deep -s - $DEMO_APP 2>&1 | grep -v "replacing existing signature" || true

# Preferences live in this account's ~/Library/Preferences under the demo bundle ID; CFFIXED_USER_HOME doesn't move them.
defaults write $DEMO_BUNDLE_IDENTIFIER interfaceLanguage -string en
defaults write $DEMO_BUNDLE_IDENTIFIER appAppearance -string light
defaults write $DEMO_BUNDLE_IDENTIFIER showsOnboardingTips -bool false
defaults write $DEMO_BUNDLE_IDENTIFIER showsRandomTips -bool false
defaults write $DEMO_BUNDLE_IDENTIFIER offersCrashReportsAtLaunch -bool false
defaults write $DEMO_BUNDLE_IDENTIFIER reopensTabsAtLaunch -bool false
defaults write $DEMO_BUNDLE_IDENTIFIER remoteHosts -array $DEMO_SSH_ALIAS
defaults write $DEMO_BUNDLE_IDENTIFIER sessionNotifications -data \
  "$(printf '{"notifiesWhenInputNeeded":false,"notifiesWhenTurnFinishes":false}' | xxd -p | tr -d '\n')"
echo "built $DEMO_APP from $DEMO_SOURCE_APP ($(plutil -extract CFBundleShortVersionString raw $info))"
