import Foundation

/// Check this host…, from an SSH host's ⋯ menu or its refresh warning, and Check host on an SSH tab whose command
/// ended, which also checks that tab's folder and CLI. The window's sheet shows the check while it runs, then its
/// report; see `RemoteHostCheck`. The shell startup it finds is kept as the shell startup check's own would be.
extension ConversationStore {
    func checkHost(_ host: String, session: HostCheckSession? = nil) {
        let state = HostCheckSheetState(host: host, session: session)
        hostCheck = state
        runHostCheck(state)
    }

    /// Check host on an SSH tab whose command ended, as when its session failed to resume.
    func checkHost(ofTerminal id: UUID) {
        guard let tab = terminalSessions.first(where: { $0.id == id }), let host = tab.host.sshDestination else { return }
        checkHost(host, session: HostCheckSession(provider: tab.provider, projectPath: tab.projectPath))
    }

    /// Check again in the sheet, as after you changed something on the host.
    func checkShownHostAgain() {
        guard var state = hostCheck, !state.isChecking else { return }
        state.runID = UUID()
        state.report = nil
        hostCheck = state
        runHostCheck(state)
    }

    private func runHostCheck(_ state: HostCheckSheetState) {
        let host = state.host
        let programs = RemoteHostCheckProgram.all { customStartCommand(for: $0, on: .ssh(host)) }
        let providersWithSessions = Set(conversations.filter { $0.host == .ssh(host) }.map(\.provider))
        let check = remoteHostCheck
        let session = state.session
        let runID = state.runID
        Task.detached(priority: .userInitiated) {
            let outcome = check.check(
                host: host,
                programs: programs,
                session: session,
                providersWithSessions: providersWithSessions,
                thisMacSummary: HostCheckThisMacSummary.current()
            )
            await self.finishHostCheck(outcome, host: host, runID: runID)
        }
    }

    private func finishHostCheck(_ outcome: RemoteHostCheck.Outcome, host: String, runID: UUID) {
        if let shellStartupResult = outcome.shellStartupResult {
            applyRemoteShellStartupCheckResult(shellStartupResult, on: host)
        }
        if let cliLocations = outcome.cliLocations, remoteHostList.hosts.contains(host) {
            RemoteHostCLILocations.shared.setLocations(cliLocations, on: host)
            setInstalledProviders(Set(cliLocations.keys), on: .ssh(host))
        }
        // The sheet may have closed, or started another run, since.
        guard hostCheck?.runID == runID else { return }
        hostCheck?.report = outcome.report
    }
}
