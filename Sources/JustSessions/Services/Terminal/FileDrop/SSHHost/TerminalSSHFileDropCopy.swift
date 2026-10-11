import Foundation

/// One running copy of files dropped on a tab to its SSH host: the files still to copy, the host paths of those done,
/// and how far it has gone; see `TerminalSSHFileDrop`.
@MainActor
final class TerminalSSHFileDropCopy {
    struct File: Sendable {
        let id = UUID()
        let url: URL
        /// For the progress of all the files; the copy itself reads the size of the file it opens.
        let byteCount: Int64
    }

    let id = UUID()
    let startedAt = Date()
    let cancellation = RemoteDroppedFileCopyCancellation()
    /// Every file dropped for this copy, those still queued included.
    private(set) var fileCount: Int
    private(set) var hostPaths: [String] = []
    private(set) var currentFile: File?
    private var queuedFiles: [File]
    private var totalByteCount: Int64
    private var copiedByteCountOfFinishedFiles: Int64 = 0
    private var copiedByteCountOfCurrentFile: Int64 = 0

    init(files: [File]) {
        queuedFiles = files
        fileCount = files.count
        totalByteCount = files.reduce(0) { $0 + $1.byteCount }
    }

    var currentFileNumber: Int { hostPaths.count + 1 }

    var fractionCopied: Double {
        guard totalByteCount > 0 else { return 0 }
        return min(1, Double(copiedByteCountOfFinishedFiles + copiedByteCountOfCurrentFile) / Double(totalByteCount))
    }

    /// Files dropped while the copy runs, copied after those before them.
    func add(_ files: [File]) {
        queuedFiles += files
        fileCount += files.count
        totalByteCount += files.reduce(0) { $0 + $1.byteCount }
    }

    func nextFile() -> File? {
        guard !queuedFiles.isEmpty else { return nil }
        let file = queuedFiles.removeFirst()
        currentFile = file
        copiedByteCountOfCurrentFile = 0
        return file
    }

    /// Ignored for a file that is no longer the one being copied.
    func updateProgress(of fileID: UUID, copiedByteCount: Int64) {
        guard currentFile?.id == fileID else { return }
        copiedByteCountOfCurrentFile = copiedByteCount
    }

    func finishFile(_ file: File, hostPath: String) {
        hostPaths.append(hostPath)
        copiedByteCountOfFinishedFiles += file.byteCount
        copiedByteCountOfCurrentFile = 0
        currentFile = nil
    }
}
