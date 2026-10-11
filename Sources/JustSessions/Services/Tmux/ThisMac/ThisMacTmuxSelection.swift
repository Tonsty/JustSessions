import Foundation

/// The background refresh chooses a compatible server; opening a tab reads that choice without spawning probes.
final class ThisMacTmuxSelection: @unchecked Sendable {
    private let lock = NSLock()
    private var selectedServer: ThisMacTmuxServer?
    private var latestGeneration = 0

    var server: ThisMacTmuxServer? {
        lock.withLock { selectedServer }
    }

    /// Reserves the generation that may commit a probe. Beginning a newer probe invalidates every older answer,
    /// including one produced by a different coordinator sharing this resolver.
    func beginProbeGeneration() -> Int {
        lock.withLock {
            latestGeneration &+= 1
            return latestGeneration
        }
    }

    /// Probes candidates without changing the server new tabs use. A shared discovery commits the answer only after
    /// confirming that its generation is still current.
    func probe(from candidates: [ThisMacTmuxServer]) -> ThisMacTmuxServer? {
        let supportedServers = candidates.filter { $0.hasSupportedVersion() }
        // An installed version may already own running work. Keep its client until that server exits,
        // since tmux versions can use incompatible client/server protocols. Never kill it to migrate.
        return supportedServers.first(where: { $0.hasRunningSessions }) ?? supportedServers.first
    }

    @discardableResult
    func commit(_ server: ThisMacTmuxServer?, generation: Int) -> ThisMacTmuxServer? {
        lock.withLock {
            guard generation == latestGeneration else { return selectedServer }
            selectedServer = server
            return server
        }
    }

    /// A direct refresh probes and commits as one generation. Shared workspace discovery does these steps separately.
    func select(from candidates: [ThisMacTmuxServer]) -> ThisMacTmuxServer? {
        let generation = beginProbeGeneration()
        return commit(probe(from: candidates), generation: generation)
    }
}
