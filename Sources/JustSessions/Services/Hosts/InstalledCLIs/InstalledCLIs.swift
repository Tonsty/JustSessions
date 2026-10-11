import Foundation

/// Finds which tools' CLIs are installed, so new sessions only offer those. SSH hosts answer in their refresh;
/// see `RemoteHostStatusProbe`.
enum InstalledCLIs {
    /// The tools whose CLI a launch on this Mac would find. The first lookup reads the login shell's PATH, so call
    /// this off the main actor.
    static func onThisMac(commandResolver: NativeCLICommandResolver) -> Set<ConversationProvider> {
        // `.never` cannot throw.
        (try? onThisMac(commandResolver: commandResolver, cancellation: .never)) ?? []
    }

    static func onThisMac(
        commandResolver: NativeCLICommandResolver,
        cancellation: ConversationDiscoveryCancellation
    ) throws -> Set<ConversationProvider> {
        var installed: Set<ConversationProvider> = []
        for provider in ConversationProvider.allCases {
            try cancellation.checkCancellation()
            if commandResolver.executablePath(named: provider.executableName) != nil { installed.insert(provider) }
        }
        return installed
    }
}
