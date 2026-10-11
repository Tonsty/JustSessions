import AppKit
import QuartzCore
import SwiftUI

/// A small green arc that turns while a CLI works. With Reduce Motion on it holds still; its open shape still sets
/// it apart from the dot of a CLI that is not working.
///
/// The arc is a Core Animation layer turned by the render server, not a SwiftUI animation: a `TimelineView` ticking
/// 30 times a second made the window's whole hosting view re-render on every tick, about a quarter of the main
/// thread's time at idle with one CLI working; see item 19 in docs/development/performance.md.
struct WorkingSpinner: View {
    static let secondsPerTurn = 0.9

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        WorkingSpinnerArc(turns: !reduceMotion)
            .frame(width: 8, height: 8)
    }
}

/// The arc as an AppKit view, so its turning costs the SwiftUI view graph nothing.
private struct WorkingSpinnerArc: NSViewRepresentable {
    let turns: Bool

    func makeNSView(context: Context) -> WorkingSpinnerArcView {
        WorkingSpinnerArcView()
    }

    func updateNSView(_ view: WorkingSpinnerArcView, context: Context) {
        view.turns = turns
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: WorkingSpinnerArcView, context: Context) -> CGSize? {
        CGSize(width: 8, height: 8)
    }
}

/// A layer-backed view whose shape layer draws the arc, in the live status color of the view's appearance, and
/// turns it with a repeating rotation that runs only while the view is in a window and `turns` is set.
final class WorkingSpinnerArcView: NSView {
    private static let rotationKey = "turn"
    private static let liveColor = NSColor.adaptive(
        light: NSColor(hexValue: StatusHexColors.live.light),
        dark: NSColor(hexValue: StatusHexColors.live.dark)
    )

    var turns = true {
        didSet { if turns != oldValue { updateRotation() } }
    }

    private let arcLayer = CAShapeLayer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        // The arc stays where SwiftUI puts the view; only the shape layer turns.
        layer?.addSublayer(arcLayer)
        arcLayer.fillColor = nil
        arcLayer.lineWidth = 1.6
        arcLayer.lineCap = .round
        arcLayer.strokeStart = 0
        arcLayer.strokeEnd = 0.72
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override var isFlipped: Bool { true }

    override func layout() {
        super.layout()
        let side = min(bounds.width, bounds.height)
        let frame = CGRect(x: (bounds.width - side) / 2, y: (bounds.height - side) / 2, width: side, height: side)
        arcLayer.frame = frame
        // The stroke is centered on the view's edge, as SwiftUI strokes a `Circle` filling the view; the layer does not
        // clip, so the outer half of the stroke draws past the frame as it did.
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(origin: .zero, size: frame.size))
        arcLayer.path = path
        updateStrokeColor()
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateStrokeColor()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        updateRotation()
    }

    override func viewDidUnhide() {
        super.viewDidUnhide()
        updateRotation()
    }

    private func updateStrokeColor() {
        effectiveAppearance.performAsCurrentDrawingAppearance {
            arcLayer.strokeColor = Self.liveColor.cgColor
        }
    }

    /// Turns while in a window and asked to; otherwise stops, so no hidden spinner keeps the render server busy.
    private func updateRotation() {
        let shouldTurn = turns && window != nil && !isHiddenOrHasHiddenAncestor
        if shouldTurn {
            guard arcLayer.animation(forKey: Self.rotationKey) == nil else { return }
            let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
            rotation.fromValue = 0
            rotation.toValue = 2 * Double.pi
            rotation.duration = WorkingSpinner.secondsPerTurn
            rotation.repeatCount = .infinity
            rotation.isRemovedOnCompletion = false
            arcLayer.add(rotation, forKey: Self.rotationKey)
        } else {
            arcLayer.removeAnimation(forKey: Self.rotationKey)
        }
    }
}
