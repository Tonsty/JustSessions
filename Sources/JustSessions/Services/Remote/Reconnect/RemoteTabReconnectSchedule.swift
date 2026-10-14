import Foundation

/// When `RemoteTabReconnector` asks an SSH host whether the CLIs of its dropped tabs still run in tmux. A host is first
/// asked 2 seconds after a tab dropped, the Mac woke, the app came forward, or a login opened, since the network may
/// still be coming back. After each failure it waits 5 seconds, then twice as long after each failure in a row, up
/// to a minute, and gives up 15 minutes after the event that started the tries.
struct RemoteTabReconnectSchedule {
    static let firstTryDelay: TimeInterval = 2
    static let shortestWait: TimeInterval = 5
    static let longestWait: TimeInterval = 60
    static let tryingPeriod: TimeInterval = 15 * 60

    private struct HostTries {
        var startedAt: Date
        var nextTryAt: Date
        var failuresInARow = 0
    }

    private var triesByHost: [String: HostTries] = [:]

    var hostsBeingTried: Set<String> { Set(triesByHost.keys) }

    /// The soonest a host other than `hostsBeingAsked` is due, for the reconnector to wake then; nil while no other
    /// host is tried. A host being asked stays due until its answer comes.
    func nextTryAt(excluding hostsBeingAsked: Set<String>) -> Date? {
        triesByHost.filter { !hostsBeingAsked.contains($0.key) }.values.map(\.nextTryAt).min()
    }

    /// Starts the tries over, as after a new drop or the Mac waking, even while the host is tried already.
    mutating func startTrying(_ host: String, now: Date) {
        triesByHost[host] = HostTries(startedAt: now, nextTryAt: now + Self.firstTryDelay)
    }

    func isDue(_ host: String, now: Date) -> Bool {
        guard let tries = triesByHost[host] else { return false }
        return now >= tries.nextTryAt
    }

    /// The host couldn't be asked, as when it didn't answer or needs Connect…. Returns false once the tries gave up.
    @discardableResult
    mutating func noteFailure(on host: String, now: Date) -> Bool {
        guard var tries = triesByHost[host] else { return false }
        guard now.timeIntervalSince(tries.startedAt) < Self.tryingPeriod else {
            triesByHost.removeValue(forKey: host)
            return false
        }
        tries.failuresInARow += 1
        tries.nextTryAt = now + Self.wait(afterFailuresInARow: tries.failuresInARow)
        triesByHost[host] = tries
        return true
    }

    /// The host answered, or has no dropped tab left to reconnect.
    mutating func stopTrying(_ host: String) {
        triesByHost.removeValue(forKey: host)
    }

    /// 5 seconds after one failure, 10 after two, and so on, up to a minute.
    static func wait(afterFailuresInARow failures: Int) -> TimeInterval {
        min(shortestWait * pow(2, Double(min(max(failures - 1, 0), 10))), longestWait)
    }
}
