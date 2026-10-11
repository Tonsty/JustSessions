import Foundation

/// When each CLI on this Mac started waiting on you, as `WaitingForYou` decides it, for the notification bell's
/// newest-first order and its rows' ages. A wait starts at the activity sync that first sees it, so a CLI first seen
/// while it waits, as at launch, starts waiting then. Kept under every key the CLI goes by, like
/// `SessionAttentionTracker`, so a tab keeps its time once it learns its session, and its CLI keeps it after the tab
/// closes with the CLI left running in tmux.
struct WaitingForYouStartTimes: Equatable {
    private enum WaitKind: Equatable {
        case needsInput
        case finishedTurn

        init(_ reason: SessionAttentionReason) {
            switch reason {
            case .needsInput: self = .needsInput
            case .finishedTurn: self = .finishedTurn
            }
        }
    }

    private struct Wait: Equatable {
        let kind: WaitKind
        let startTime: Date
    }

    private var waitsByActivityKey: [String: Wait] = [:]

    /// Nil when the CLI does not wait on you, as of the last activity sync.
    func startTime(of source: SessionAttentionSource) -> Date? {
        wait(of: source)?.startTime
    }

    /// After an activity sync, which saw `observations` at `now` and has just updated `unseenFinishedTurns`. A wait
    /// that goes on keeps its time, even when the CLI words what it waits for differently; a CLI that stops for your
    /// answer after finishing its turn starts waiting again. A CLI missing from `observations` no longer runs and is
    /// forgotten.
    mutating func update(
        after observations: [SessionActivityObservation],
        unseenFinishedTurns: UnseenFinishedTurns,
        at now: Date
    ) {
        var nextWaits: [String: Wait] = [:]
        for observation in observations {
            let previousWait = wait(of: observation.source)
            let reason = WaitingForYou.reason(
                activity: observation.activity,
                hasUnseenFinishedTurn: unseenFinishedTurns.contains(observation.source)
            )
            let nextWait: Wait?
            if let reason {
                let kind = WaitKind(reason)
                nextWait = previousWait?.kind == kind ? previousWait : Wait(kind: kind, startTime: now)
            } else {
                // A CLI that tells nothing for a moment keeps waiting as it did.
                nextWait = observation.activity == nil ? previousWait : nil
            }
            guard let nextWait else { continue }
            for key in observation.source.activityKeys { nextWaits[key] = nextWait }
        }
        waitsByActivityKey = nextWaits
    }

    private func wait(of source: SessionAttentionSource) -> Wait? {
        source.activityKeys.lazy.compactMap { waitsByActivityKey[$0] }.first
    }
}
