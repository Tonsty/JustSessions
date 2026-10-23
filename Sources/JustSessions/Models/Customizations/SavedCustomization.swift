import Foundation

/// A choice made in the app and kept in settings, which every workspace window shows: session and project names,
/// pins, archiving, and message bookmarks. See `ConversationStore.changeSavedCustomization(_:_:)`.
protocol SavedCustomization: Equatable {
    static func load(from userDefaults: UserDefaults) -> Self
    func save(to userDefaults: UserDefaults)
}

extension ConversationTitleAliases: SavedCustomization {}
extension ProjectDisplayNames: SavedCustomization {}
extension PinnedItems: SavedCustomization {}
extension ArchivedSessions: SavedCustomization {}
extension MessageBookmarks: SavedCustomization {}
