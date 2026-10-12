/// One row of a terminal's screen as text, with the cell each character starts at. Words here are runs of characters
/// that aren't blank. Ghostty reads a cell nothing was written to as a space.
struct TerminalScreenRow {
    let characters: [Character]
    private let startColumns: [Int]
    private let cellCounts: [Int]

    init(_ text: String) {
        characters = Array(text)
        cellCounts = characters.map(TerminalCellWidth.cellCount(of:))
        var startColumns: [Int] = []
        var column = 0
        for cellCount in cellCounts {
            startColumns.append(column)
            column += cellCount
        }
        self.startColumns = startColumns
    }

    /// The index of the first character that isn't blank.
    var firstTextIndex: Int? { characters.firstIndex { !Self.isBlank($0) } }

    /// The index of the last character that isn't blank.
    var lastTextIndex: Int? { characters.lastIndex { !Self.isBlank($0) } }

    /// The cells up to and including the last character that isn't blank.
    var textWidth: Int {
        guard let lastTextIndex else { return 0 }
        return startColumns[lastTextIndex] + cellCounts[lastTextIndex]
    }

    /// The character whose cells hold `column`.
    func characterIndex(atColumn column: Int) -> Int? {
        characters.indices.first { startColumns[$0] <= column && column < startColumns[$0] + cellCounts[$0] }
    }

    /// The word holding the character at `index`; nil when that character is blank.
    func wordRange(around index: Int) -> Range<Int>? {
        guard characters.indices.contains(index), !Self.isBlank(characters[index]) else { return nil }
        var lowerBound = index
        while lowerBound > 0, !Self.isBlank(characters[lowerBound - 1]) { lowerBound -= 1 }
        var upperBound = index + 1
        while upperBound < characters.count, !Self.isBlank(characters[upperBound]) { upperBound += 1 }
        return lowerBound..<upperBound
    }

    /// The row's first word, after its indentation.
    var firstWordRange: Range<Int>? { firstTextIndex.flatMap(wordRange(around:)) }

    /// The row's last word.
    var lastWordRange: Range<Int>? { lastTextIndex.flatMap(wordRange(around:)) }

    static func isBlank(_ character: Character) -> Bool {
        character.isWhitespace
    }
}
