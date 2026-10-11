import AppKit

/// Opens a link ⌘-clicked in a tab's terminal, whichever engine draws it; see `TerminalLinkTarget` for what opens.
/// A web page opens in the default browser and a file in the app macOS opens its kind with, ignoring any line number.
@MainActor
struct TerminalLinkOpener {
    let host: SessionHost
    /// The tab's project folder, which a relative path is in.
    let workingDirectory: String
    /// Replaced in tests, which must not open anything.
    var openURL: (URL) -> Void = { NSWorkspace.shared.open($0) }

    func open(_ link: String) {
        guard let target = TerminalLinkTarget(link: link, host: host, workingDirectory: workingDirectory) else { return }
        openURL(target.url)
    }
}
