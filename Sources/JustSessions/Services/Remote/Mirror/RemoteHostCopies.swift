import Foundation

/// When this window's copies of each SSH host started and ended, and how many ended in failure in a row, for a Claude
/// Code tab waiting on a session its host hasn't listed; see `followClaudeSessionSwitch`. Every window's are combined, so
/// the tabs waiting on a host, in one window or several, share one copy and the wait after it.
struct RemoteHostCopies {
    struct Copies: Equatable {
        var lastStartedAt: Date?
        var lastEndedAt: Date?
        /// How many of the copies that ended last failed in a row; 0 after one that didn't.
        var failuresInARow = 0
    }

    private var copiesByHost: [String: Copies] = [:]
    /// When a copy starts or ends; tests set the time.
    private let currentDate: () -> Date

    init(currentDate: @escaping () -> Date = Date.init) {
        self.currentDate = currentDate
    }

    func copies(of host: String) -> Copies { copiesByHost[host] ?? Copies() }

    mutating func noteStart(of host: String) {
        copiesByHost[host, default: Copies()].lastStartedAt = currentDate()
    }

    mutating func noteEnd(of host: String, failed: Bool) {
        var copies = copiesByHost[host, default: Copies()]
        copies.lastEndedAt = currentDate()
        copies.failuresInARow = failed ? copies.failuresInARow + 1 : 0
        copiesByHost[host] = copies
    }

    mutating func forget(_ host: String) {
        copiesByHost.removeValue(forKey: host)
    }

    /// The windows' copies as one: the latest start, and the latest end with its window's run of failures.
    static func combined(_ windows: [Copies]) -> Copies {
        var combined = Copies()
        for copies in windows {
            if let started = copies.lastStartedAt, started > (combined.lastStartedAt ?? .distantPast) {
                combined.lastStartedAt = started
            }
            if let ended = copies.lastEndedAt, ended > (combined.lastEndedAt ?? .distantPast) {
                combined.lastEndedAt = ended
                combined.failuresInARow = copies.failuresInARow
            }
        }
        return combined
    }
}
