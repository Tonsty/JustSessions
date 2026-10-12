# Shared settings for the demo video tools. Every script sources this file; the Python and Swift tools read the
# exported values. See docs/development/demo-video.md.

export DEMO_VIDEO_TOOLS=${${(%):-%x}:A:h}
export DEMO_VIDEO_REPOSITORY=${DEMO_VIDEO_TOOLS:h:h}

# Everything generated: the demo app, raw takes, sample-session snapshot, models, and renders. Ignored by git.
export DEMO_WORK=${DEMO_WORK:-$DEMO_VIDEO_REPOSITORY/dist/demo-video}
# The demo app's home folder. Outside the repository, so the CLIs don't load its AGENTS.md, and short, so the
# paths the CLIs print on screen stay readable.
export DEMO_HOME=${DEMO_HOME:-/Users/Shared/demo}

# The demo app is a copy of a built JustSessions with its own bundle ID, so it has its own preferences, and a
# launcher that points it at DEMO_HOME and its own tmux folder.
export DEMO_SOURCE_APP=${DEMO_SOURCE_APP:-$DEMO_VIDEO_REPOSITORY/dist/JustSessions.app}
export DEMO_BUNDLE_IDENTIFIER=dev.zichaoyang.justsessions.demo
export DEMO_APP=$DEMO_WORK/JustSessions.app
export DEMO_APP_EXECUTABLE=$DEMO_APP/Contents/MacOS/JustSessionsReal
export DEMO_TMUX_DIRECTORY=$DEMO_WORK/tmux
# The app's tmux socket is $DEMO_TMUX_DIRECTORY/tmux-<uid>/justsessions, and macOS caps a socket path at 103 bytes.
if (( ${#DEMO_TMUX_DIRECTORY} + ${#UID} + 19 > 103 )); then
  echo "DEMO_WORK's path is too long for the app's tmux socket; set a shorter DEMO_WORK." >&2
  return 1
fi

# Screen geometry, in points on the main display. The recorder captures the stage at 2x; the app window sits
# inside it with a margin of the stage's dark background.
export DEMO_STAGE="64 150 1600 900"
export DEMO_WINDOW_FRAME="144 195 1440 810"

# The canned model server that gives Codex, OpenCode, and Pi their sample history.
export DEMO_MODEL_PORT=${DEMO_MODEL_PORT:-18765}

# SSH: the standard test VM (docs/development/ssh-testing.md) plays a server called devbox, logged in as dev.
export DEMO_VM_ADMIN_ALIAS=${DEMO_VM_ADMIN_ALIAS:-justsessions-test}
export DEMO_SSH_ALIAS=devbox
export DEMO_REMOTE_USER=dev
# The demo app reaches the VM through a forward on this Mac's loopback, which Local Network privacy doesn't cover.
export DEMO_LOOPBACK_PORT=${DEMO_LOOPBACK_PORT:-2222}

# The environment the demo app gives its terminals, and the CLIs run with when generating sample sessions.
demo_isolated_environment=(
  HOME=$DEMO_HOME
  ZDOTDIR=$DEMO_HOME
  CLAUDE_CONFIG_DIR=$DEMO_HOME/.claude
  CODEX_HOME=$DEMO_HOME/.codex
  KIRO_HOME=$DEMO_HOME/.kiro
  PI_CODING_AGENT_DIR=$DEMO_HOME/.pi/agent
  XDG_DATA_HOME=$DEMO_HOME/.local/share
  XDG_CONFIG_HOME=$DEMO_HOME/.config
  XDG_STATE_HOME=$DEMO_HOME/.local/state
  XDG_CACHE_HOME=$DEMO_HOME/.cache
  TMUX_TMPDIR=$DEMO_TMUX_DIRECTORY
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
  PATH=$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
)
