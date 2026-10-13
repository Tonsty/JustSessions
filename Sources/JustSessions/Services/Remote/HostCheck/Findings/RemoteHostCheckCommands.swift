import Foundation

/// The commands a finding offers to run in your own terminal. Each does what the check did, so its answer can be seen
/// without JustSessions. They are typed into zsh on this Mac and read again by the host's shell, so a value that
/// either would change, such as one with a quote or `$`, gets no command rather than a wrong one.
enum RemoteHostCheckCommands {
    /// `ssh host 'command'`, run by the shell `ssh` starts on the host.
    static func ssh(_ host: String, _ remoteCommand: String) -> String? {
        guard isPlain(host), !remoteCommand.contains("'") else { return nil }
        return "ssh \(host) '\(remoteCommand)'"
    }

    /// `ssh host 'env JUSTSESSIONS=1 "$SHELL" -lic "command"'`: in the login shell the app's commands use, with the
    /// variable they get; see `RemoteShellStartup`.
    static func inLoginShell(_ host: String, _ innerCommand: String, startup: RemoteShellStartup) -> String? {
        guard !innerCommand.contains("\""), !innerCommand.contains("$"), !innerCommand.contains("`") else { return nil }
        return ssh(host, "\(loginShellPrefix(startup)) \"\(innerCommand)\"")
    }

    /// Logs in with a terminal, as a tab does, and prints a line once the login shell's startup has finished.
    static func shellStartup(_ host: String, startup: RemoteShellStartup) -> String? {
        guard isPlain(host) else { return nil }
        return "ssh -t \(host) '\(loginShellPrefix(startup)) \"echo Startup finished\"'"
    }

    /// Letters, digits, and the punctuation of host names and paths that no shell reads specially.
    static func isPlain(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || "@._-/~+:,".contains($0)) }
    }

    private static func loginShellPrefix(_ startup: RemoteShellStartup) -> String {
        "env \(RemoteShellStartup.environmentVariable)=1 \"$SHELL\" " + (startup == .interactive ? "-lic" : "-lc")
    }
}
