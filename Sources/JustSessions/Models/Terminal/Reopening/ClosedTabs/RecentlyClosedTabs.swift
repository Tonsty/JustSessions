import Foundation

/// The tabs closed in one window, the latest last, for Reopen Closed Tab: each with the session it ran, or for a plain
/// terminal its folder, and its place in the tab bar. As in Chrome, the latest 25 are kept, and only while the window
/// is open.
struct RecentlyClosedTabs: Equatable {
    struct ClosedTab: Equatable {
        let tab: ReopenableTerminalTab
        /// The tab's place in the tab bar when it closed.
        let tabBarIndex: Int
    }

    static let maximumCount = 25

    private(set) var closedTabs: [ClosedTab] = []

    var isEmpty: Bool { closedTabs.isEmpty }

    /// A session closed again replaces its earlier entry: a session runs in one tab, so it reopens once.
    mutating func remember(_ tab: ReopenableTerminalTab, closedAt tabBarIndex: Int) {
        if let conversationID = tab.conversationID {
            closedTabs.removeAll { $0.tab.conversationID == conversationID }
        }
        closedTabs.append(ClosedTab(tab: tab, tabBarIndex: tabBarIndex))
        if closedTabs.count > Self.maximumCount {
            closedTabs.removeFirst(closedTabs.count - Self.maximumCount)
        }
    }

    mutating func takeLatest() -> ClosedTab? {
        closedTabs.popLast()
    }
}
