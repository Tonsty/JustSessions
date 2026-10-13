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

    func refresh(_ host: SessionHost) {
        switch host {
        case .thisMac: refreshThisMac()
        case .ssh(let destination): refreshRemoteHost(destination)
        }
    }

    /// From the New Session sheet. The typed folder is looked up on its host first, so a missing folder is reported
    /// before a tab opens, or created when `creatingMissingFolder` is set, and the tab waits under the path the CLI
    /// records for its session.
    func launchNewSession(
        provider: ConversationProvider,
        host: SessionHost,
        folder: String,
        creatingMissingFolder: Bool = false,
        resolver: RemoteFolderResolver = RemoteFolderResolver()
    ) async throws {
        let location = try await projectLocation(
            of: folder,
            on: host,
            creatingMissingFolder: creatingMissingFolder,
            resolver: resolver
        )
        try launchNewSession(provider: provider, in: location)
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
            let resolvedPath = try await Task.detached(priority: .userInitiated) {
                try resolver.resolvedPath(of: folder, host: destination, creatingMissingFolder: creatingMissingFolder)
            }.value
            return ProjectLocation(host: host, path: resolvedPath)
        }
    }
}
