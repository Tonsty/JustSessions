import AppKit
import Carbon.HIToolbox

/// What a key does while a CLI's prompt is selected, as in a text field with all its text selected.
enum PromptSelectionKeyAction: Equatable {
    /// ⌘C: copies the prompt and keeps it selected.
    case copy
    /// ⌘X: copies the prompt, then deletes it.
    case cut
    /// Delete, with Shift, Option, or Command too, or Forward Delete: deletes the prompt.
    case delete
    /// ⌘V, or a key that types text: deletes the prompt, then lets the key paste or type.
    case replace
    /// ← and →: put the caret at the prompt's start or end.
    case moveToStart
    case moveToEnd
    /// ⌘A again: selects all of the terminal.
    case selectAllTerminalText
    /// Escape: only ends the selection.
    case dismiss
    /// Any other key ends the selection and goes to the terminal as usual.
    case passThrough

    init(_ event: NSEvent) {
        let modifiers = event.modifierFlags.intersection([.shift, .control, .option, .command])
        if modifiers == .command, let commandAction = Self.commandAction(event) {
            self = commandAction
            return
        }
        switch Int(event.keyCode) {
        case kVK_Delete where [[], .shift, .option, .command].contains(modifiers):
            self = .delete
        case kVK_ForwardDelete where modifiers.isEmpty:
            self = .delete
        case kVK_LeftArrow where modifiers.isEmpty:
            self = .moveToStart
        case kVK_RightArrow where modifiers.isEmpty:
            self = .moveToEnd
        case kVK_Escape where modifiers.isEmpty:
            self = .dismiss
        default:
            self = modifiers.isSubset(of: .shift) && Self.typesText(event) ? .replace : .passThrough
        }
    }

    /// Whether `event` is ⌘A, which selects the prompt while the terminal has the keyboard; see `TerminalPromptSelection`.
    static func isSelectAll(_ event: NSEvent) -> Bool {
        event.type == .keyDown
            && event.modifierFlags.intersection([.shift, .control, .option, .command]) == .command
            && event.charactersIgnoringModifiers?.lowercased() == "a"
    }

    /// The letters are whichever keys type them on the keyboard's layout, as for the Edit menu.
    private static func commandAction(_ event: NSEvent) -> Self? {
        switch event.charactersIgnoringModifiers?.lowercased() {
        case "c": .copy
        case "x": .cut
        case "v": .replace
        case "a": .selectAllTerminalText
        default: nil
        }
    }

    /// A key that types visible text or a space, not a control character or a function key's private-use character.
    private static func typesText(_ event: NSEvent) -> Bool {
        guard let characters = event.characters, !characters.isEmpty else { return false }
        return characters.unicodeScalars.allSatisfy { scalar in
            !CharacterSet.controlCharacters.contains(scalar) && !(0xF700...0xF8FF).contains(scalar.value)
        }
    }
}
