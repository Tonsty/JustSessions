import AppKit
import SwiftUI

/// The message ⌘D would bookmark now, the message being read (RDR-48), where the reader's entries laid it out, and its
/// mark beside it. Not observable: the reader sets it after every scroll update, and a SwiftUI view following it cost 2 ms
/// a scroll step at 240 entries and 5 at 640 (performance.md item 34), so it moves the mark's AppKit view itself.
@MainActor
final class TranscriptBookmarkTarget {
    struct Shown: Equatable {
        let entryID: Int
        /// The entry's row in the entries' layout (`TranscriptScrollPositionController.entryFrameInStack(at:)`).
        let frame: CGRect
        /// The space above the message in its row (`TranscriptEntryView.topPadding(startsTurn:)`).
        let topPadding: CGFloat
    }

    private(set) var shown: Shown?
    weak var marks: TranscriptBookmarkTargetMarksView? {
        didSet { marks?.show(shown) }
    }

    /// Moves the mark only when the target changes, so scrolling within one message does nothing.
    func show(_ shown: Shown?) {
        guard self.shown != shown else { return }
        self.shown = shown
        marks?.show(shown)
    }
}

/// The gutter left of the entries, where the mark of the message ⌘D would bookmark goes (RDR-48). Its `updateNSView` runs
/// only when the theme or the bookmarks change; the target moves the mark without SwiftUI.
struct TranscriptBookmarkTargetMarks: NSViewRepresentable {
    let target: TranscriptBookmarkTarget
    /// The reader's padding left of the entries (`TranscriptScrollView`), which the letters sit in.
    static let gutterWidth: CGFloat = 24

    func makeNSView(context: Context) -> TranscriptBookmarkTargetMarksView {
        TranscriptBookmarkTargetMarksView()
    }

    func updateNSView(_ view: TranscriptBookmarkTargetMarksView, context: Context) {
        view.style = TranscriptBookmarkTargetMarkView.Style(
            color: NSColor(Color(ThemePalette.secondaryText.resolve(in: context.environment))),
            letters: context.environment.transcriptBookmarkLetters,
            side: TranscriptBookmarkMarker.side
        )
        if target.marks !== view { target.marks = view }
    }
}

/// Spans the gutter column the height of the entries and draws nothing itself, so it has no backing store to fill.
final class TranscriptBookmarkTargetMarksView: NSView {
    private let mark = TranscriptBookmarkTargetMarkView()
    private var shown: TranscriptBookmarkTarget.Shown?

    var style: TranscriptBookmarkTargetMarkView.Style? {
        didSet {
            guard style != oldValue else { return }
            show(shown)
        }
    }

    override var isFlipped: Bool { true }

    init() {
        super.init(frame: .zero)
        mark.isHidden = true
        addSubview(mark)
    }

    required init?(coder: NSCoder) { nil }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func isAccessibilityElement() -> Bool { false }

    /// Puts the mark at the message's first line, in the letter's slot, and as tall as the message.
    func show(_ shown: TranscriptBookmarkTarget.Shown?) {
        self.shown = shown
        guard let shown, let style else {
            mark.isHidden = true
            return
        }
        let slotX = TranscriptBookmarkTargetMarks.gutterWidth - style.side - TranscriptBookmarkMarker.gapToText
        let top = shown.frame.minY + shown.topPadding
        let frame = CGRect(x: slotX, y: top, width: style.side, height: max(style.side, shown.frame.maxY - 4 - top))
        let content = TranscriptBookmarkTargetMarkView.Content(style: style, hasLetter: style.letters.letter(forEntryID: shown.entryID) != nil)
        if mark.frame != frame { mark.frame = frame }
        if mark.content != content {
            mark.content = content
            mark.needsDisplay = true
        }
        mark.isHidden = false
    }
}

/// The mark itself: a ring around the letter's slot, an outline bookmark in it while the message has none, and a line down
/// the slot's column for the rest of the message, so its whole extent shows. Off the text, so no text's contrast changes;
/// the secondary text color keeps 3:1 on the reader's surface.
final class TranscriptBookmarkTargetMarkView: NSView {
    struct Style: Equatable {
        let color: NSColor
        let letters: TranscriptBookmarkLetters
        let side: CGFloat
    }

    struct Content: Equatable {
        let style: Style
        let hasLetter: Bool
    }

    static let ringWidth: CGFloat = 1.5
    static let lineWidth: CGFloat = 2
    var content: Content?

    override var isFlipped: Bool { true }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
    override func isAccessibilityElement() -> Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let content else { return }
        let side = content.style.side
        content.style.color.set()
        let slot = CGRect(x: 0, y: 0, width: side, height: side)
        let ring = NSBezierPath(roundedRect: slot.insetBy(dx: Self.ringWidth / 2, dy: Self.ringWidth / 2),
                                xRadius: ThemeCornerRadius.small.rawValue, yRadius: ThemeCornerRadius.small.rawValue)
        ring.lineWidth = Self.ringWidth
        ring.stroke()
        if !content.hasLetter { Self.bookmarkOutline(in: slot.insetBy(dx: side * 0.3, dy: side * 0.22)).stroke() }
        let lineTop = side + 3
        if bounds.height - lineTop > 4 {
            NSBezierPath(roundedRect: CGRect(x: side / 2 - Self.lineWidth / 2, y: lineTop, width: Self.lineWidth, height: bounds.height - lineTop),
                         xRadius: Self.lineWidth / 2, yRadius: Self.lineWidth / 2).fill()
        }
    }

    /// A bookmark ribbon's outline, a rectangle with a notch cut up into its bottom edge, in flipped coordinates.
    static func bookmarkOutline(in rect: CGRect) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.line(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.line(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.line(to: CGPoint(x: rect.midX, y: rect.maxY - rect.width * 0.4))
        path.line(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.close()
        path.lineWidth = 1.2
        path.lineJoinStyle = .round
        return path
    }
}
