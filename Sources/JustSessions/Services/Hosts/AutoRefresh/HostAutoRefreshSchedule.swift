import Foundation

/// When `HostAutoRefresher` refreshes each host on its own. This Mac is due a minute after its last refresh started;
/// an SSH host five minutes after its last copy. An SSH host whose refresh failed is tried five minutes after the
/// failure was seen, then twice as long after each failure in a row, up to an hour; one that waits for Connect… is
/// left alone. A host that has not had its first refresh is left to its window, which starts it.
struct HostAutoRefreshSchedule {
    static let thisMacInterval: TimeInterval = 60
    static let sshHostInterval: TimeInterval = 5 * 60
    static let longestSSHHostWait: TimeInterval = 60 * 60

    /// When each failing SSH host was last tried, or its failure first seen.
    private var lastTryByFailingHost: [String: Date] = [:]
    private var failuresInARowByHost: [String: Int] = [:]

    func isThisMacDue(lastRefreshStartedAt: Date?, status: HostRefreshStatus?, now: Date) -> Bool {
        guard status != .refreshing, let lastRefreshStartedAt else { return false }
        return now.timeIntervalSince(lastRefreshStartedAt) >= Self.thisMacInterval
    }

    mutating func isSSHHostDue(_ host: String, status: HostRefreshStatus?, needsLogIn: Bool, now: Date) -> Bool {
        switch status {
        case nil, .refreshing?:
            return false
        case .refreshed(let refreshedAt)?:
            lastTryByFailingHost.removeValue(forKey: host)
            failuresInARowByHost.removeValue(forKey: host)
            return now.timeIntervalSince(refreshedAt) >= Self.sshHostInterval
        case .failed?:
            guard !needsLogIn else { return false }
            guard let lastTry = lastTryByFailingHost[host] else {
                // A failure this schedule didn't start, such as the first refresh's, counts from when it is seen.
                lastTryByFailingHost[host] = now
                failuresInARowByHost[host] = 1
                return false
            }
            return now.timeIntervalSince(lastTry) >= Self.wait(afterFailuresInARow: failuresInARowByHost[host, default: 1])
        }
    }

    mutating func noteTry(on host: String, at date: Date) {
        lastTryByFailingHost[host] = date
    }

    /// After a refresh this schedule started, with the host's status once it ended.
    mutating func noteResult(on host: String, status: HostRefreshStatus?) {
        if case .failed? = status {
            failuresInARowByHost[host, default: 0] += 1
        } else {
            lastTryByFailingHost.removeValue(forKey: host)
            failuresInARowByHost.removeValue(forKey: host)
        }
    }

    /// Five minutes after one failure, ten after two, and so on, up to an hour.
    static func wait(afterFailuresInARow failures: Int) -> TimeInterval {
        min(sshHostInterval * pow(2, Double(min(max(failures - 1, 0), 10))), longestSSHHostWait)
    }
}
