import Foundation

/// Where a text block sits in the reader: its entry, then its place among that entry's text blocks, numbered as Find
/// numbers them (`TranscriptSearchSegments`). Entry IDs rise through a session, so keys sort in reading order.
struct TranscriptTextSelectionKey: Hashable, Comparable {
    let entryIndex: Int
    let segmentIndex: Int

    static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.entryIndex, lhs.segmentIndex) < (rhs.entryIndex, rhs.segmentIndex)
    }
}

/// A place between two characters of one text block, counted in UTF-16 units as `NSTextView` counts them.
struct TranscriptTextSelectionPosition: Hashable, Comparable {
    let key: TranscriptTextSelectionKey
    let offset: Int

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.key == rhs.key ? lhs.offset < rhs.offset : lhs.key < rhs.key
    }
}

/// A selection that can run across text blocks, from where it started to where it was extended. It names blocks by
/// their keys rather than by their views, so a block that loads again, or redraws with new text, takes its part back.
struct TranscriptTextSelection: Equatable {
    var anchor: TranscriptTextSelectionPosition
    var focus: TranscriptTextSelectionPosition

    var start: TranscriptTextSelectionPosition { min(anchor, focus) }
    var end: TranscriptTextSelectionPosition { max(anchor, focus) }
    var spansSeveralBlocks: Bool { anchor.key != focus.key }

    /// The part of the block with `key` and `length` characters that the selection covers. It is empty, at the start of
    /// the block, for a block outside the selection.
    func range(in key: TranscriptTextSelectionKey, length: Int) -> NSRange {
        let start = start
        let end = end
        guard start.key <= key, key <= end.key else { return NSRange(location: 0, length: 0) }
        let lowerBound = key == start.key ? min(max(0, start.offset), length) : 0
        let upperBound = key == end.key ? min(max(0, end.offset), length) : length
        return NSRange(location: lowerBound, length: max(0, upperBound - lowerBound))
    }
}
