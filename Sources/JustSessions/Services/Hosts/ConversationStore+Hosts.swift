import Foundation

/// This Mac and the SSH hosts are listed, refreshed, and started from alike. Only how a host's session files are
/// read and its CLI is reached differ; see `refreshThisMac()` and `ConversationStore+RemoteHosts`.
extension ConversationStore {
    /// This Mac first, then the SSH hosts in the order they were added.
    var hosts: [SessionHost] {
        [.thisMac] + remoteHostList.hosts.map(SessionHost.ssh)
    }

    var hasRemoteHosts: Bool { !remoteHostList.hosts.isEmpty }

    var isScanningThisMac: Bool { hostRefreshStatuses[.thisMac] == .refreshing }

    /// A disconnected SSH host is listed from its last copy instead, without reaching it; see
    /// `ConversationStore+RemoteHostDisconnect`.
    func refresh(_ host: SessionHost) {
        switch host {
        case .thisMac: refreshThisMac()
        case .ssh(let destination) where isDisconnected(destination): listRemoteHostFromMirror(destination)
        case .ssh(let destination): refreshRemoteHost(destination)
        }
    }

    /// A heading's refresh: an SSH host that couldn't be reached a moment ago is tried again now, where the app's own
    /// refreshes wait a while; see `SSHHostReachability`. A disconnected host connects again, which refreshes it.
    func refreshTryingAgain(_ host: SessionHost) {
        guard !isDisconnected(host) else {
            connectIfDisconnected(host)
            return
        }
        if let destination = host.sshDestination { SSHHostReachability.shared.forget(destination) }
        refresh(host)
    }

    /// From the New Session sheet. The typed folder is looked up on its host first, so a missing folder is reported
    /// before a tab opens, or created when `creatingMissingFolder` is set, and the tab waits under the path the CLI
    /// records for its session. With `deletesSessionWhenClosed`, closing the tab deletes the session.
    func launchNewSession(
        provider: ConversationProvider,
        host: SessionHost,
        folder: String,
        creatingMissingFolder: Bool = false,
        deletesSessionWhenClosed: Bool = false,
        resolver: RemoteFolderResolver = RemoteFolderResolver()
    ) async throws {
        let location = try await projectLocation(
            of: folder,
            on: host,
            creatingMissingFolder: creatingMissingFolder,
            resolver: resolver
        )
        try launchNewSession(provider: provider, in: location, deletesSessionWhenClosed: deletesSessionWhenClosed)
    }

    /// A folder typed in the New Session sheet or Add project, looked up on its host, which fails when it is missing
    /// unless `creatingMissingFolder` asks for it to be created there first.
    func projectLocation(
        of folder: String,
        on host: SessionHost,
        creatingMissingFolder: Bool = false,
        resolver: RemoteFolderResolver
    ) async throws -> ProjectLocation {
        switch host {
        case .thisMac:
            let path = try ThisMacFolderResolver.resolvedPath(of: folder, creatingMissingFolder: creatingMissingFolder)
            return ProjectLocation(host: .thisMac, path: path)
        case .ssh(let destination):
            connectIfDisconnected(host)
            let resolvedPath = try await Task.detached(priority: .userInitiated) {
                try resolver.resolvedPath(of: folder, host: destination, creatingMissingFolder: creatingMissingFolder)
            }.value
            return ProjectLocation(host: host, path: resolvedPath)
        }
    }
}
