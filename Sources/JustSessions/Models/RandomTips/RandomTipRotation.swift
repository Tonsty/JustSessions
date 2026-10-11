/// Which random tip comes next: one picked at random among those not shown yet, and never the one showing, so every
/// tip shows once before any shows again. Once each has shown, the next round starts.
struct RandomTipRotation: Equatable {
    private(set) var shownTips: Set<RandomTip>

    /// Picks the tip to show after `currentTip` and counts it as shown. `randomIndex` returns an index below the count it
    /// is given.
    mutating func nextTip(after currentTip: RandomTip?, randomIndex: (Int) -> Int) -> RandomTip {
        var candidates = RandomTip.allCases.filter { !shownTips.contains($0) && $0 != currentTip }
        if candidates.isEmpty {
            shownTips = []
            candidates = RandomTip.allCases.filter { $0 != currentTip }
        }
        let nextTip = candidates[randomIndex(candidates.count)]
        shownTips.insert(nextTip)
        return nextTip
    }
}
