import Foundation

/// Turns off AppKit's window open and close animations for the test process, in the registration domain, so nothing is
/// saved. Each animation runs a run loop on a dispatch worker thread, and one cut short by a test closing its window at
/// once never ends. Enough of them fill dispatch's thread pool, and the terminal tests that run after stop getting
/// their PTY's output and input (a full run's GhosttyTabInputTests and TerminalPromptSelectionTests waits ran out with
/// 65 threads stuck in `-[NSAnimation _runBlocking]`). Tests that show a titled window with key focus call this first.
enum WindowAnimations {
    static func disable() {
        UserDefaults.standard.register(defaults: ["NSAutomaticWindowAnimationsEnabled": false])
    }
}
