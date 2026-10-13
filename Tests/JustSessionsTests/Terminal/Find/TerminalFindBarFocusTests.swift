import AppKit
import SwiftUI
import Testing
@testable import JustSessions

/// Who has the keyboard as a tab's find bar opens and closes, with the tab's view in a window as the app shows it.
/// A selected tab's terminal takes the keyboard a moment after it appears, so tests wait for that before opening the
/// bar, as a person would.
@MainActor
@Suite(.serialized)
struct TerminalFindBarFocusTests {
    @MainActor
    private final class Fixture {
        let window: NSWindow
        let tab: TerminalSession
        var focusCount = 0

        init(isActive: Bool = true) {
            _ = NSApplication.shared
            tab = TerminalSession(
                engine: .swiftTerm,
                conversation: nil,
                provider: nil,
                projectPath: "/tmp/terminal-find",
                action: nil,
                displayTitle: "Find focus",
                command: NativeCLICommand(executablePath: "/bin/cat", arguments: [], workingDirectory: "/tmp", environment: [])
            )
            window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 700, height: 400), styleMask: [.titled], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentView = NSHostingView(rootView: TerminalWorkspaceView(
                session: tab,
                isShown: true,
                isActive: isActive,
                onReconnect: nil,
                onCheckHost: nil,
                onFocus: { [unowned self] in focusCount += 1 },
                makeContextMenu: { _ in NSMenu() },
                onOpenLink: { _ in }
            ))
            window.makeKeyAndOrderFront(nil)
        }

        var findFieldHasTheKeyboard: Bool {
            guard let fieldEditor = window.firstResponder as? NSTextView,
                  let field = fieldEditor.delegate as? NSTextField else { return false }
            return field.isDescendant(of: window.contentView!)
        }

        var terminalHasTheKeyboard: Bool { window.firstResponder === tab.terminalView }

        func tearDown() {
            tab.close()
            window.close()
        }
    }

    @Test func showingTheBarGivesItsFieldTheKeyboardAndClosingGivesItBack() async throws {
        let fixture = Fixture()
        defer { fixture.tearDown() }
        try await expectEventually { fixture.terminalHasTheKeyboard }

        fixture.tab.findState.show()

        try await expectEventually { fixture.findFieldHasTheKeyboard && fixture.tab.findState.isFieldFocused }

        fixture.tab.findState.close()

        try await expectEventually { fixture.terminalHasTheKeyboard }
        #expect(!fixture.tab.findState.isFieldFocused)
    }

    /// ⌘F with the bar open but the terminal typing puts the keyboard back in the field.
    @Test func showingTheOpenBarAgainTakesTheKeyboardBack() async throws {
        let fixture = Fixture()
        defer { fixture.tearDown() }
        try await expectEventually { fixture.terminalHasTheKeyboard }
        fixture.tab.findState.show()
        try await expectEventually { fixture.findFieldHasTheKeyboard }
        fixture.window.makeFirstResponder(fixture.tab.terminalView)
        try await expectEventually { !fixture.tab.findState.isFieldFocused }

        fixture.tab.findState.show()

        try await expectEventually { fixture.findFieldHasTheKeyboard && fixture.tab.findState.isFieldFocused }
    }

    /// In a split, the field of the pane that is not selected selects its tab when it takes the keyboard.
    @Test func theFieldOfAPaneNotSelectedSelectsItsTab() async throws {
        let fixture = Fixture(isActive: false)
        defer { fixture.tearDown() }

        fixture.tab.findState.show()

        try await expectEventually { fixture.findFieldHasTheKeyboard }
        try await expectEventually { fixture.focusCount == 1 }
    }
}
