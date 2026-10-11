import AppKit
import Testing
@testable import JustSessions

/// A tab opens the links its terminal hands over, with its own host and project folder.
@MainActor
struct TerminalTabLinkOpeningTests {
    @Test(arguments: TerminalEngine.allCases)
    func aTabOnThisMacOpensAPathInItsProjectFolder(_ engine: TerminalEngine) throws {
        let projectFolder = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: projectFolder) }
        try Data("# Plan\n".utf8).write(to: projectFolder.appendingPathComponent("plan.md"))
        let tab = makeTab(engine: engine, host: .thisMac, projectPath: projectFolder.path)
        var openedURLs: [URL] = []
        tab.linkOpener.openURL = { openedURLs.append($0) }

        tab.terminalView.onOpenLink?("plan.md:12")
        tab.terminalView.onOpenLink?("https://example.com/docs")

        #expect(openedURLs == [projectFolder.appendingPathComponent("plan.md"), URL(string: "https://example.com/docs")!])
    }

    @Test(arguments: TerminalEngine.allCases)
    func aTabOnAnSSHHostOpensWebPagesButNoPaths(_ engine: TerminalEngine) throws {
        let projectFolder = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: projectFolder) }
        try Data("# Plan\n".utf8).write(to: projectFolder.appendingPathComponent("plan.md"))
        let tab = makeTab(engine: engine, host: .ssh("devbox"), projectPath: projectFolder.path)
        var openedURLs: [URL] = []
        tab.linkOpener.openURL = { openedURLs.append($0) }

        tab.terminalView.onOpenLink?("plan.md")
        tab.terminalView.onOpenLink?(projectFolder.appendingPathComponent("plan.md").path)
        tab.terminalView.onOpenLink?("https://example.com/docs")

        #expect(openedURLs == [URL(string: "https://example.com/docs")!])
    }

    private func makeTab(engine: TerminalEngine, host: SessionHost, projectPath: String) -> TerminalSession {
        TerminalSession(
            engine: engine,
            conversation: nil,
            provider: .claude,
            projectPath: projectPath,
            action: nil,
            displayTitle: "Tab",
            command: NativeCLICommand(executablePath: "/usr/bin/true", arguments: [], workingDirectory: projectPath, environment: []),
            host: host
        )
    }
}
