import Foundation

/// A tool's CLI as Check this host… looks for it on the host: the program the tool starts with there.
struct RemoteHostCheckProgram: Equatable, Sendable {
    let provider: ConversationProvider
    /// The tool's executable, or the program of your start command for the tool on the host.
    let program: String
    /// Only the executable the app starts by itself is asked for `--version`; a start command of your own may run a
    /// script that does something else with it.
    let asksVersion: Bool

    /// The output key of its lookup; see `RemoteHostCheckScript`.
    var key: String { "cli-" + provider.executableName }

    /// One for each tool, with your start command's program in place of the executable where you set one. A tool
    /// whose start command names its program only when it runs, such as through a variable, is left out: looking up
    /// the executable instead would check something the tool doesn't start with. So is a program whose name the
    /// check can't quote; see `RemoteHostCheckScript.doubleQuoted(_:)`.
    static func all(startCommands: (ConversationProvider) -> String?) -> [RemoteHostCheckProgram] {
        ConversationProvider.allCases.compactMap { provider in
            guard let startCommand = CLIStartCommandLine.customCommand(startCommands(provider)) else {
                return RemoteHostCheckProgram(provider: provider, program: provider.executableName, asksVersion: true)
            }
            guard case .program(let program) = StartCommandShape(startCommand),
                  RemoteHostCheckScript.doubleQuoted(program) != nil else { return nil }
            return RemoteHostCheckProgram(provider: provider, program: program, asksVersion: false)
        }
    }
}
