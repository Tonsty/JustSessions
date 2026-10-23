import AppKit
import SwiftUI

/// Tells `TranscriptBookmarkTargetRegistry` which reader a window shows and whether it is visible.
struct TranscriptBookmarkTargetReporter: NSViewRepresentable {
    let target: TranscriptBookmarkCommandTarget?
    let isActive: Bool

    func makeNSView(context: Context) -> TranscriptBookmarkTargetReportingView { TranscriptBookmarkTargetReportingView() }

    func updateNSView(_ view: TranscriptBookmarkTargetReportingView, context: Context) {
        view.target = target
        view.isActive = isActive
    }
}

final class TranscriptBookmarkTargetReportingView: NSView {
    var target: TranscriptBookmarkCommandTarget?
    var isActive = false
    var registry = TranscriptBookmarkTargetRegistry.shared

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil { registry.register(self) }
    }

    /// Clicks go to the reader.
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
