/// What a terminal shows: its rows, top to bottom, and the cell its cursor is in.
struct TerminalScreen {
    let rows: [TerminalScreenRow]
    let columnCount: Int
    let cursor: TerminalCellPosition

    init(rows: [TerminalScreenRow], columnCount: Int, cursor: TerminalCellPosition) {
        self.rows = rows
        self.columnCount = columnCount
        self.cursor = cursor
    }

    /// A screen from its rows' text, as a test or Ghostty's viewport gives them.
    init(lines: [String], columnCount: Int, cursor: TerminalCellPosition) {
        self.init(rows: lines.map(TerminalScreenRow.init), columnCount: columnCount, cursor: cursor)
    }
}

/// A cell on a terminal's screen, counted from the top left one.
struct TerminalCellPosition: Equatable {
    let column: Int
    let row: Int
}
