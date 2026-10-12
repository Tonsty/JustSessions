import Foundation

/// Every window's `TabBarLayout`, by its store, as its tab bar reports it. A tab bar takes out each group and tab that
/// leaves it, so a closed window leaves nothing behind. Each span is the report of one view, the last to report it, and
/// only that view takes it out: a tab moving to another place in the bar, as one leaving a split across projects does,
/// shows there before its old view goes.
@MainActor
final class TabBarLayouts {
    /// What a view in a tab bar reports the span of.
    enum Item: Hashable, Sendable {
        case group(String)
        case tab(UUID)
    }

    private var layoutsByStore: [ObjectIdentifier: TabBarLayout] = [:]
    /// The view whose report each span is, by store.
    private var reportersByStore: [ObjectIdentifier: [Item: UUID]] = [:]
    /// Called after a window's tab bar lays out anew.
    var onChange: ((ConversationStore) -> Void)?

    func layout(of store: ConversationStore) -> TabBarLayout {
        layoutsByStore[ObjectIdentifier(store)] ?? TabBarLayout()
    }

    func report(_ span: TabBarLayout.Span, of item: Item, in store: ConversationStore, by reporter: UUID) {
        reportersByStore[ObjectIdentifier(store), default: [:]][item] = reporter
        change(item, to: span, in: store)
    }

    /// Takes out the span `reporter` reported, unless another view has reported it since.
    func withdraw(_ item: Item, in store: ConversationStore, by reporter: UUID) {
        let storeID = ObjectIdentifier(store)
        guard reportersByStore[storeID]?[item] == reporter else { return }
        reportersByStore[storeID]?[item] = nil
        if reportersByStore[storeID]?.isEmpty == true { reportersByStore[storeID] = nil }
        change(item, to: nil, in: store)
    }

    private func change(_ item: Item, to span: TabBarLayout.Span?, in store: ConversationStore) {
        let storeID = ObjectIdentifier(store)
        var layout = layoutsByStore[storeID] ?? TabBarLayout()
        switch item {
        case .group(let groupKey): layout.groupSpans[groupKey] = span
        case .tab(let tabID): layout.tabSpansInGroups[tabID] = span
        }
        guard layout != layoutsByStore[storeID] ?? TabBarLayout() else { return }
        layoutsByStore[storeID] = layout.isEmpty ? nil : layout
        onChange?(store)
    }
}
