import AppKit
import SwiftUI

struct ContentView: View {
    /// Holds the window's store for the window's lifetime: `@StateObject` creates it once, where `@State`'s initial value
    /// would build a throwaway store every time the window's view is recreated. The holder never publishes; views follow
    /// the store's own observation.
    @StateObject private var storeHolder: StoreHolder
    private var store: ConversationStore { storeHolder.store }
    @State private var searchText = ""
    @State private var recencyFilter: SessionRecencyFilter = .all
    @State private var providerFilter: ConversationProviderFilter = .all
    @State private var statusFilter: SessionStatusFilter = .all
    @State private var renamingConversation: Conversation?
    @State private var renamingProject: ProjectConversationGroup?
    @State private var editedProjectName = ""
    @State private var deletionRequest: SessionDeletionRequest?
    @State private var editedTitle = ""
    @State private var hasStartedScan = false

    init(readService: WorkspaceReadService) {
        _storeHolder = StateObject(wrappedValue: StoreHolder(store: ConversationStore(windowRegistry: .shared, readService: readService)))
    }

    var body: some View {
        ConversationBrowserView(
            store: store,
            searchText: $searchText,
            recencyFilter: $recencyFilter,
            providerFilter: $providerFilter,
            statusFilter: $statusFilter,
            onRename: { conversation in
                editedTitle = store.title(for: conversation)
                renamingConversation = conversation
            },
            onRenameProject: { project in
                editedProjectName = project.displayName
                renamingProject = project
            },
            onRequestDeletion: { deletionRequest = $0 }
        )
        .onAppear {
            if !hasStartedScan {
                hasStartedScan = true
                store.reopenTabsFromLastQuit()
                // Each host loads independently when the workspace first opens.
                for host in store.hosts { store.refresh(host) }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            ExternalEditorStore.shared.refresh()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            store.prepareTabsForTermination()
        }
        .background(WorkspaceWindowRegistration(store: store))
        .onDisappear { store.closeWorkspace() }
        .alert("Rename conversation", isPresented: Binding(isPresenting: $renamingConversation)) {
            TextField("Name", text: $editedTitle)
            Button("Cancel", role: .cancel) { renamingConversation = nil }
            Button("Save") {
                if let conversation = renamingConversation { store.rename(conversation, to: editedTitle) }
                renamingConversation = nil
            }
        } message: {
            Text("This changes the display name in JustSessions.")
        }
        .dismissesOnClickOutside(item: $renamingConversation)
        .alert("Rename project", isPresented: Binding(isPresenting: $renamingProject)) {
            TextField("Name", text: $editedProjectName)
            Button("Cancel", role: .cancel) { renamingProject = nil }
            Button("Save") {
                if let project = renamingProject { store.renameProject(project.projectPath, to: editedProjectName) }
                renamingProject = nil
            }
        } message: {
            Text("Only renames it in JustSessions. Leave empty to use the folder name (\(renamingProject?.folderName ?? "")).")
        }
        .dismissesOnClickOutside(item: $renamingProject)
        .sessionDeletionDialog(for: $deletionRequest, store: store)
        .storeAlert(store)
    }
}

/// The window's store, held by `@StateObject` so it is created once; see `ContentView.storeHolder`.
private final class StoreHolder: ObservableObject {
    let store: ConversationStore

    init(store: ConversationStore) {
        self.store = store
    }
}
