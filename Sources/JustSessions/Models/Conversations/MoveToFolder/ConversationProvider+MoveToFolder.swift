import Foundation

/// Claude Code moves a session to another folder with its own `/cd` command: it moves the transcript into that folder's
/// project directory, tells the model the folder changed, and first asks in the terminal when the session hasn't worked
/// in the folder before. The app sends `/cd` as the resumed session's first message, so Claude Code does all of that
/// itself; see `ConversationStore.moveSession(_:toFolder:)`.
extension ConversationProvider {
    var movesSessionsToOtherFolders: Bool { self == .claude }

    /// The arguments, after the resume arguments, that move the session to `folderPath` once its CLI starts. `/cd`
    /// reads the rest of its line as the path, so a path with spaces is passed as it is.
    func moveToFolderArguments(_ folderPath: String) -> [String] {
        initialPromptArguments("/cd \(folderPath)")
    }
}
