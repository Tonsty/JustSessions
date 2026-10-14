import Foundation

/// When the app checks an SSH host on its own: once it hasn't been checked by this version of the app, once a day,
/// and soon after something suggests a problem, which is when a tab of the host ended with an error soon after it
/// started, or when the last refresh's tmux disagrees with the last check about reaching the tmux server. A check that
/// couldn't log in or finish is checked again within the hour once a refresh has worked since.
enum HostBackgroundCheckSchedule {
    static let dailyInterval: TimeInterval = 24 * 60 * 60
    /// The shortest time between two checks of a host, so a tab reconnected over and over, or a refresh and a check
    /// that keep disagreeing, don't check the host over and over.
    static let shortestInterval: TimeInterval = 10 * 60
    /// How soon a check that couldn't log in or finish is checked again; less often than `shortestInterval`, since
    /// such a check may keep failing on a host whose refreshes work, as when a CLI takes too long to print its version.
    static let unfinishedCheckInterval: TimeInterval = 60 * 60
    /// The findings of a check that couldn't log in, start the login shell, or finish.
    static let unfinishedCheckFindingIDs: Set<String> = ["connection", "login-shell", "script"]

    enum Reason: Equatable, Sendable {
        case neverChecked
        case checkedByAnotherAppVersion
        case tabEndedSoonAfterStarting
        case tmuxServerUnreachable
        case tmuxServerReachableAgain
        case refreshWorkedSinceUnfinishedCheck
        case daily
    }

    /// What the host's last refresh found.
    struct Refresh: Equatable, Sendable {
        let refreshedAt: Date
        let tmuxServerProblem: String?
    }

    /// Nil when the host isn't due a check.
    static func reason(
        keptCheck: KeptHostCheck?,
        appVersion: String,
        lastRefresh: Refresh,
        tabAskedForCheck: Bool,
        now: Date
    ) -> Reason? {
        guard let keptCheck else { return .neverChecked }
        if keptCheck.appVersion != appVersion { return .checkedByAnotherAppVersion }
        let checkedAt = keptCheck.report.checkedAt
        let age = now.timeIntervalSince(checkedAt)
        guard age >= shortestInterval else { return nil }
        if tabAskedForCheck { return .tabEndedSoonAfterStarting }
        // Only a refresh after the check says anything new about tmux.
        if lastRefresh.refreshedAt > checkedAt {
            let checkFoundTmuxServerUnreachable = keptCheck.report.findings.contains { $0.id == "tmux" && $0.status == .problem }
            switch (lastRefresh.tmuxServerProblem != nil, checkFoundTmuxServerUnreachable) {
            case (true, false): return .tmuxServerUnreachable
            case (false, true): return .tmuxServerReachableAgain
            default: break
            }
            let checkWasUnfinished = keptCheck.report.findings.contains {
                $0.status == .problem && unfinishedCheckFindingIDs.contains($0.id)
            }
            if checkWasUnfinished && age >= unfinishedCheckInterval { return .refreshWorkedSinceUnfinishedCheck }
        }
        return age >= dailyInterval ? .daily : nil
    }
}
