import Darwin
import Foundation
import GhosttyTerminal

/// The launch check, `Scripts/Release/check-app-launches.sh`, opens the packaged app with no tabs, so no Ghostty
/// terminal looks for the resource bundle that Ghostty's package stops the app without. Asked with
/// `-checksGhosttyResourcesAtLaunch YES`, the app makes the controller a Ghostty terminal makes first, which looks the
/// bundle up, and quits with an error when the shell integration or terminfo in it can't be found. v1.2.0 stopped on
/// every Mac but the one that built it as soon as Ghostty was chosen.
@MainActor
enum GhosttyResourcesLaunchCheck {
    static let userDefaultsKey = "checksGhosttyResourcesAtLaunch"

    static func runIfAsked(userDefaults: UserDefaults = .standard) {
        guard userDefaults.bool(forKey: userDefaultsKey) else { return }
        _ = GhosttyTerminalControllers.shared.controller(appearanceStore: .shared, themeStore: .shared)
        guard GhosttyRuntimeResources.directoryURL != nil, GhosttyRuntimeResources.terminfoDirectoryURL != nil else {
            FileHandle.standardError.write(Data("Ghostty's shell integration or terminfo is missing from the app.\n".utf8))
            exit(1)
        }
    }
}
