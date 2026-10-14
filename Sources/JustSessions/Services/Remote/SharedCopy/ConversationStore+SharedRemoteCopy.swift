import Foundation

/// Every window lists an SSH host from the same local copy, so once one window has copied a host, the others list
/// that copy instead of copying the host again.
extension ConversationStore {
    /// After this window copied `host`: the other windows list the copy, unless they are refreshing or deleting from
    /// the host themselves.
    func shareRemoteHostCopy(
        _ host: String,
        refreshedAt: Date,
        status: RemoteHostStatus?,
        discovery: RemoteSessionDiscovery
    ) {
        for store in otherWindowStores {
            store.listRemoteHostCopy(host, refreshedAt: refreshedAt, status: status, discovery: discovery)
        }
    }

    /// Lists the host's sessions from the copy another window just made, as this window's own refresh would have.
    func listRemoteHostCopy(
        _ host: String,
        refreshedAt: Date,
        status: RemoteHostStatus?,
        discovery: RemoteSessionDiscovery
    ) {
        guard canListRemoteHostCopy(host) else { return }
        Task.detached(priority: .userInitiated) {
            guard let hostConversations = try? discovery.readMirror(host: host) else { return }
            await self.applyRemoteHostCopy(host, hostConversations: hostConversations, refreshedAt: refreshedAt, status: status)
        }
    }

    private func applyRemoteHostCopy(
        _ host: String,
        hostConversations: [Conversation],
        refreshedAt: Date,
        status: RemoteHostStatus?
    ) {
        // This window may have started a refresh or a deletion of its own while the copy was read.
        guard canListRemoteHostCopy(host) else { return }
        applyRemoteHostConversations(hostConversations, host: host)
        if let status {
            setTmuxSessionNames(status.tmuxSessionNames, on: .ssh(host))
            setTmuxServerProblem(status.tmuxServerProblem, on: host)
            if let installedProviders = status.installedProviders {
                setInstalledProviders(installedProviders, on: .ssh(host))
            }
        }
        hostRefreshStatuses[.ssh(host)] = .refreshed(refreshedAt)
        noteLoginState(on: host, refreshProblem: nil)
    }

    private func canListRemoteHostCopy(_ host: String) -> Bool {
        remoteHostList.hosts.contains(host)
            && hostRefreshStatuses[.ssh(host)] != .refreshing
            && !isDeleting(on: .ssh(host))
    }
}
