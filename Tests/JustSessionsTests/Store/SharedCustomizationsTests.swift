import Foundation
import Testing
@testable import JustSessions

/// Names, pins, and archiving belong to the app, so every workspace window shows each change, and a change in one
/// window never loses another's. Each window used to save its own copy, loaded when it opened, over the others'.
@MainActor
struct SharedCustomizationsTests {
    @Test func aRenameShowsInEveryWindowAndKeepsTheOtherWindowsRenames() throws {
        let isolatedUserDefaults = try IsolatedUserDefaults()
        defer { isolatedUserDefaults.removeSuite() }
        let registry = WorkspaceWindowRegistry()
        let first = Conversation.fixture(title: "First suggested")
        let second = Conversation.fixture(title: "Second suggested")
        let firstWindow = ConversationStore(adapters: [], userDefaults: isolatedUserDefaults.userDefaults, windowRegistry: registry)
        let secondWindow = ConversationStore(adapters: [], userDefaults: isolatedUserDefaults.userDefaults, windowRegistry: registry)

        firstWindow.rename(first, to: "Renamed in the first window")
        #expect(secondWindow.title(for: first) == "Renamed in the first window")

        secondWindow.rename(second, to: "Renamed in the second window")
        let relaunched = ConversationStore(adapters: [], userDefaults: isolatedUserDefaults.userDefaults)

        #expect(firstWindow.title(for: second) == "Renamed in the second window")
        #expect(relaunched.title(for: first) == "Renamed in the first window")
        #expect(relaunched.title(for: second) == "Renamed in the second window")
    }

    /// A store that never heard of the change, such as one opened before it in another registry, still keeps it.
    @Test func aChangeStartsFromWhatIsSavedNotFromTheWindowsOwnCopy() throws {
        let isolatedUserDefaults = try IsolatedUserDefaults()
        defer { isolatedUserDefaults.removeSuite() }
        let renamed = Conversation.fixture(title: "Suggested")
        let pinned = Conversation.fixture(title: "Pinned")
        let archived = Conversation.fixture(title: "Archived")
        let unaware = ConversationStore(adapters: [], userDefaults: isolatedUserDefaults.userDefaults)
        let other = ConversationStore(adapters: [], userDefaults: isolatedUserDefaults.userDefaults)

        other.rename(renamed, to: "Kept")
        other.renameProject("/work/app", to: "The App")
        other.setPinned(true, conversation: pinned)
        other.setArchived(true, conversations: [archived])
        unaware.rename(Conversation.fixture(title: "Another"), to: "Also kept")
        unaware.renameProject("/work/api", to: "The API")
        unaware.setPinned(true, projectPath: "/work/app")
        unaware.setArchived(true, conversations: [pinned])
        let relaunched = ConversationStore(adapters: [], userDefaults: isolatedUserDefaults.userDefaults)

        #expect(relaunched.title(for: renamed) == "Kept")
        #expect(relaunched.projectDisplayName(forProjectPath: "/work/app") == "The App")
        #expect(relaunched.projectDisplayName(forProjectPath: "/work/api") == "The API")
        #expect(relaunched.pinnedItems.isPinned(conversationID: pinned.id))
        #expect(relaunched.pinnedItems.isPinned(projectPath: "/work/app"))
        #expect(relaunched.archivedSessions.isArchived(conversationID: archived.id))
        #expect(relaunched.archivedSessions.isArchived(conversationID: pinned.id))
    }

    @Test func pinsArchivingAndProjectNamesShowInEveryWindow() throws {
        let isolatedUserDefaults = try IsolatedUserDefaults()
        defer { isolatedUserDefaults.removeSuite() }
        let registry = WorkspaceWindowRegistry()
        let conversation = Conversation.fixture(title: "Suggested")
        let firstWindow = ConversationStore(adapters: [], userDefaults: isolatedUserDefaults.userDefaults, windowRegistry: registry)
        let secondWindow = ConversationStore(adapters: [], userDefaults: isolatedUserDefaults.userDefaults, windowRegistry: registry)

        firstWindow.renameProject("/work/app", to: "The App")
        firstWindow.setPinned(true, conversation: conversation)
        firstWindow.setArchived(true, conversations: [conversation])

        #expect(secondWindow.projectDisplayName(forProjectPath: "/work/app") == "The App")
        #expect(secondWindow.pinnedItems.isPinned(conversationID: conversation.id))
        #expect(secondWindow.archivedSessions.isArchived(conversationID: conversation.id))
    }
}
