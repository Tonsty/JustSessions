/// Joins a prompt's rows into its text. A CLI draws a line it wrapped and a line you broke the same way, so the rows
/// alone don't say which it was. Every supported CLI wraps at a space, which it leaves out of the rows, so a wrapped row
/// ends early only when the next word didn't fit:
/// - An empty row, a row the next row's first word would still have fit in, and a row before an indented one end a
///   line you broke.
/// - A full row was broken inside a word, which goes on in the next row.
/// - Any other row was wrapped at a space.
/// A line you broke right where the CLI would have wrapped it reads as wrapped.
enum CLIPromptLineJoining {
    static func text(of lines: [CLIPromptLine], wrapWidth: Int) -> String {
        guard var text = lines.first?.text else { return "" }
        for (previousLine, line) in zip(lines, lines.dropFirst()) {
            text += separator(after: previousLine, before: line, wrapWidth: wrapWidth)
            text += line.text
        }
        return text
    }

    private static func separator(after previousLine: CLIPromptLine, before line: CLIPromptLine, wrapWidth: Int) -> String {
        guard let firstCharacter = line.text.first, !previousLine.text.isEmpty, !firstCharacter.isWhitespace else {
            return "\n"
        }
        let firstWordCellCount = TerminalScreenRow(String(line.text.prefix { !$0.isWhitespace })).textWidth
        if previousLine.cellCount + 1 + firstWordCellCount <= wrapWidth { return "\n" }
        return previousLine.cellCount >= wrapWidth ? "" : " "
    }
}
