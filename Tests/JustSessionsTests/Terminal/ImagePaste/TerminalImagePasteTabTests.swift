import AppKit
import Carbon.HIToolbox
import Foundation
import Testing
@testable import JustSessions

/// An image pasted on a tab, from ⌘V or the menu's Paste to what the tab's CLI receives. Each tab reads a pasteboard of
/// its own in place of the clipboard, and its process records what it is sent.
@MainActor
struct TerminalImagePasteTabTests {
    enum Trigger: CaseIterable {
        case menuPaste
        case commandV
    }

    /// SwiftTerm's ⌘V goes through the Edit menu to the same `paste(_:)` as the menu's, which a test can't send it.
    @Test(arguments: [
        (TerminalEngine.swiftTerm, Trigger.menuPaste), (TerminalEngine.ghostty, Trigger.menuPaste),
        (TerminalEngine.ghostty, Trigger.commandV),
    ])
    func onAnSSHHostTheImageIsCopiedThereAndTheCLIGetsItsPath(_ engine: TerminalEngine, _ trigger: Trigger) async throws {
        let folder = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: folder) }
        let hostHome = folder.appendingPathComponent("host-home")
        try FileManager.default.createDirectory(at: hostHome, withIntermediateDirectories: true)
        let receivedInput = folder.appendingPathComponent("received-input")
        let tab = TerminalSession(
            engine: engine,
            conversation: nil,
            provider: .claude,
            projectPath: "/home/me/project",
            action: nil,
            displayTitle: "Tab",
            command: NativeCLICommand(
                executablePath: "/bin/sh",
                arguments: ["-c", "stty raw -echo; exec cat > \"$RECEIVED_INPUT\""],
                workingDirectory: folder.path,
                environment: ["RECEIVED_INPUT=\(receivedInput.path)", "PATH=/usr/bin:/bin", "TERM=xterm-256color"]
            ),
            host: .ssh("devbox")
        )
        // Ghostty takes a paste only in a window.
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600), styleMask: [.titled], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = tab.terminalView
        window.makeFirstResponder(tab.terminalView)
        let png = makePNGData()
        let pasteboard = NSPasteboard.holding([.png: png])
        defer {
            tab.close()
            window.close()
            pasteboard.releaseGlobally()
        }
        tab.terminalView.imagePaste.pasteboard = pasteboard
        let fileDrop = try #require(tab.sshFileDrop)
        fileDrop.copier = .local(home: hostHome)
        fileDrop.connectionSharing = { _ in nil }
        fileDrop.pastedImagesFolder = folder.appendingPathComponent("pasted images")
        tab.startIfNeeded()
        try await expectEventually { FileManager.default.fileExists(atPath: receivedInput.path) }

        switch trigger {
        case .menuPaste:
            tab.terminalView.paste(tab.terminalView)
        case .commandV:
            #expect(tab.terminalView.performKeyEquivalent(with: commandV(in: window)))
        }

        let received = { String(decoding: (try? Data(contentsOf: receivedInput)) ?? Data(), as: UTF8.self) }
        try await expectEventually { received().hasSuffix(" ") }
        let droppedFiles = hostHome.appendingPathComponent(RemoteDroppedFileCopyScript.droppedFilesFolder)
        let copies = try FileManager.default.contentsOfDirectory(atPath: droppedFiles.path)
        try #require(copies.count == 1)
        let hostPath = droppedFiles.appendingPathComponent(copies[0]).appendingPathComponent("pasted-image.png").path
        #expect(received() == TerminalFileDropPaste.escapedPath(hostPath) + " ")
        #expect(try Data(contentsOf: URL(fileURLWithPath: hostPath)) == png)
        #expect(try FileManager.default.contentsOfDirectory(atPath: fileDrop.pastedImagesFolder.path).isEmpty)
    }

    /// Ghostty drops an empty paste, so the tab sends the one Claude Code answers by reading the clipboard itself.
    @Test(arguments: Trigger.allCases)
    func onThisMacAGhosttyTabSendsAnEmptyBracketedPaste(_ trigger: Trigger) async throws {
        let fixture = try GhosttyTabFixture()
        let pasteboard = NSPasteboard.holding([.png: makePNGData()])
        defer {
            fixture.tearDown()
            pasteboard.releaseGlobally()
        }
        fixture.view.imagePaste.pasteboard = pasteboard
        try await fixture.start(printing: "printf '\\033[?2004h'")
        try await expectEventually { fixture.view.isBracketedPasteOn }

        paste(trigger, in: fixture)

        try await expectEventually { !fixture.receivedInput.isEmpty }
        #expect(fixture.receivedInput == "\u{1B}[200~\u{1B}[201~")
    }

    /// As SwiftTerm does, nothing goes to a program that didn't turn bracketed paste on, where the markers would be
    /// typed as text.
    @Test func onThisMacAGhosttyTabSendsNothingWithoutBracketedPaste() async throws {
        let fixture = try GhosttyTabFixture()
        let pasteboard = NSPasteboard.holding([.png: makePNGData()])
        defer {
            fixture.tearDown()
            pasteboard.releaseGlobally()
        }
        fixture.view.imagePaste.pasteboard = pasteboard
        try await fixture.start(printing: "printf '\\033[?2004h\\033[?2004l'; touch printed")
        try await expectEventually { FileManager.default.fileExists(atPath: fixture.folder.appendingPathComponent("printed").path) }
        try await Task.sleep(for: .milliseconds(200))

        #expect(fixture.view.performKeyEquivalent(with: commandV(in: fixture.window)))
        fixture.view.sendAsTyped("x")

        try await expectEventually { !fixture.receivedInput.isEmpty }
        #expect(fixture.receivedInput == "x")
    }

    /// Text on the clipboard, an image's beside it included, is Ghostty's own paste.
    @Test func aClipboardWithTextIsLeftToTheEngine() throws {
        let fixture = try GhosttyTabFixture()
        let pasteboard = NSPasteboard.holding([.png: makePNGData(), .string: Data("shot.png".utf8)])
        defer {
            fixture.tearDown()
            pasteboard.releaseGlobally()
        }
        fixture.view.imagePaste.pasteboard = pasteboard

        #expect(!fixture.view.pastesClipboardImage())
        #expect(fixture.view.imagePaste.handleClipboardImage() == nil)
    }

    private func paste(_ trigger: Trigger, in fixture: GhosttyTabFixture) {
        switch trigger {
        case .menuPaste:
            fixture.view.paste(fixture.view)
        case .commandV:
            #expect(fixture.view.performKeyEquivalent(with: commandV(in: fixture.window)))
        }
    }

    private func commandV(in window: NSWindow) -> NSEvent {
        SyntheticKey.event(keyCode: kVK_ANSI_V, characters: "v", modifiers: .command, window: window)
    }
}
