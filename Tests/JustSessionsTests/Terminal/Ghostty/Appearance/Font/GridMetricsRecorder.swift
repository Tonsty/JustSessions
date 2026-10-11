import GhosttyTerminal

/// Keeps the grid size a Ghostty terminal reports, cells included, as a view's delegate.
@MainActor
final class GridMetricsRecorder: TerminalSurfaceGridResizeDelegate {
    private(set) var metrics: TerminalGridMetrics?

    func terminalDidResize(_ size: TerminalGridMetrics) {
        metrics = size
    }
}
