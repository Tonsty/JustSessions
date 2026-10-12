import AppKit

/// How one transcript text block is set. Conversation text follows the reading text size; code, headings, tool
/// summaries, and notes derive their own sizes from it or use a fixed size.
struct TranscriptTextStyle: Equatable {
    var fontSize: CGFloat
    var isMonospaced = false
    var isSemibold = false
    var lineSpacing: CGFloat = 4
    var tone: TranscriptTextTone = .primary

    var font: NSFont {
        let weight: NSFont.Weight = isSemibold ? .semibold : .regular
        return isMonospaced ? .monospacedSystemFont(ofSize: fontSize, weight: weight) : .systemFont(ofSize: fontSize, weight: weight)
    }
}

/// Which of the reader's text colors a block is drawn in.
enum TranscriptTextTone: Equatable {
    /// Messages, which SwiftUI drew in its default primary color before the reader drew text with AppKit.
    case primary
    /// Tool call summaries.
    case secondary
    /// Notes, such as a compaction.
    case tertiary
}
