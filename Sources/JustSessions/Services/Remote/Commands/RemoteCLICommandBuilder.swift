import Foundation

/// Builds the `ssh -t <host> …` command a terminal tab runs to open a session on a remote host.
/// With a tmux session name, the CLI runs inside that tmux session, so it keeps running when the connection
/// drops or the tab closes, and opening the same name again reattaches to it.
struct RemoteCLICommandBuilder {
    let inheritedEnvironment: [String: String]
    let loginConnections: SSHLoginConnections
    /// See `SSHKeystrokeTiming`.
    let keystrokeTimingOptions: [String]

    init(
        inheritedEnvironment: [String: String] = SSHProcessEnvironment.standard,
        loginConnections: SSHLoginConnections = .shared,
        keystrokeTimingOptions: [String] = SSHKeystrokeTiming.options
    ) {
        self.inheritedEnvironment = inheritedEnvironment
        self.loginConnections = loginConnections
        self.keystrokeTimingOptions = keystrokeTimingOptions
    }

    /// `startCommand` is one set in the New session sheet; nil starts the tool's own executable. It stands in for
    /// `defaultStartCommand`, so the app's arguments that follow leave out what it holds. `usesHostTmuxPrefix` is the
    /// host's choice in `RemoteHostsUsingTmuxPrefix`, so every tab's command passes it.
    func command(
        host: String,
        provider: ConversationProvider,
        projectPath: String,
        arguments: [String],
        tmuxSessionName: String? = nil,
        usesHostTmuxPrefix: Bool,
        startCommand: String? = nil
    ) -> NativeCLICommand {
        sshCommand(
            host: host,
            remoteCommand: Self.remoteCommand(
                provider: provider,
                projectPath: projectPath,
                arguments: arguments,
                tmuxSessionName: tmuxSessionName,
                usesHostTmuxPrefix: usesHostTmuxPrefix,
                startCommand: startCommand,
                shellStartup: RemoteHostShellStartups.shared.startup(on: host),
                cliLocation: RemoteHostCLILocations.shared.location(of: provider, on: host)
            )
        )
    }

    /// `ssh -t <host> <remoteCommand>`, with a terminal for the remote command. On a host logged in to with
    /// Connect…, the tab goes through that login, so it asks nothing; without one, `ssh` asks in the tab's terminal.
    func sshCommand(host: String, remoteCommand: String) -> NativeCLICommand {
        NativeCLICommand(
            executablePath: "/usr/bin/ssh",
            arguments: ["-t"]
                + loginConnections.connectionOptions(for: host)
                + [
                    // Notice a dead connection within a minute, so the tab ends and offers to reconnect.
                    "-o", "ServerAliveInterval=15", "-o", "ServerAliveCountMax=4",
                ]
                + keystrokeTimingOptions
                + [
                    // With a `RemoteCommand` in `~/.ssh/config`, `ssh` would refuse to run the tab's command.
                    "-o", "RemoteCommand=none",
                    host,
                    remoteCommand,
                ],
            workingDirectory: NSHomeDirectory(),
            environment: NativeCLICommand.environmentEntries(
                TerminalColorEnvironment.embeddedTerminalEnvironment(from: inheritedEnvironment)
            )
        )
    }

    /// A tab's command to connect again, through the host's login open now: the login it went through may have
    /// closed since, and Connect… may have opened another, or the first, since the tab opened.
    func withCurrentLogin(_ command: NativeCLICommand, host: String) -> NativeCLICommand {
        var arguments = command.arguments
        // `sshCommand` puts a login's options right after `-t`.
        if arguments.count > 5, Array(arguments[1...3]) == ["-o", "ControlMaster=no", "-o"],
           arguments[4].hasPrefix("ControlPath=") {
            arguments.removeSubrange(1...4)
        }
        arguments.insert(contentsOf: loginConnections.connectionOptions(for: host), at: 1)
        return NativeCLICommand(
            executablePath: command.executablePath,
            arguments: arguments,
            workingDirectory: command.workingDirectory,
            environment: command.environment
        )
    }

    /// What the tab's login shells on the host set for the CLI and for tmux. `ssh` gives the host the tab's `TERM` but
    /// not its `COLORTERM`. Without it a CLI in tmux before 3.3, whose terminal is `screen`, keeps to the 16 ANSI
    /// colors, and Claude Code draws its selection in ANSI black, the background of themes such as Atom One Dark.
    /// tmux 3.6 and later also read it as the tab showing RGB colors.
    static let terminalEnvironment = ["COLORTERM=truecolor"]

    /// Runs the CLI through the host's login shell, so the PATH set up in the host's shell profile
    /// (for example `~/.local/bin` or an nvm-managed `node`) is in effect, and so are its aliases and functions; see
    /// `RemoteShellStartup` and `RemoteCLIInvocation`. Without tmux on the host, the CLI runs directly.
    static func remoteCommand(
        provider: ConversationProvider,
        projectPath: String,
        arguments: [String],
        tmuxSessionName: String? = nil,
        usesHostTmuxPrefix: Bool = false,
        startCommand: String? = nil,
        shellStartup: RemoteShellStartup = .interactive,
        cliLocation: RemoteCLILocation = .loginShell
    ) -> String {
        let directCommand = CLIStartCommandLine.customCommand(startCommand).map {
            let invocation = CLIStartCommandLine.remoteInvocation(
                startCommand: $0,
                arguments: provider.argumentsAfterCustomStartCommand(arguments)
            )
            return "cd \(ShellQuoting.quoted(projectPath)) && exec \(invocation)"
        } ?? RemoteCLIInvocation.startCommand(
            executableName: provider.executableName,
            location: cliLocation,
            projectPath: projectPath,
            quotedArguments: arguments.map(ShellQuoting.quoted)
        )
        func inLoginShell(_ command: String) -> String {
            shellStartup.command(running: command, environment: terminalEnvironment)
        }
        guard let tmuxSessionName else { return inLoginShell(directCommand) }
        // `-A` attaches when the session already runs, and the options after it are set again on every attach.
        // The status line and mouse settings make it look and scroll like the CLI on its own, and with no prefix
        // key Ctrl-B reaches the CLI, unless the host uses its own; see `RemoteTmuxPrefixOptions`. Passthrough lets
        // a CLI's copy reach this Mac's clipboard: OpenCode sends OSC 52 wrapped for tmux, which tmux 3.3 and later
        // drop with it off, and its unwrapped OSC 52 only with the server-wide `set-clipboard on`. Older tmux always
        // passes it, and `-q` skips the option there. These are options of this session and its window only; the
        // host's other tmux sessions keep theirs. The exception is `escape-time`, a server option: tmux before 3.5,
        // such as Ubuntu 24.04's 3.4, waits 500 ms after Esc to see whether a longer key sequence follows, so Esc
        // reached the CLI half a second late. The host's other sessions get 10 ms too, as tmux 3.5 and later give
        // them anyway.
        let sessionOptions = [
            "set-option status off", "set-option mouse on", "set-option -wq allow-passthrough on",
            "set-option -s escape-time 10",
        ]
            + RemoteTmuxPrefixOptions.setOptionCommands(usingHostPrefix: usesHostTmuxPrefix)
        let tmuxCommand = "exec tmux new-session -A -s \(ShellQuoting.quoted(tmuxSessionName)) "
            + ShellQuoting.quoted(inLoginShell(directCommand))
            + sessionOptions.map { " \\; \($0)" }.joined()
        // The login shell may be fish, which has no `if …; then …; fi`; `&&` and `;` read the same in both. When tmux
        // is found, `exec` replaces the shell, so the CLI runs directly only without it.
        return inLoginShell("command -v tmux >/dev/null 2>&1 && \(tmuxCommand); \(directCommand)")
    }

    /// Runs `innerCommand` in the host's login shell, started as the host needs; see `RemoteShellStartup`.
    static func loginShellCommand(_ innerCommand: String, on host: String) -> String {
        RemoteHostShellStartups.shared.startup(on: host).command(running: innerCommand)
    }
}
