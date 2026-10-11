import AppKit

/// Acts on a link in a tab's terminal, whichever engine draws it: ⌘-clicking opens it, and the right-click menu offers
/// the rest; see `TerminalContextMenu+Link`. `TerminalLinkTarget` says what a link points at.
@MainActor
struct TerminalLinkOpener {
    let host: SessionHost
    /// The tab's project folder, which a relative path is in.
    let workingDirectory: String
    /// Replaced in tests, which must not open, reveal, or copy anything.
    var openURL: (URL) -> Void = { NSWorkspace.shared.open($0) }
    var revealInFinder: (URL) -> Void = { NSWorkspace.shared.activateFileViewerSelecting([$0]) }
    var copyText: (String) -> Void = { text in
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
    var openInEditor: @MainActor (TerminalLinkLocalItem, InstalledExternalEditor) async throws -> Void = ExternalEditorFileOpener.open

    func target(of link: String) -> TerminalLinkTarget? {
        TerminalLinkTarget(link: link, host: host, workingDirectory: workingDirectory)
    }

    /// What ⌘-clicking does; see `open(_:)` for a target.
    func open(_ link: String) {
        if let target = target(of: link) { open(target) }
    }

    /// Opens a web page in the default browser, and a file or folder on this Mac in the app macOS opens its kind with,
    /// ignoring any line number, when `canOpen(_:)` allows it.
    func open(_ target: TerminalLinkTarget) {
        guard canOpen(target) else { return }
        switch target {
        case .webAddress(let url): openURL(url)
        case .localItem(let item): openURL(item.url)
        case .remotePath: break
        }
    }

    /// A path on an SSH host never opens, nor a file on this Mac that opening would run; see `LocalFileLinkSafety`.
    func canOpen(_ target: TerminalLinkTarget) -> Bool {
        switch target {
        case .webAddress: true
        case .localItem(let item): LocalFileLinkSafety.canOpen(item.url)
        case .remotePath: false
        }
    }
}
