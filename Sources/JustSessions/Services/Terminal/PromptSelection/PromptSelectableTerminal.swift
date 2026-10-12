import AppKit

/// What `TerminalPromptSelection` asks of either engine's terminal.
@MainActor
protocol PromptSelectableTerminal: NSView {
    /// What the terminal shows now, with its cursor; nil while it shows its scrollback or hasn't laid out any text.
    func screenForPromptSelection() -> TerminalScreen?
    /// Where screen row `row`'s cells `columns` are drawn, in the terminal's coordinates.
    func frame(ofCells columns: Range<Int>, inRow row: Int) -> NSRect?
    /// Sends keys to the process after any typed before them.
    func typeForPromptSelection(_ keys: String)
    /// Selects all of the terminal's text, as the Edit menu's Select All does.
    func selectAllTerminalText()
    /// Whether the terminal's own selection holds text. Ghostty offers no way to end it but a click or a typed key.
    var selectionActive: Bool { get }
    /// While an input method composes text, the keys belong to it.
    func hasMarkedText() -> Bool
    /// How the terminal draws selected text, which the prompt's selection copies.
    var promptSelectionTextStyle: PromptSelectionTextStyle { get }
}

struct PromptSelectionTextStyle {
    let font: NSFont
    let backgroundColor: NSColor
    let foregroundColor: NSColor
}
