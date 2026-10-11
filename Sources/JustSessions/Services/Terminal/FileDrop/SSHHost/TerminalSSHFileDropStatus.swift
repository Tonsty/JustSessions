import Foundation

/// What the notice over a tab on an SSH host says about files dropped on it; see `TerminalSSHFileDrop`.
enum TerminalSSHFileDropStatus: Equatable {
    /// File `fileNumber` of `fileCount`, named `fileName`, is being copied; `fractionCopied` is of all the files' bytes.
    case copying(fileName: String, fileNumber: Int, fileCount: Int, fractionCopied: Double)
    /// Nothing was typed, for the reason `explanation` gives in English, as the app's other connection errors do.
    case failed(explanation: String)
}
