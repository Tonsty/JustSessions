import CoreGraphics

/// Where the conversation map draws an outline in its column (TAB-10): fit to height, so every row and bookmark stays
/// in view without scrolling, and a pure function of the outline and the column's size.
struct ConversationMapLayout: Equatable {
    enum Ink: Int, CaseIterable, Comparable {
        /// Fill order, and strength when rows share a pixel row.
        case toolRun, assistant, user

        init(_ kind: ConversationOutline.Block.Kind) {
            switch kind {
            case .user, .image: self = .user
            case .assistant: self = .assistant
            case .toolRun: self = .toolRun
            }
        }

        static func < (first: Self, second: Self) -> Bool { first.rawValue < second.rawValue }
    }

    struct Bar: Equatable {
        let minY: CGFloat
        let height: CGFloat
        let widthFraction: CGFloat
        let ink: Ink
    }

    struct Chip: Equatable {
        let letter: String
        /// The first row of the bookmarked message, where its tick goes.
        let rowY: CGFloat
        let chipY: CGFloat
    }

    let pitch: CGFloat
    let top: CGFloat
    let rowCount: Int

    /// Fit to height: the natural pitch while every row fits, never stretched; squeezed otherwise.
    init(rowCount: Int, height: CGFloat, naturalPitch: CGFloat, verticalInset: CGFloat) {
        self.rowCount = rowCount
        top = verticalInset
        let available = max(0, height - 2 * verticalInset)
        pitch = rowCount == 0 ? naturalPitch : min(naturalPitch, available / CGFloat(rowCount))
    }

    func y(ofRow row: Int) -> CGFloat { top + CGFloat(row) * pitch }

    func row(atY y: CGFloat) -> Int {
        pitch > 0 ? min(max(0, Int((y - top) / pitch)), max(0, rowCount - 1)) : 0
    }

    /// One bar per text row while rows are two pixels apart or more; otherwise one per pixel row in the strongest ink
    /// of its rows at their widest. O(rows); at most max(rows that fit, height / pixel) bars.
    func bars(for outline: ConversationOutline, pixel: CGFloat) -> [Bar] {
        var bars: [Bar] = []
        let columns = CGFloat(ConversationOutlineBuilder.columns)
        if pitch >= 2 * pixel {
            let thickness = max(pixel, ((pitch * 2 / 3) / pixel).rounded() * pixel)
            for (index, block) in outline.blocks.enumerated() {
                for (line, width) in block.lineWidths.enumerated() where width > 0 {
                    let minY = (y(ofRow: outline.rowStarts[index] + line) / pixel).rounded(.down) * pixel
                    bars.append(Bar(minY: minY, height: thickness, widthFraction: CGFloat(width) / columns, ink: Ink(block.kind)))
                }
            }
            return bars
        }
        var current: (pixelRow: Int, ink: Ink, width: CGFloat)?
        func flush() {
            if let current {
                bars.append(Bar(minY: CGFloat(current.pixelRow) * pixel, height: pixel, widthFraction: current.width, ink: current.ink))
            }
        }
        for (index, block) in outline.blocks.enumerated() {
            let ink = Ink(block.kind)
            for (line, width) in block.lineWidths.enumerated() where width > 0 {
                let pixelRow = Int(y(ofRow: outline.rowStarts[index] + line) / pixel)
                let fraction = CGFloat(width) / columns
                if let shared = current, shared.pixelRow == pixelRow {
                    current = (pixelRow, max(shared.ink, ink), max(shared.width, fraction))
                } else {
                    flush()
                    current = (pixelRow, ink, fraction)
                }
            }
        }
        flush()
        return bars
    }

    /// Each bookmark's letter beside its message's first row, pushed down then up just enough that none overlap and all
    /// stay inside. In a column too short for them all apart (26 at a large interface size in a short window) they
    /// overlap evenly instead, each below the one before, so every letter's top still shows. A bookmark without a block
    /// (gone, or newer than the last read) has none.
    func chips(for bookmarks: [MessageBookmark], in outline: ConversationOutline, side: CGFloat, height: CGFloat) -> [Chip] {
        var chips = bookmarks.compactMap { bookmark -> Chip? in
            guard let index = outline.blockIndex(for: bookmark) else { return nil }
            let rowY = y(ofRow: outline.rowStarts[index])
            return Chip(letter: bookmark.letter, rowY: rowY, chipY: rowY - side / 2)
        }.sorted { $0.rowY < $1.rowY }
        let step = chips.count > 1 ? min(side + 1, max(0, height - side) / CGFloat(chips.count - 1)) : side + 1
        var floor: CGFloat = 0
        for index in chips.indices {
            let chipY = max(chips[index].chipY, floor)
            chips[index] = Chip(letter: chips[index].letter, rowY: chips[index].rowY, chipY: chipY)
            floor = chipY + step
        }
        var ceiling = height - side
        for index in chips.indices.reversed() {
            // At 0 for the top one when they overlap evenly, which rounding can leave a hair above.
            let chipY = max(0, min(chips[index].chipY, ceiling))
            chips[index] = Chip(letter: chips[index].letter, rowY: chips[index].rowY, chipY: chipY)
            ceiling = chipY - step
        }
        return chips
    }

    /// The bookmark whose chip is under `point`: x within the chip column and y within its square. Where chips overlap,
    /// the lower one, drawn last.
    func bookmark(at point: CGPoint, chips: [Chip], bookmarks: [MessageBookmark], width: CGFloat, side: CGFloat) -> MessageBookmark? {
        guard point.x >= width - ConversationMapMetrics.chipGap - side,
              let chip = chips.last(where: { point.y >= $0.chipY && point.y <= $0.chipY + side }) else { return nil }
        return bookmarks.first { $0.letter == chip.letter }
    }
}
