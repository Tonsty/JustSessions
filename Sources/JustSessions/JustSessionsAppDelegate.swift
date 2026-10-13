import AppKit

/// AppKit launch events and the Dock menu, which SwiftUI's `App` has no hook for.
final class JustSessionsAppDelegate: NSObject, NSApplicationDelegate {
    /// `NSApp` does not exist yet while `JustSessionsApp` is created. Here it does, and no window is open, so the
    /// first window already opens in the saved appearance. Clicks on notifications need their handler this early too.
    /// Onboarding reads whether this is a fresh install before anything this launch saves a setting, and the random tip
    /// whether onboarding's tour is due before it starts.
    func applicationWillFinishLaunching(_ notification: Notification) {
        _ = OnboardingTipsStore.shared
        _ = RandomTipsStore.shared
        AppAppearanceStore.shared.applyToApplication()
        SessionNotificationCenter.shared.startHandlingClicks()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        GhosttyResourcesLaunchCheck.runIfAsked()
        LaunchCrashReportOffer.offerIfTheLastRunCrashed()
        ZoomInEqualsKey.startForwarding()
        HostAutoRefresher.shared.start()
        DispatchQueue.global(qos: .utility).async { SSHLoginConnections.closeLoginsOfEndedApps() }
    }

    /// Logins made with Connect… end with the app; nothing it typed for them is kept.
    func applicationWillTerminate(_ notification: Notification) {
        SSHLoginConnections.shared.disconnectAll()
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        WorkspaceDockMenu.shared.makeMenu()
    }
}
