import Foundation

/// Stops a dropped file's copy from any thread: its `ssh` is stopped, the host removes what arrived, and the copy
/// throws `CancellationError`.
final class RemoteDroppedFileCopyCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var isCancelledValue = false
    private var runningProcess: Process?

    var isCancelled: Bool { lock.withLock { isCancelledValue } }

    func cancel() {
        let process: Process? = lock.withLock {
            isCancelledValue = true
            return runningProcess
        }
        if let process, process.isRunning { process.terminate() }
    }

    /// Stops `process` on a later `cancel()`; false, and nothing kept, when the copy is already cancelled.
    func watch(_ process: Process) -> Bool {
        lock.withLock {
            guard !isCancelledValue else { return false }
            runningProcess = process
            return true
        }
    }

    func stopWatching() {
        lock.withLock { runningProcess = nil }
    }
}
