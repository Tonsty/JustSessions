import Foundation

/// tmux commands for a remote host's JustSessions sessions, run through the login shell so `tmux` is found
/// wherever the host's profile puts it.
enum RemoteTmuxCommands {
    static func renameSessionCommand(from oldName: String, to newName: String, on host: String) -> String {
        RemoteCLICommandBuilder.loginShellCommand(
            "tmux rename-session -t \(ShellQuoting.quoted(oldName)) \(ShellQuoting.quoted(newName)) 2>/dev/null; true",
            on: host
        )
    }

    /// Exits with 0 only while the host's tmux runs the session; a host without tmux fails it too. The target is
    /// exactly that session, not one whose name starts with it; see `RemoteTmuxGeneration.exactSessionPrefix`. `sh`
    /// runs it, as the login shell may be fish.
    static func hasSessionCommand(_ name: String, on host: String) -> String {
        let script = [
            "name=\(ShellQuoting.quoted(name))",
            RemoteTmuxGeneration.exactSessionPrefixAssignment,
            "tmux has-session -t \"$exact$name\" 2>/dev/null",
        ].joined(separator: "\n")
        return RemoteCLICommandBuilder.loginShellCommand("sh -c \(ShellQuoting.quoted(script))", on: host)
    }

    /// Replaces each client attached to the session with a new client in the same terminal, which tmux asks for the
    /// terminal's colors as it attaches. The session and its CLI run on. Exits with 0 once the clients have detached.
    /// tmux before 2.4 has no `detach-client -E`, so there it fails at once and the clients stay, as on a host without
    /// tmux.
    static func reattachClientsCommand(_ name: String, on host: String) -> String {
        let target = ShellQuoting.quoted("=" + name)
        let attach = "exec tmux attach-session -t \(target)"
        return RemoteCLICommandBuilder.loginShellCommand(
            "tmux detach-client -s \(target) -E \(ShellQuoting.quoted(attach))",
            on: host
        )
    }

    static func killSessionCommand(_ name: String, on host: String) -> String {
        RemoteCLICommandBuilder.loginShellCommand(
            "tmux kill-session -t \(ShellQuoting.quoted(name)) 2>/dev/null; true",
            on: host
        )
    }

    /// Ends the session as `killSessionCommand` does, then waits up to `timeoutSeconds` for its CLI to exit, so the
    /// session can be deleted without the CLI writing to it again. The CLI is the pane's process, or, for an alias or
    /// function the login shell runs, a child of it, which may outlive the shell once both hang up; see
    /// `RemoteCLIInvocation`. `sh` runs the script, as the login shell may be fish.
    static func killSessionWaitingForCLIExitCommand(_ name: String, on host: String, timeoutSeconds: Int) -> String {
        let script = [
            "name=\(ShellQuoting.quoted(name))",
            RemoteTmuxGeneration.exactSessionPrefixAssignment,
            // The name with `:` after it is the session's pane; the name alone is no pane.
            "pid=$(tmux display-message -p -t \"$exact$name:\" '#{pane_pid}' 2>/dev/null)",
            // `ps -A -o pid= -o ppid=` lists every process with its parent on Linux, macOS, and BusyBox.
            "pids=\"$pid $([ -n \"$pid\" ] && ps -A -o pid= -o ppid= 2>/dev/null | awk -v parent=\"$pid\" '$2 == parent { print $1 }')\"",
            "tmux kill-session -t \"$exact$name\" 2>/dev/null",
            "running() { for p in $pids; do kill -0 \"$p\" 2>/dev/null && return 0; done; return 1; }",
            // A deadline rather than a count of polls: each poll starts `sleep`, which takes its own time.
            "deadline=$(($(date +%s) + \(timeoutSeconds)))",
            "while [ -n \"$pid\" ] && running && [ \"$(date +%s)\" -lt \"$deadline\" ]; do sleep 0.1; done",
            "true",
        ].joined(separator: "; ")
        return RemoteCLICommandBuilder.loginShellCommand("sh -c \(ShellQuoting.quoted(script))", on: host)
    }

    /// Gives every JustSessions session on the host the prefix keys `RemoteTmuxPrefixOptions` describes, so a new
    /// choice reaches tabs already attached and sessions no tab shows, which you may attach to yourself. `sh` runs the
    /// loop, as the login shell may be fish.
    static func setPrefixOptionsCommand(usingHostPrefix: Bool, on host: String) -> String {
        // `set-option` takes a pane, the name with `:` after it; the name alone finds nothing.
        let setOptions = RemoteTmuxPrefixOptions.setOptionCommands(
            usingHostPrefix: usingHostPrefix, target: "\"$exact$name:\"", unusedKey: "\"$unused_key\""
        )
        let forHostTmux = RemoteTmuxGeneration.caseStatement {
            "exact=\(ShellQuoting.quoted($0.exactSessionPrefix)) unused_key=\($0.unusedPrefixKey)"
        }
        let script = forHostTmux
            + "\ntmux list-sessions -F '#{session_name}' 2>/dev/null | grep '^\(TmuxSessionName.prefix)'"
            + " | while IFS= read -r name; do tmux \(setOptions.joined(separator: " \\; ")) 2>/dev/null; done; true"
        return RemoteCLICommandBuilder.loginShellCommand("sh -c \(ShellQuoting.quoted(script))", on: host)
    }
}
