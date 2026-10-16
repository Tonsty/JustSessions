import SwiftUI

struct ConversationBrowserView: View {
    let store: ConversationStore
    @Binding var searchText: String
    @Binding var recencyFilter: SessionRecencyFilter
    @Binding var providerFilter: ConversationProviderFilter
    @Binding var statusFilter: SessionStatusFilter
    @Binding var archiveFilter: SessionArchiveFilter
    let onRename: (Conversation) -> Void
    let onRenameProject: (ProjectConversationGroup) -> Void
    let onRequestDeletion: (SessionDeletionRequest) -> Void

    @State var sessionSelection = SessionMultiSelection()
    /// What this window showed, for Back and Forward; see `WorkspaceNavigationControls`.
    @State var navigationHistory = WorkspaceNavigationHistory()
    @State private var messageSearch = SidebarMessageSearch()
    /// The match a click on a session row found in messages opens the reader at.
    @State private var transcriptMatchReveal: TranscriptMatchReveal?
    /// The host the New Session sheet opened on; nil while it is closed.
    @State private var newSessionSheetHost: SessionHost?
    /// Settings or Help while either shows as a sheet on this window.
    @State private var appWideSheet: AppWideSheet?
    @State private var closingTerminalID: UUID?
    @State private var closingSeveralTabs: SeveralTabsClosingRequest?
    @SceneStorage("isSidebarHidden") private var isSidebarHidden = false
    @StateObject private var updateManager = SparkleUpdateManager()
    @StateObject private var onboardingTour = OnboardingTour()

    private var filteredProjection: FilteredSidebarProjection {
        store.filteredSidebarProjection(
            providerFilter: providerFilter,
            recencyFilter: recencyFilter,
            statusFilter: statusFilter,
            archiveFilter: archiveFilter,
            searchText: searchText,
            messageMatchConversationIDs: Set(messageSearch.results.matchesByConversationID.keys)
        )
    }

    /// Projects on every host that a new session can start in, most recent first.
    private var startableProjects: [ProjectConversationGroup] {
        store.sidebarProjectGroups.filter(\.canStartNewSession)
    }

    private var focusedConversation: Conversation? {
        guard let conversationID = sessionSelection.onlySelectedConversationID else { return nil }
        return store.conversation(withID: conversationID)
    }

    var body: some View {
        // Nothing in this body reads the selected tab, or anything else a tab switch changes: what does is read in the
        // modifiers and small views below, so a switch redraws them and not the sidebar's every row.
        let filteredProjection = filteredProjection

        ResizableSidebarLayout(isSidebarHidden: isSidebarHidden) {
            ConversationSidebarView(
                store: store,
                searchText: $searchText,
                recencyFilter: $recencyFilter,
                providerFilter: $providerFilter,
                statusFilter: $statusFilter,
                archiveFilter: $archiveFilter,
                sessionSelection: $sessionSelection,
                projects: filteredProjection.projects,
                allSessionCount: filteredProjection.allSessionCount,
                recentSessionCount: filteredProjection.recentSessionCount,
                runningSessionCount: filteredProjection.runningSessionCount,
                waitingSessionCount: filteredProjection.waitingSessionCount,
                archivedSessionCount: filteredProjection.archivedSessionCount,
                messageMatches: searchText.isEmpty ? [:] : messageSearch.results.matchesByConversationID,
                onNewSession: { newSessionSheetHost = defaultNewSessionHost },
                onSelectConversation: { conversation in
                    // A session a search found in messages opens its reader at the match, even while its CLI runs.
                    if !searchText.isEmpty, let match = messageSearch.match(for: conversation.id) {
                        sessionSelection.selectOnly(conversation.id)
                        store.selectTerminal(nil)
                        transcriptMatchReveal = TranscriptMatchReveal(
                            conversationID: conversation.id, entryID: match.entryID, query: messageSearch.results.query
                        )
                    // A session whose CLI runs opens on its terminal. Its row stays highlighted through its tab, so,
                    // as for a new session's row, the selection clears and the highlight follows the tabs.
                    } else if store.showRunningCLI(for: conversation) {
                        sessionSelection.clear()
                    } else {
                        sessionSelection.selectOnly(conversation.id)
                        store.selectTerminal(nil)
                    }
                },
                onRenameConversation: onRename,
                onRenameProject: onRenameProject,
                onRequestDeletion: onRequestDeletion,
                onCloseTerminal: { requestClosingTerminal($0) },
                onCloseTabGroup: { requestClosingTabs($0, subject: .group(projectName: $1)) },
                onCloseSelectedTabs: { requestClosingTabs($0, subject: .selectedTabs) }
            )
        } detail: {
            WorkspaceDetailView(
                store: store,
                sessionSelection: sessionSelection,
                transcriptMatchReveal: transcriptMatchReveal,
                isSidebarHidden: isSidebarHidden,
                onRename: onRename,
                onNewSession: { newSessionSheetHost = defaultNewSessionHost },
                onCloseTerminal: { requestClosingTerminal($0) },
                onCloseTabGroup: { requestClosingTabs($0, subject: .group(projectName: $1)) },
                onDelete: { onRequestDeletion(.conversation($0)) }
            )
        }
        .background(SidebarMessageSearchDriver(
            indexer: store.messageIndexer,
            search: messageSearch,
            typedQuery: searchText,
            conversations: store.sidebarConversations,
            conversationsRevision: store.conversationsRevision
        ))
        // A reveal opens the reader only for the session it was made for, and only once.
        .onChange(of: sessionSelection.onlySelectedConversationID) { _, conversationID in
            if conversationID != transcriptMatchReveal?.conversationID { transcriptMatchReveal = nil }
        }
        .modifier(WorkspaceNavigationControls(
            store: store,
            history: $navigationHistory,
            sessionSelection: $sessionSelection,
            isSidebarHidden: $isSidebarHidden,
            listedConversationIDs: filteredProjection.listedConversationIDs,
            isEnabled: workspaceTabCommandsEnabled
        ))
        .focusedSceneValue(\.isSidebarHidden, $isSidebarHidden)
        .background(SelectedTabTextZoomTarget(store: store))
        .sheet(item: $newSessionSheetHost) { host in
            let startableProjects = startableProjects
            NewSessionSheet(
                initialKind: newSessionKind,
                initialHost: host,
                initialProjectPath: newSessionProjectPath(on: host, startableProjects: startableProjects),
                hosts: store.hosts,
                providersByHost: store.newSessionProvidersByHost,
                recentProjects: startableProjects,
                startCommands: store.cliStartCommands,
                onSaveStartCommand: { try await store.saveStartCommand($0, for: $1, on: $2) }
            ) { request in
                switch request.kind {
                case .cli(let provider):
                    try await store.launchNewSession(
                        provider: provider,
                        host: request.host,
                        folder: request.folder,
                        creatingMissingFolder: request.creatingMissingFolder
                    )
                case .plainTerminal:
                    try await store.openPlainTerminal(
                        host: request.host,
                        folder: request.folder,
                        creatingMissingFolder: request.creatingMissingFolder
                    )
                }
            }
        }
        .dismissesOnClickOutside(item: $newSessionSheetHost)
        .sheet(item: hostCheckBinding) { state in
            HostCheckSheet(store: store, presentedState: state)
        }
        .dismissesOnClickOutside(item: hostCheckBinding)
        .showsAppWideSheets($appWideSheet, hosts: store.hosts, onCheckForUpdates: { updateManager.checkForUpdates() })
        .modifier(WorkspaceTabActionsValue(
            store: store,
            isEnabled: workspaceTabCommandsEnabled,
            newSession: { newSessionSheetHost = defaultNewSessionHost },
            requestClosingTab: { requestClosingTerminal($0) }
        ))
        .modifier(TerminalTabCloseConfirmation(
            store: store,
            closingSessionID: $closingTerminalID,
            tabCloseChoiceSettingsStore: .shared,
            plainTerminalCloseChoiceSettingsStore: .shared
        ))
        .modifier(SeveralTabsCloseConfirmation(store: store, request: $closingSeveralTabs))
        .modifier(OnboardingTipsPresenter(
            store: store,
            tour: onboardingTour,
            tipsStore: .shared,
            listsProjectWithSessions: filteredProjection.projects.contains { !$0.conversations.isEmpty },
            focusedConversation: focusedConversation,
            isSidebarShown: !isSidebarHidden,
            isReadyForTips: workspaceTabCommandsEnabled,
            onStartTour: { isSidebarHidden = false }
        ))
    }

    /// A tab still waiting to be shown runs nothing, so it closes without asking what to do with its CLI; so does a tab
    /// whose CLI or shell already ended, which also ends the dead tmux session that kept a failed CLI's output. A tab
    /// whose CLI can keep running in tmux, or a plain terminal, closes without asking too once you chose Don't ask
    /// again, doing what you chose: for that tab's host, or for every plain terminal.
    private func requestClosingTerminal(_ id: UUID?) {
        guard let id, let closingTab = store.terminalSessions.first(where: { $0.id == id }) else { return }
        switch closingTab.closingNeed {
        case .nothingStarted:
            store.closeTerminal(id)
        case .alreadyEnded:
            store.closeTerminal(id, endingTmuxSession: true)
        case .canKeepCLIRunning:
            let savedChoice = TabCloseChoiceSettingsStore.shared.choice(for: closingTab.host)
            if let endsTmuxSession = savedChoice.endsTmuxSessionWithoutAsking {
                store.closeTerminal(id, endingTmuxSession: endsTmuxSession)
            } else {
                closingTerminalID = id
            }
        case .plainTerminal where PlainTerminalCloseChoiceSettingsStore.shared.choice == .closeWithoutAsking:
            store.closeTerminal(id)
        case .plainTerminal, .cliStopsWithTab:
            closingTerminalID = id
        }
    }

    /// A group's one tab, or one tab selected, closes as its × closes it, with its own dialog. More ask once for them all,
    /// unless each would close without asking on its own.
    private func requestClosingTabs(_ tabIDs: [UUID], subject: SeveralTabsClosingRequest.Subject) {
        guard tabIDs.count > 1 else {
            requestClosingTerminal(tabIDs.first)
            return
        }
        let question = store.closingQuestion(
            forTabs: tabIDs,
            tabCloseChoices: TabCloseChoiceSettingsStore.shared.choices,
            plainTerminalCloseChoice: PlainTerminalCloseChoiceSettingsStore.shared.choice
        )
        if question == .closeWithoutAsking {
            store.closeTabs(tabIDs, as: TabCloseChoiceSettingsStore.shared.choices)
        } else {
            closingSeveralTabs = SeveralTabsClosingRequest(subject: subject, tabIDs: tabIDs, question: question)
        }
    }

    var workspaceTabCommandsEnabled: Bool {
        newSessionSheetHost == nil && appWideSheet == nil && closingTerminalID == nil && closingSeveralTabs == nil
            && store.hostCheck == nil
    }

    /// Check this host…'s sheet, which the sidebar and an ended tab open through the store.
    private var hostCheckBinding: Binding<HostCheckSheetState?> {
        Binding(get: { store.hostCheck }, set: { store.hostCheck = $0 })
    }

    /// The selected tab's tool, or a terminal when that tab is one; else the tool the sidebar shows, Codex when it shows
    /// every tool. The sheet takes the host's first installed tool instead when the host does not have this one.
    private var newSessionKind: NewSessionKind {
        if let selectedTerminal = store.selectedTerminal {
            return selectedTerminal.provider.map(NewSessionKind.cli) ?? .plainTerminal
        }
        return .cli(providerFilter.provider ?? .codex)
    }

    /// The host of the selected tab, or else of the selected session, so a new session starts next to it.
    private var defaultNewSessionHost: SessionHost {
        let host = store.selectedTerminal?.host ?? focusedConversation?.host ?? .thisMac
        return store.hosts.contains(host) ? host : .thisMac
    }

    /// The selected tab's or session's folder when it is on the host, or else the host's most recent project.
    private func newSessionProjectPath(on host: SessionHost, startableProjects: [ProjectConversationGroup]) -> String {
        if let selectedTerminal = store.selectedTerminal, selectedTerminal.host == host {
            return selectedTerminal.projectPath
        }
        if let focusedConversation, focusedConversation.host == host { return focusedConversation.projectPath }
        return startableProjects.first { $0.host == host }?.location.path ?? ""
    }
}

/// Text zoom goes to the terminals while a tab shows, and otherwise to the conversation. Read in this view's body, so a
/// tab switch redraws only it rather than the browser.
private struct SelectedTabTextZoomTarget: View {
    let store: ConversationStore

    var body: some View {
        TextZoomTargetReporter(target: store.selectedTerminalID == nil ? .conversation : .terminals)
    }
}

/// The tab commands, which follow the selected tab and the open tabs, and ⌃Tab's shortcuts. Read in this modifier's body,
/// so a tab switch redraws only it rather than the browser.
private struct WorkspaceTabActionsValue: ViewModifier {
    let store: ConversationStore
    /// No sheet, alert, or dialog is up.
    let isEnabled: Bool
    let newSession: () -> Void
    /// Asks to close a tab, as its × does.
    let requestClosingTab: (UUID?) -> Void

    func body(content: Content) -> some View {
        content
            .focusedSceneValue(\.workspaceTabActions, WorkspaceTabActions(
                tabCount: store.terminalSessions.count,
                hasSelectedTab: store.selectedTerminal != nil,
                isSplitShown: store.shownSplit != nil,
                isEnabled: isEnabled,
                newSession: newSession,
                closeSelectedTab: { requestClosingTab(store.selectedTerminalID) },
                selectAdjacentTab: { store.selectAdjacentTerminal(movingForward: $0) },
                selectTab: { store.selectTerminal(shortcutNumber: $0) },
                separateShownSplit: { if let shownSplit = store.shownSplit { store.separateSplit(shownSplit.id) } },
                closeShownSplitView: { side in
                    // The same close request as ⌘W, for the view on that side.
                    guard let shownSplit = store.shownSplit, let sides = store.sides(of: shownSplit) else { return }
                    requestClosingTab(sides.tabID(on: side))
                },
                reverseShownSplit: { if let shownSplit = store.shownSplit { store.reverseSplit(shownSplit.id) } }
            ))
            .background(WorkspaceTabCycleShortcuts(
                isEnabled: isEnabled && !store.terminalSessions.isEmpty,
                onSelectAdjacentTab: { store.selectAdjacentTerminal(movingForward: $0) }
            ))
    }
}
