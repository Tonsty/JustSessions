import Foundation

/// Asks a remote host, in one SSH round trip per refresh, which tmux sessions JustSessions started there still run
/// and where each tool's CLI is. Runs through the login shell so both `tmux` and the CLIs are found wherever the
/// host's profile puts them, as its aliases and functions too; a CLI that shell doesn't find is looked for in the
/// folders installers put it in; see `RemoteCLILocation`.
enum RemoteHostStatusProbe {
    /// Separates the tmux session names above it from the CLIs the login shell finds below it. Has spaces, so it is
    /// never taken for a tmux session name.
    static let installedCLIsHeading = "JustSessions installed CLIs:"
    /// Comes after those CLIs, before the `<executable name> <path>` lines of the install folders' search.
    static let installFoldersHeading = "JustSessions CLIs in install folders:"

    static func command(on host: String) -> String {
        command(startup: RemoteHostShellStartups.shared.startup(on: host))
    }

    /// `type` finds aliases and functions as well as programs, in fish too, whose `command -v` finds only programs.
    static func command(startup: RemoteShellStartup) -> String {
        let executableNames = ConversationProvider.allCases.map(\.executableName)
        let cliChecks = executableNames.map { name in
            let name = ShellQuoting.quoted(name)
            return "type \(name) >/dev/null 2>&1 && echo \(name)"
        }
        let installFoldersSearch = "sh -c " + ShellQuoting.quoted(RemoteCLIInstallFolders.searchScript(executableNames: executableNames))
        return startup.command(
            running: (["tmux list-sessions -F '#{session_name}' 2>/dev/null", "echo \(ShellQuoting.quoted(installedCLIsHeading))"]
                + cliChecks
                + ["echo \(ShellQuoting.quoted(installFoldersHeading))", installFoldersSearch, "true"])
                .joined(separator: "; ")
        )
    }

    /// Nil when the host could not be reached.
    static func status(
        ofHost host: String,
        runner: RemoteHostCommandRunner = RemoteHostCommandRunner()
    ) -> RemoteHostStatus? {
        status(ofHost: host, startup: RemoteHostShellStartups.shared.startup(on: host), runner: runner)
    }

    static func status(
        ofHost host: String,
        startup: RemoteShellStartup,
        runner: RemoteHostCommandRunner = RemoteHostCommandRunner()
    ) -> RemoteHostStatus? {
        guard let result = runner.run(host, command(startup: startup), 30),
              result.exitStatus != RemoteHostCommandRunner.connectionFailureExitStatus else { return nil }
        return status(inOutput: result.output)
    }

    /// Lines a shell profile prints come before everything else, so only lines after the heading name CLIs.
    static func status(inOutput output: String) -> RemoteHostStatus {
        let lines = output.split(whereSeparator: \.isNewline).map { $0.trimmingCharacters(in: .whitespaces) }
        guard let headingIndex = lines.lastIndex(of: installedCLIsHeading) else {
            return RemoteHostStatus(tmuxSessionNames: TmuxSessionName.appSessionNames(inListOutput: output), cliLocations: nil)
        }
        let foldersHeadingIndex = lines[headingIndex...].firstIndex(of: installFoldersHeading) ?? lines.endIndex
        let namesFoundByLoginShell = Set(lines[(headingIndex + 1)..<foldersHeadingIndex])
        let installFolderPaths = lines.dropFirst(foldersHeadingIndex + 1).compactMap { line -> (name: String, path: String)? in
            guard let space = line.firstIndex(of: " ") else { return nil }
            return (String(line[..<space]), String(line[line.index(after: space)...]))
        }
        var cliLocations: [ConversationProvider: RemoteCLILocation] = [:]
        for provider in ConversationProvider.allCases {
            if namesFoundByLoginShell.contains(provider.executableName) {
                cliLocations[provider] = .loginShell
            } else if let path = RemoteCLIInstallFolders.preferredPath(
                among: installFolderPaths.filter { $0.name == provider.executableName }.map(\.path)
            ) {
                cliLocations[provider] = .installed(path: path)
            }
        }
        return RemoteHostStatus(
            tmuxSessionNames: TmuxSessionName.appSessionNames(inListOutput: lines[..<headingIndex].joined(separator: "\n")),
            cliLocations: cliLocations
        )
    }
}
