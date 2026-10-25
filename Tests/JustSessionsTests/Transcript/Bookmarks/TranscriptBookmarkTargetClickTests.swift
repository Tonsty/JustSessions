import AppKit
import Testing
@testable import JustSessions

/// The mark beside the message ⌘D would bookmark (RDR-48): its outline bookmark takes a click while the message has no
/// letter; a letter, and the rest of the gutter, let clicks through to what is under them. Points are in the marks view's
/// parent's coordinates, as AppKit passes them going down the view tree.
@MainActor
struct TranscriptBookmarkTargetClickTests {
    private static func marks(letters: [MessageBookmark]) -> (container: NSView, marks: TranscriptBookmarkTargetMarksView) {
        let container = FlippedView(frame: NSRect(x: 0, y: 0, width: 400, height: 600))
        let marks = TranscriptBookmarkTargetMarksView()
        marks.frame = NSRect(x: 0, y: 0, width: TranscriptBookmarkTargetMarks.gutterWidth, height: 600)
        container.addSubview(marks)
        marks.style = TranscriptBookmarkTargetMarkView.Style(color: .secondaryLabelColor, letters: TranscriptBookmarkLetters(letters), side: 16)
        marks.show(TranscriptBookmarkTarget.Shown(entryID: 4, frame: CGRect(x: 0, y: 100, width: 300, height: 120), topPadding: 12))
        return (container, marks)
    }

    private final class FlippedView: NSView {
        override var isFlipped: Bool { true }
    }

    /// The slot is 16 points square at x 4 (24 - 16 - 4), from the message's first line at y 112.
    @Test func theOutlineBookmarkOfAMessageWithoutOneTakesTheClick() {
        let (_, marks) = Self.marks(letters: [])

        let hit = marks.hitTest(NSPoint(x: 12, y: 118))

        #expect(hit is TranscriptBookmarkTargetMarkView)
        #expect(hit?.isAccessibilityElement() == true)
        #expect(hit?.accessibilityRole() == .button)
        #expect(marks.hitTest(NSPoint(x: 12, y: 160)) == nil)   // the line down the rest of the message
        #expect(marks.hitTest(NSPoint(x: 12, y: 60)) == nil)
    }

    @Test func aMessageWithALetterLetsTheClickThroughToIt() {
        let bookmark = MessageBookmark(letter: "a", entryID: 4, kind: .assistant, snippet: "")
        let (_, marks) = Self.marks(letters: [bookmark])

        #expect(marks.hitTest(NSPoint(x: 12, y: 118)) == nil)
    }

    @Test func noTargetTakesNothing() {
        let (_, marks) = Self.marks(letters: [])
        marks.show(nil)

        #expect(marks.hitTest(NSPoint(x: 12, y: 118)) == nil)
    }
}
