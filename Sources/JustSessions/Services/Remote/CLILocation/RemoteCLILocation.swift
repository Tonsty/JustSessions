import Foundation

/// Where an SSH host's tabs start a tool's CLI from, as the host's last refresh found it; see `RemoteHostStatusProbe`.
enum RemoteCLILocation: Equatable, Sendable {
    /// The host's login shell finds the CLI's name: a program on its PATH, or an alias or function of the shell's own,
    /// which a tab runs as typing the name would, with the alias's arguments.
    case loginShell
    /// The login shell doesn't find the name, but the CLI is where its installer puts it, in a folder that shell's
    /// PATH leaves out, such as `~/.claude/local` or an nvm version's `bin`; see `RemoteCLIInstallFolders`. A tab
    /// starts it by this path, with its folder first on PATH, so a Node CLI finds the `node` beside it.
    case installed(path: String)
}
