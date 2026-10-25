import SwiftUI

/// Lays out a Markdown table's cells in the reader (RDR-04), as a browser lays out a table: each column as wide as its
/// widest cell while the table fits `availableWidth`; otherwise the widest columns give up width first, down to
/// `minimumColumnWidth` or, when wider, the column's longest word (`minimumWidths`), and their cells wrap. Each row is as tall as its tallest cell at its column's width, measured at
/// that width, so a wrapped cell never runs into the row below. A table whose columns can't fit even then is wider than
/// `availableWidth`, and its scroll view scrolls sideways.
///
/// The cells come row by row, `rowCellCounts` of them in each row; a short row leaves its last columns empty.
struct TranscriptMarkdownTableLayout: Layout {
    static let minimumColumnWidth: CGFloat = 120
    /// A word wider than this, such as a URL or a hash, may break rather than widen its column further.
    static let maximumWordWidth: CGFloat = 240

    let rowCellCounts: [Int]
    let availableWidth: CGFloat
    /// Each column's longest word with its cell's padding, below which its cells would break a word.
    var minimumWidths: [CGFloat] = []

    struct Cache {
        var columnWidths: [CGFloat] = []
        var rowHeights: [CGFloat] = []
        var isMeasured = false
    }

    func makeCache(subviews: Subviews) -> Cache { Cache() }

    func updateCache(_ cache: inout Cache, subviews: Subviews) { cache = Cache() }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        measure(subviews, into: &cache)
        return CGSize(width: cache.columnWidths.reduce(0, +), height: cache.rowHeights.reduce(0, +))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        measure(subviews, into: &cache)
        var index = 0
        var y = bounds.minY
        for (row, count) in rowCellCounts.enumerated() {
            var x = bounds.minX
            for column in 0..<count where index < subviews.count {
                let size = CGSize(width: cache.columnWidths[column], height: cache.rowHeights[row])
                subviews[index].place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(size))
                x += size.width
                index += 1
            }
            y += cache.rowHeights[row]
        }
    }

    /// Each cell is measured twice at most, at its ideal width and at its column's, and the text view keeps each.
    private func measure(_ subviews: Subviews, into cache: inout Cache) {
        guard !cache.isMeasured else { return }
        let columnCount = rowCellCounts.max() ?? 0
        var idealWidths = [CGFloat](repeating: 0, count: columnCount)
        var index = 0
        for count in rowCellCounts {
            for column in 0..<count where index < subviews.count {
                idealWidths[column] = max(idealWidths[column], subviews[index].sizeThatFits(.unspecified).width)
                index += 1
            }
        }
        let minimums = idealWidths.indices.map { column in
            max(Self.minimumColumnWidth, min(Self.maximumWordWidth, column < minimumWidths.count ? minimumWidths[column] : 0))
        }
        let columnWidths = Self.columnWidths(idealWidths: idealWidths, minimumWidths: minimums, availableWidth: availableWidth)
        var rowHeights: [CGFloat] = []
        index = 0
        for count in rowCellCounts {
            var height: CGFloat = 0
            for column in 0..<count where index < subviews.count {
                height = max(height, subviews[index].sizeThatFits(ProposedViewSize(width: columnWidths[column], height: nil)).height)
                index += 1
            }
            rowHeights.append(height)
        }
        cache = Cache(columnWidths: columnWidths, rowHeights: rowHeights, isMeasured: true)
    }

    /// The ideal widths while they fit; otherwise the widest are cut to one shared width, as water fills, so the columns
    /// fill `availableWidth`, none cut below its minimum or narrower than it was. When even the minimums don't fit,
    /// those. Whole points.
    static func columnWidths(idealWidths: [CGFloat], minimumWidths: [CGFloat], availableWidth: CGFloat) -> [CGFloat] {
        let ideal = idealWidths.map { $0.rounded(.up) }
        guard ideal.reduce(0, +) > availableWidth else { return ideal }
        let lowest = ideal.indices.map { min(ideal[$0], ($0 < minimumWidths.count ? minimumWidths[$0] : 0).rounded(.up)) }
        guard lowest.reduce(0, +) < availableWidth else { return lowest }
        func widths(cappedAt cap: CGFloat) -> [CGFloat] { ideal.indices.map { max(lowest[$0], min(ideal[$0], cap)) } }
        // The total grows with the cap, so the cap that fills the width is found by halving.
        var low: CGFloat = 0
        var high = ideal.max() ?? 0
        for _ in 0..<48 {
            let middle = (low + high) / 2
            if widths(cappedAt: middle).reduce(0, +) > availableWidth { high = middle } else { low = middle }
        }
        let roundedUp = widths(cappedAt: low.rounded(.up))
        return roundedUp.reduce(0, +) <= availableWidth ? roundedUp : widths(cappedAt: low.rounded(.down))
    }
}
