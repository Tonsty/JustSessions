#!/bin/zsh
# other_cli_sessions.sh: gives Codex, OpenCode, and Pi real sample sessions by running each CLI in the demo home
# against the canned model server. Then it names them the way each CLI records a rename, and snapshots them for
# recording/reset_demo.sh. Run it again after a CLI update changes its session format.
set -e
source ${0:A:h:h}/settings.sh
tools=$DEMO_VIDEO_TOOLS
run_isolated=$tools/environment/run_isolated.sh
socket=$DEMO_TMUX_DIRECTORY/probe.sock
web=$DEMO_HOME/Projects/orbit-web
api=$DEMO_HOME/Projects/orbit-api
opencode_database=$DEMO_HOME/.local/share/opencode/opencode.db

$tools/environment/services.sh start
rm -rf $DEMO_HOME/.codex/sessions $DEMO_HOME/.codex/session_index.jsonl $DEMO_HOME/.pi/agent/sessions $opencode_database*(N)

# Codex: typed into its interactive composer, which records the session the way a person's would.
codex_session() {
  local directory=$1 prompt=$2 session=codex-${RANDOM}
  $tools/environment/run_in_isolated_tmux.sh $session $directory 8 codex > /dev/null
  tmux -S $socket send-keys -t $session -l $prompt
  sleep 0.5
  tmux -S $socket send-keys -t $session Enter
  sleep 8
  tmux -S $socket kill-session -t $session
}
codex_session $web "Refactor the settings page into smaller components"
codex_session $api "Migrate the database to Postgres 17"
pkill -f "$DEMO_HOME/.codex/packages" 2>/dev/null || true

# Both read a piped stdin into the prompt and wait for it to close, so give them an empty one.
$run_isolated $web perl -e 'alarm 120; exec @ARGV' opencode run "Write e2e tests for the sign-in flow" < /dev/null > /dev/null
sqlite3 $opencode_database "update session set title = 'E2E tests for sign-in';"
$run_isolated $web perl -e 'alarm 60; exec @ARGV' pi -p "Update the README with the new install steps" < /dev/null > /dev/null
(cd $tools/fixtures && python3 name_other_sessions.py > /dev/null)

codex_count=$(find $DEMO_HOME/.codex/sessions -name 'rollout-*.jsonl' | wc -l | tr -d ' ')
opencode_count=$(sqlite3 $opencode_database "select count(*) from session;")
pi_count=$(find $DEMO_HOME/.pi/agent/sessions -name '*.jsonl' | wc -l | tr -d ' ')
echo "sessions: Codex $codex_count, OpenCode $opencode_count, Pi $pi_count"
[[ $codex_count == 2 && $opencode_count == 1 && $pi_count == 1 ]] || { echo "expected 2, 1, and 1"; exit 1; }

snapshot=$DEMO_WORK/session-snapshot
rm -rf $snapshot
mkdir -p $snapshot
cp -p $DEMO_HOME/.codex/session_index.jsonl $snapshot/
cp -Rp $DEMO_HOME/.codex/sessions $snapshot/codex-sessions
cp -Rp $DEMO_HOME/.pi/agent/sessions $snapshot/pi-sessions
sqlite3 $opencode_database ".backup $snapshot/opencode.db"
echo "snapshot in $snapshot"
