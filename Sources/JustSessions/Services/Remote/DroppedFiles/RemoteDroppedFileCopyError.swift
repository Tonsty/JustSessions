import Foundation

/// Why a file dropped on a tab could not be copied to the tab's SSH host.
enum RemoteDroppedFileCopyError: LocalizedError, Equatable {
    /// The file could not be opened on this Mac.
    case couldNotRead(fileName: String)
    case couldNotRun(host: String)
    /// `ssh` could not connect, or lost the connection, for the reason its output gave.
    case sshFailed(host: String, problem: SSHConnectionProblem)
    case couldNotMakeFolder(host: String)
    case couldNotWrite(host: String, fileName: String)
    case incomplete(host: String, fileName: String)
    /// Nothing arrived for `RemoteDroppedFileCopier.stallTimeout`.
    case stalled(host: String)
    /// The host's command failed some other way, with the last line it printed.
    case failed(host: String, output: String)

    var errorDescription: String? {
        switch self {
        case .couldNotRead(let fileName):
            "\(fileName) couldn't be read on this Mac."
        case .couldNotRun(let host):
            "Copying to \(host) did not start."
        case .sshFailed(let host, let problem):
            problem.explanation(host: host)
        case .couldNotMakeFolder(let host):
            "\(host) has no room for dropped files: ~/\(RemoteDroppedFileCopyScript.droppedFilesFolder) couldn't be made."
        case .couldNotWrite(let host, let fileName):
            "\(fileName) couldn't be written on \(host). Its disk may be full."
        case .incomplete(let host, let fileName):
            "Only part of \(fileName) reached \(host). Drop or paste it again."
        case .stalled(let host):
            "\(host) stopped taking the file. Check the connection, then drop or paste it again."
        case .failed(let host, let output):
            "Copying to \(host) failed: \(output)"
        }
    }
}
