/// What ⌘-clicking a link to a file on this Mac does, set in Settings → General → Tabs. Web addresses, folders, and
/// paths on SSH hosts open as before whatever it is.
enum FileLinkClickChoice: Hashable {
    /// Opens it in the app macOS opens its kind of file with, leaving out the line, as before there was a choice.
    case defaultApp
    /// Shows the items a right-click on the link shows, at the pointer.
    case askEachTime
    /// Opens a text file in the installed editor of this name, at the printed line where the editor can; any other
    /// file opens in its default app. See `FileLinkEditorScope`.
    case editor(name: String)

    static let userDefaultsKey = "fileLinkClickChoice"

    /// How the choice is saved: `defaultApp`, `askEachTime`, or `editor:` followed by the editor's name.
    var storedValue: String {
        switch self {
        case .defaultApp: "defaultApp"
        case .askEachTime: "askEachTime"
        case .editor(let name): Self.editorPrefix + name
        }
    }

    init?(storedValue: String) {
        switch storedValue {
        case "defaultApp": self = .defaultApp
        case "askEachTime": self = .askEachTime
        default:
            guard storedValue.hasPrefix(Self.editorPrefix) else { return nil }
            let name = String(storedValue.dropFirst(Self.editorPrefix.count))
            guard !name.isEmpty else { return nil }
            self = .editor(name: name)
        }
    }

    private static let editorPrefix = "editor:"
}
