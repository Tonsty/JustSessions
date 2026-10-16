import Foundation

/// Sessions on SSH hosts. Each host is copied into a local mirror in the background, apart from this Mac's scan,
/// so a slow or unreachable host never holds up the rest of the list.
extension ConversationStore {
    /// Returns the refresh's task, or nil when none started: the host is refreshing already, or a deletion from it
    /// runs and the refresh waits for it.
    @discardableResult
    func refreshRemoteHost(
        _ host: String,
        discovery: RemoteSessionDiscovery = RemoteSessionDiscovery()
    ) -> Task<Void, Never>? {
        guard remoteHostList.hosts.contains(host),
              !deferRefreshWhileDeleting(on: .ssh(host)),
              hostRefreshStatuses[.ssh(host)] != .refreshing else { return nil }
        hostRefreshStatuses[.ssh(host)] = .refreshing
        return Task.detached(priority: .userInitiated) {
            // The last copy lists right away; the host may be slow or offline.
            if let mirroredConversations = try? discovery.readMirror(host: host), !mirroredConversations.isEmpty {
                await self.applyRemoteHostConversations(mirroredConversations, host: host)
            }
            do {
                try await discovery.discoverToolByTool(
                    host: host,
                    copying: { step in await self.setRemoteSessionCopyStep(step, host: host) },
                    copied: { step, toolConversations in
                        await self.applyRemoteHostConversations(toolConversations, of: step, host: host)
                    }
                )
                let status = RemoteHostStatusProbe.status(ofHost: host)
                if let status {
                    await self.setTmuxSessionNames(status.tmuxSessionNames, on: .ssh(host))
                    await self.setTmuxServerProblem(status.tmuxServerProblem, on: host)
                    if let cliLocations = status.cliLocations {
                        RemoteHostCLILocations.shared.setLocations(cliLocations, on: host)
                        await self.setInstalledProviders(Set(cliLocations.keys), on: .ssh(host))
                    }
                    await self.checkClaudeSessionIDFlagIfUnanswered(on: host)
                }
                let refreshedAt = Date.now
                await self.setRemoteHostRefreshStatus(.refreshed(refreshedAt), host: host)
                await self.noteLoginState(on: host, refreshProblem: nil)
                await self.shareRemoteHostCopy(host, refreshedAt: refreshedAt, status: status, discovery: discovery)
                // After the refresh, so a check that changes how the host's shell starts can refresh it again.
                if let status {
                    await self.checkRemoteShellStartupIfNeeded(on: host, statusListedCLIs: status.installedProviders != nil)
                }
            } catch {
                await self.setRemoteHostRefreshStatus(.failed(error.localizedDescription), host: host)
                if case .sshFailed(_, let problem)? = error as? RemoteSessionMirrorError {
                    await self.noteLoginState(on: host, refreshProblem: problem)
                    // Windows' shell runs none of the check's commands, which would blame the host's startup files.
                    if problem == .windowsHost { return }
                }
                await self.checkRemoteShellStartupIfNeeded(on: host, statusListedCLIs: false)
            }
        }
    }

    /// Why the app can't log in to `host` without a prompt, or through a login made with Connect…, or nil when it
    /// can; checked before the host is added.
    func connectionProblem(
        on host: String,
        check: RemoteHostConnectionCheck = RemoteHostConnectionCheck()
    ) async -> SSHConnectionProblem? {
        await Task.detached(priority: .userInitiated) { check.problem(connectingTo: host) }.value
    }

    /// Where `ssh` would connect for the host, and the listed host that connects to the same place, read off the main
    /// actor with `ssh -G`.
    func sameMachineCheck(for host: String) async -> SSHHostSameMachineCheck {
        let listedHosts = remoteHostList.hosts
        return await Task.detached(priority: .userInitiated) {
            SSHHostSameMachineCheck.check(host: host, listedHosts: listedHosts)
        }.value
    }

    /// Returns false when the host is not a valid `ssh` destination or is already listed.
    @discardableResult
    func addRemoteHost(_ proposedHost: String) -> Bool {
        guard remoteHostList.add(proposedHost), let host = RemoteHostList.normalizedHost(proposedHost) else { return false }
        remoteHostList.save(to: userDefaults)
        messageIndexer.restoreHost(.ssh(host))
        refreshRemoteHost(host)
        return true
    }

    func removeRemoteHost(_ host: String, mirror: RemoteSessionMirror = RemoteSessionMirror()) {
        remoteHostList.remove(host)
        disconnect(host)
        SSHPortForwards.shared.stopAll(on: host)
        RemoteSignIns.shared.forget(host)
        forgetLoginState(on: host)
        messageIndexer.removeHost(.ssh(host))
        remoteHostList.save(to: userDefaults)
        remoteHostsUsingTmuxPrefix.setUsesTmuxPrefix(false, for: host)
        remoteHostsUsingTmuxPrefix.save(to: userDefaults)
        tabCloseChoiceSettingsStore.forgetSSHHost(host)
        forgetRemoteShellStartup(on: host)
        forgetHostChecks(on: host)
        hostRefreshStatuses.removeValue(forKey: .ssh(host))
        remoteSessionCopySteps.removeValue(forKey: .ssh(host))
        tmuxSessionNamesByHost.removeValue(forKey: .ssh(host))
        installedProvidersByHost.removeValue(forKey: .ssh(host))
        RemoteHostCLILocations.shared.forgetLocations(on: host)
        replaceConversations(on: .ssh(host), with: [])
        Task.detached(priority: .utility) {
            mirror.removeMirror(host: host)
        }
        // A Try Again that waited for this host's refresh can start for the other hosts' sessions; the refresh
        // ends without reporting, now that the host is gone.
        startQueuedDeletion()
    }

    /// Lists a host's sessions from its copy, and links the tabs waiting for them.
    func applyRemoteHostConversations(
        _ hostConversations: [Conversation],
        host: String,
        discardMissingReopeningTabs: Bool = true
    ) {
        // The host may have been removed while its copy ran.
        guard remoteHostList.hosts.contains(host) else { return }
        replaceConversations(on: .ssh(host), with: hostConversations, discardMissingReopeningTabs: discardMissingReopeningTabs)
        linkWaitingTabsToPreassignedSessions(on: .ssh(host))
        linkWaitingTabsByAppearance(on: .ssh(host))
    }

    /// Lists one tool's sessions as soon as they are copied, in place of that tool's earlier ones; the host's other
    /// tools keep theirs until their own copy. A tab waiting to reopen is given up only once every tool is listed,
    /// since its session may be one of a tool not copied yet.
    func applyRemoteHostConversations(_ toolConversations: [Conversation], of step: RemoteSessionCopyStep, host: String) {
        let otherToolsConversations = (conversations + subagentConversations)
            .filter { $0.host == .ssh(host) && $0.provider != step.provider }
        applyRemoteHostConversations(
            otherToolsConversations + toolConversations,
            host: host,
            discardMissingReopeningTabs: step.isLast
        )
    }

    private func setRemoteSessionCopyStep(_ step: RemoteSessionCopyStep, host: String) {
        guard remoteHostList.hosts.contains(host) else { return }
        remoteSessionCopySteps[.ssh(host)] = step
    }

    private func setRemoteHostRefreshStatus(_ status: HostRefreshStatus, host: String) {
        guard remoteHostList.hosts.contains(host) else { return }
        hostRefreshStatuses[.ssh(host)] = status
        remoteSessionCopySteps.removeValue(forKey: .ssh(host))
        // A Try Again that waited for this refresh can start now.
        startQueuedDeletion()
    }
}
