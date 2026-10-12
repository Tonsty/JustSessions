import Foundation

/// How a block's text joins its neighbors when a selection across blocks is copied.
enum TranscriptTextCopyRole: Hashable {
    /// Prose, a heading, a code block, or a whole message: a blank line apart from its neighbors.
    case paragraph
    /// A list item: it keeps its marker, such as "•" or "2.", and follows the item before it on the next line.
    case listItem(marker: String)
    /// A table cell: a tab apart from the cells beside it, and on the next line after the row above it.
    case tableCell(row: Int)
    /// One of a run's tool call summaries, one per line.
    case line
}

/// Joins the selected parts of several text blocks into the plain text that Copy puts on the pasteboard.
enum TranscriptTextSelectionCopy {
    struct Piece: Equatable {
        let key: TranscriptTextSelectionKey
        let role: TranscriptTextCopyRole
        let text: String
        /// Whether the piece starts at the start of its block, so a list item's marker belongs before it.
        let startsAtBlockStart: Bool
    }

    static func text(of pieces: [Piece]) -> String {
        var text = ""
        var previousPiece: Piece?
        for piece in pieces where !piece.text.isEmpty {
            if let previousPiece {
                // A code block's text ends with its last line's break, which the separator already adds.
                while text.hasSuffix("\n") { text.removeLast() }
                text += separator(between: previousPiece, and: piece)
            }
            if piece.startsAtBlockStart, case .listItem(let marker) = piece.role { text += marker + " " }
            text += piece.text
            previousPiece = piece
        }
        return text
    }

    private static func separator(between previousPiece: Piece, and piece: Piece) -> String {
        guard previousPiece.key.entryIndex == piece.key.entryIndex else { return "\n\n" }
        switch (previousPiece.role, piece.role) {
        case (.tableCell(let previousRow), .tableCell(let row)): return previousRow == row ? "\t" : "\n"
        case (.listItem, .listItem), (.line, .line): return "\n"
        default: return "\n\n"
        }
    }
}
