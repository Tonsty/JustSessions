import Foundation

/// Why an editor's command-line tool did not open a file; see `ExternalEditorFileOpener`.
enum ExternalEditorCommandLineToolError: LocalizedError, Equatable {
    case didNotFinish
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .didNotFinish: "The editor's command-line tool did not finish."
        case .failed(let output): output.isEmpty ? "The editor's command-line tool failed." : output
        }
    }
}
