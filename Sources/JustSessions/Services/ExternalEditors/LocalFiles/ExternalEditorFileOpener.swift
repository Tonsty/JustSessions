import AppKit

/// Opens a file or folder on this Mac, named by a link in a terminal, in an installed editor. A VS Code-family editor
/// gets a file with a line number through its command-line tool's `--goto`, which puts the cursor on that line and
/// column; any other editor, or a link without a line, opens the file as the Finder's Open With does.
@MainActor
enum ExternalEditorFileOpener {
    nonisolated static let timeout: TimeInterval = 30

    static func open(_ item: TerminalLinkLocalItem, in editor: InstalledExternalEditor) async throws {
        // The tool that opens SSH folders is the editor's `code` tool, which also takes `--goto`.
        if item.kind == .file, item.lineNumber != nil, let toolURL = editor.sshFolderCommandLineToolURL {
            try await goTo(item, withCommandLineToolAt: toolURL)
            return
        }
        _ = try await NSWorkspace.shared.open(
            [item.url],
            withApplicationAt: editor.applicationURL,
            configuration: NSWorkspace.OpenConfiguration()
        )
    }

    private static func goTo(_ item: TerminalLinkLocalItem, withCommandLineToolAt toolURL: URL) async throws {
        let arguments = ["--goto", item.pathWithLineAndColumn]
        let result = await Task.detached {
            BoundedProcessRunner.result(
                ofExecutable: toolURL.path,
                arguments: arguments,
                includesStandardError: true,
                timeout: Self.timeout
            )
        }.value
        guard let result else { throw ExternalEditorCommandLineToolError.didNotFinish }
        guard result.exitStatus == 0 else {
            throw ExternalEditorCommandLineToolError.failed(result.output.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
