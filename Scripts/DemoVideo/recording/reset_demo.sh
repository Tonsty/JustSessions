#!/bin/zsh
# reset_demo.sh: puts the demo app, its tmux sessions, and every sample session back to the state each take starts
# from. It doesn't touch the mouse or keyboard; the app opens in the background.
set -e
source ${0:A:h:h}/settings.sh
driver=$DEMO_WORK/bin/demo-driver
snapshot=$DEMO_WORK/session-snapshot
tmux=$DEMO_APP/Contents/Resources/Tmux/bin/tmux

$DEMO_VIDEO_TOOLS/environment/services.sh start > /dev/null
$DEMO_VIDEO_TOOLS/environment/quit_demo_app.sh
$tmux -S $DEMO_TMUX_DIRECTORY/tmux-$UID/justsessions kill-server 2>/dev/null || true
pkill -f "$DEMO_HOME/.codex/packages" 2>/dev/null || true
ssh -o ConnectTimeout=5 $DEMO_SSH_ALIAS 'tmux -L justsessions kill-server 2>/dev/null; tmux kill-server 2>/dev/null; true'

# Claude Code sessions come from the fixture scripts; the other CLIs' from the snapshot other_cli_sessions.sh took.
(cd $DEMO_VIDEO_TOOLS/fixtures && python3 local_sessions.py > /dev/null && python3 remote_sessions.py > /dev/null)
ssh $DEMO_SSH_ALIAS 'rm -rf ~/.claude/projects ~/ingest-service'
rsync -a $DEMO_WORK/remote-home/ $DEMO_SSH_ALIAS:
rm -rf $DEMO_HOME/.codex/sessions $DEMO_HOME/.pi/agent/sessions
cp -Rp $snapshot/codex-sessions $DEMO_HOME/.codex/sessions
cp -p $snapshot/session_index.jsonl $DEMO_HOME/.codex/session_index.jsonl
cp -Rp $snapshot/pi-sessions $DEMO_HOME/.pi/agent/sessions
opencode_database=$DEMO_HOME/.local/share/opencode/opencode.db
sqlite3 $opencode_database ".restore $snapshot/opencode.db"
# The app opens this database read-only, which fails for a WAL database with no -wal/-shm files beside it.
sqlite3 $opencode_database "pragma journal_mode=delete;" >/dev/null
(cd $DEMO_VIDEO_TOOLS/fixtures && python3 reset_session_times.py > /dev/null)

defaults delete $DEMO_BUNDLE_IDENTIFIER terminalTabsToReopen >/dev/null 2>&1 || true
open -g $DEMO_APP
for _ in {1..40}; do $driver windows 2>/dev/null | grep -q AXWindow && break; sleep 0.3; done
sleep 2
$driver setframe 0 ${=DEMO_WINDOW_FRAME} >/dev/null
for project in orbit-web orbit-api ingest-service; do $driver press "Expand $project" AXButton >/dev/null 2>&1 || true; done
# The first scan after launch can miss OpenCode's database; a refresh lists it.
sleep 1
$driver press "Refresh sessions on this Mac" AXButton >/dev/null
sleep 2
$driver dump 0 30 | grep -q "E2E tests for sign-in, OpenCode" || echo "WARNING: OpenCode session not listed"
echo "demo reset"
