/// The text in a CLI's prompt box, as the screen shows it: one line per screen row, and the text they make together.
struct CLIPrompt: Equatable {
    let lines: [CLIPromptLine]
    /// What ⌘C copies: the rows joined where the CLI broke a line or wrapped one; see `CLIPromptLineJoining`.
    let text: String
    /// The prompt's rows after the caret's row, which the keys that move to the prompt's end pass; see
    /// `CLIPromptEditingKeys`.
    let rowCountBelowCaret: Int
    /// The prompt's rows before the caret's row.
    let rowCountAboveCaret: Int

    /// Nil when the rows hold no text. `wrapWidth` is how many cells of text the CLI puts in a row.
    init?(lines: [CLIPromptLine], wrapWidth: Int, caretRow: Int) {
        guard let firstLine = lines.first, let lastLine = lines.last, lines.contains(where: { !$0.text.isEmpty })
        else { return nil }
        self.lines = lines
        text = CLIPromptLineJoining.text(of: lines, wrapWidth: wrapWidth)
        rowCountBelowCaret = max(0, lastLine.row - caretRow)
        rowCountAboveCaret = max(0, caretRow - firstLine.row)
    }
}

/// One screen row of a prompt's text.
struct CLIPromptLine: Equatable {
    let row: Int
    /// The cell the text starts at, which the CLI keeps for it in every row of the prompt.
    let startColumn: Int
    /// The row's text from `startColumn`, without the blanks that end the row.
    let text: String
    /// The cells `text` takes.
    let cellCount: Int

    init(row: Int, startColumn: Int, text: String, cellCount: Int) {
        self.row = row
        self.startColumn = startColumn
        self.text = text
        self.cellCount = cellCount
    }

    /// The text of `screen`'s row `row` from `startColumn`.
    init(row: Int, of screen: TerminalScreen, startColumn: Int) {
        let rowText = screen.rows[row].text(fromColumn: startColumn)
        self.init(row: row, startColumn: startColumn, text: rowText.text, cellCount: rowText.cellCount)
    }
}
