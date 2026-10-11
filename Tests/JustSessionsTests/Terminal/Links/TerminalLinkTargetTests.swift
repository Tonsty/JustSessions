import Foundation
import Testing
@testable import JustSessions

struct TerminalLinkTargetTests {
    private let projectFolder = "/Users/me/paper"
    /// The files that exist and may open, in place of the file system.
    private let openableFiles: Set<String> = [
        "/Users/me/paper/Sources/App/main.swift",
        "/Users/me/paper/README.md",
        "/Users/me/notes.md",
        "/Users/me/Shared Notes/plan v2.md",
        "/Users/me",
    ]

    @Test(arguments: [
        "https://example.com/docs?page=2#intro",
        "http://localhost:3000",
        "HTTPS://EXAMPLE.COM",
        "mailto:someone@example.com",
    ])
    func webPagesAndEmailAddressesOpenAsGiven(_ link: String) {
        #expect(target(link, host: .thisMac) == URL(string: link))
        #expect(target(link, host: .ssh("devbox")) == URL(string: link))
    }

    @Test(arguments: [
        "ssh://devbox", "vscode://file/Users/me/paper/README.md", "x-apple.systempreferences:com.apple.preference",
        "tel:+15551234567", "magnet:?xt=urn:btih:abc", "javascript:alert(1)",
    ])
    func otherSchemesOpenNothing(_ link: String) {
        #expect(target(link, host: .thisMac) == nil)
    }

    @Test func aRelativePathIsInTheProjectFolder() {
        #expect(target("Sources/App/main.swift", host: .thisMac) == fileURL("/Users/me/paper/Sources/App/main.swift"))
        #expect(target("./README.md", host: .thisMac) == fileURL("/Users/me/paper/README.md"))
        #expect(target("../notes.md", host: .thisMac) == fileURL("/Users/me/notes.md"))
    }

    @Test(arguments: ["Sources/App/main.swift:42", "Sources/App/main.swift:42:7", "/Users/me/paper/Sources/App/main.swift:3"])
    func aLineAndColumnAfterThePathAreLeftOut(_ link: String) {
        #expect(target(link, host: .thisMac) == fileURL("/Users/me/paper/Sources/App/main.swift"))
    }

    /// `README.md:3` reads as a URL whose scheme is `README.md`.
    @Test func aFileNameWithALineNumberIsStillAPath() {
        #expect(target("README.md:3", host: .thisMac) == fileURL("/Users/me/paper/README.md"))
        #expect(target("README.md:3", host: .ssh("devbox")) == nil)
    }

    @Test func aTildeIsTheHomeFolder() {
        #expect(target("~/notes.md", host: .thisMac) == fileURL("/Users/me/notes.md"))
        #expect(target("~", host: .thisMac) == fileURL("/Users/me"))
    }

    @Test func aFileURLOpensItsFile() {
        #expect(target("file:///Users/me/Shared%20Notes/plan%20v2.md", host: .thisMac) == fileURL("/Users/me/Shared Notes/plan v2.md"))
        #expect(target("file://localhost/Users/me/notes.md", host: .thisMac) == fileURL("/Users/me/notes.md"))
    }

    @Test func aPathWithSpacesOpensAsPrinted() {
        #expect(target("/Users/me/Shared Notes/plan v2.md", host: .thisMac) == fileURL("/Users/me/Shared Notes/plan v2.md"))
    }

    @Test(arguments: ["Sources/App/missing.swift", "Sources/App/missing.swift:42", "/etc/nothing-here", "  "])
    func aFileThatCannotOpenOpensNothing(_ link: String) {
        #expect(target(link, host: .thisMac) == nil)
    }

    @Test(arguments: ["Sources/App/main.swift", "/Users/me/notes.md", "~/notes.md", "file:///Users/me/notes.md"])
    func pathsInATabOnAnSSHHostOpenNothing(_ link: String) {
        #expect(target(link, host: .ssh("devbox")) == nil)
    }

    @Test func surroundingSpacesAreLeftOut() {
        #expect(target("README.md   ", host: .thisMac) == fileURL("/Users/me/paper/README.md"))
    }

    private func target(_ link: String, host: SessionHost) -> URL? {
        TerminalLinkTarget(
            link: link,
            host: host,
            workingDirectory: projectFolder,
            homeDirectory: "/Users/me",
            canOpenLocalFile: { openableFiles.contains($0.path) }
        )?.url
    }

    private func fileURL(_ path: String) -> URL {
        URL(fileURLWithPath: path)
    }
}
