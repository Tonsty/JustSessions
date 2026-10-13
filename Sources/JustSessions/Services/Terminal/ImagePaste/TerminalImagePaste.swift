import AppKit

/// ⌘V or a menu's Paste in a tab with only an image on the clipboard (`TerminalClipboardImage`).
///
/// A CLI on this Mac reads the image off the clipboard itself once it gets an empty paste, as Claude Code does. A
/// SwiftTerm tab's own paste sends one; a Ghostty tab sends it itself, since Ghostty drops an empty paste
/// (`GhosttyTabTerminalView+ImagePaste`). A CLI on an SSH host can't read this Mac's clipboard, so a tab there copies
/// the image to the host and types its path there, as for a dropped file; see `TerminalSSHFileDrop`.
@MainActor
final class TerminalImagePaste {
    enum Handling: Equatable {
        /// Send an empty paste, which a CLI on this Mac answers by reading the image off the clipboard.
        case sendEmptyPaste
        /// Send nothing now: the tab copies the image to its SSH host, or takes nothing once its CLI has ended.
        case sendNothing
    }

    /// The clipboard; a test replaces it with a pasteboard of its own.
    var pasteboard = NSPasteboard.general
    /// Set for a tab on an SSH host: takes the image to copy there, unless the tab's CLI has ended.
    var copyToHost: ((TerminalClipboardImage) -> Void)?

    var clipboardHoldsOnlyAnImage: Bool { TerminalClipboardImage.isOnly(on: pasteboard) }

    /// What the tab sends for a Paste, or nil when the clipboard holds text or no image, for the engine's own paste.
    func handleClipboardImage() -> Handling? {
        guard clipboardHoldsOnlyAnImage else { return nil }
        guard let copyToHost else { return .sendEmptyPaste }
        if let image = TerminalClipboardImage(pasteboard: pasteboard) { copyToHost(image) }
        return .sendNothing
    }
}
