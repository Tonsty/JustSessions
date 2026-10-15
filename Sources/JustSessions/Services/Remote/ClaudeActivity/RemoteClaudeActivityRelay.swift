import Foundation

/// Tells a tab what a Claude Code on an SSH host does. Claude Code writes that only in its live process registry on the
/// host, `~/.claude/sessions/<pid>.json` (see `ClaudeLiveSessionRecord`), and its terminal title stays `✳ <topic>`
/// through a turn. So a tab's tmux session starts this relay beside the CLI. Once a second it reads the record whose
/// `tmux` entry names the relay's pane, as `<session>:<window id>.<pane id>`, and when its `status` or `waitingFor`
/// changes, sets them as the window option the session's title shows; see `RemoteClaudeActivityTitle`. tmux passes
/// that title on to the tab over the tab's own connection, as it passes Codex's.
///
/// The pane's login shell starts it before the CLI, so it sees a `CLAUDE_CONFIG_DIR` the host's startup files set. It
/// runs in `sh`, as that shell may be fish. It starts once with the pane and ends with the pane's process, so it goes
/// on while no tab is attached, and a tab that reattaches starts no second one. Between reads it costs one `sleep`: it
/// reads the record, one line of JSON, with the shell's own `read`, and looks for it again only while it is missing, as
/// before Claude Code writes it. A record cut short, as one read while Claude Code writes it, leaves the last activity.
///
/// A window option works in tmux before 3.0, which has no pane options, and tmux 3.0 and later redraw the title when it
/// changes, as they don't for a session option. `refresh-client -S` makes tmux before 2.6 redraw it too.
enum RemoteClaudeActivityRelay {
    /// Starts the relay in the background and returns at once, so the CLI starts as before.
    static let launchCommand = "sh -c \(ShellQuoting.quoted("(\n\(script)\n) </dev/null >/dev/null 2>&1 &"))"

    static let script = #"""
        pane_pid=$(tmux display-message -p -t "$TMUX_PANE" '#{pane_pid}') || exit 0
        location=$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}:#{window_id}.#{pane_id}') || exit 0
        records=${CLAUDE_CONFIG_DIR:-$HOME/.claude}/sessions
        record= shown=
        while kill -0 "$pane_pid" 2>/dev/null; do
          [ -f "$record" ] || record=$(grep -lF "\"tmux\":\"$location\"" "$records"/*.json 2>/dev/null | head -n 1)
          json=
          [ -n "$record" ] && IFS= read -r json < "$record"
          case $json in
          *'"status":"'*'}')
            status=${json#*'"status":"'} reason=
            case $json in *'"waitingFor":"'*) reason=${json#*'"waitingFor":"'} ;; esac
            activity=${status%%'"'*}:${reason%%'"'*}
            if [ "$activity" != "$shown" ]; then
              tmux set-option -wq -t "$TMUX_PANE" \#(RemoteClaudeActivityTitle.optionName) "$activity" \; refresh-client -S
              shown=$activity
            fi
            ;;
          esac
          sleep 1
        done
        """#
}
