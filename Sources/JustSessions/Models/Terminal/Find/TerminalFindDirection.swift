/// Which way a terminal's find moves from the selected match. A search starts at the newest output, so the next match
/// is the one printed before it, as in Ghostty and Terminal: Return and ⌘G go toward older output, and Shift-Return
/// and ⇧⌘G toward newer. Both wrap around.
enum TerminalFindDirection: Equatable {
    case towardOlder
    case towardNewer
}
