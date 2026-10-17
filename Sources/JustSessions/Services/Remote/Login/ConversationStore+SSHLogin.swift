import Foundation

/// Connect… for SSH hosts that ask for a password, a passphrase, or a code, or whose host key is new: the app logs in
/// once, asking `ssh`'s questions in the window, and every window's commands, copies, and tabs on the host go through
/// that login; see `SSHLoginConnections`. A refresh that the host refuses for want of a login marks it, so its heading
/// offers Connect…, as it does again once the login has closed.
extension ConversationStore {
    /// Logs in to `host`, asking each of `ssh`'s questions with `ask`, which returns the answer or nil when cancelled.
    /// The host need not be listed yet, as from the Add SSH host sheet. Once logged in, every window refreshes it.
    func logIn(
        to host: String,
        login: SSHLogin = SSHLogin(),
        asking ask: @escaping @Sendable (SSHAskpassQuestion) async -> String?
    ) async -> SSHLoginOutcome {
        guard sshHostsLoggingIn.insert(host).inserted else { return .cancelled }
        let outcome = await login.logIn(to: host, ask: ask)
        sshHostsLoggingIn.remove(host)
        if outcome == .loggedIn {
            SSHHostReachability.shared.forget(host)
            for store in storesOfEveryWindow { store.loginOpened(on: host) }
            NotificationCenter.default.post(name: RemoteTabReconnector.loginOpenedNotification, object: host)
        }
        return outcome
    }

    /// Connect… on a host's heading; a login that fails says why in an alert.
    func logInFromHeading(to host: String, asking ask: @escaping @Sendable (SSHAskpassQuestion) async -> String?) {
        Task {
            guard case .failed(let problem) = await logIn(to: host, asking: ask) else { return }
            show(StoreAlert(title: "Couldn't log in to \(host)", message: problem.loginFailureExplanation(host: host)))
        }
    }

    /// Ends the host's login, when the host is removed or disconnected; see `ConversationStore+RemoteHostDisconnect`.
    /// Its tabs' connections and the port forwards going through it end with it; the tabs' CLIs keep running in tmux,
    /// and those tabs are not reconnected on their own. Every window that lists the host refreshes it without the
    /// login, so a host that needs one offers Connect… at once; a disconnected host is not refreshed.
    func closeLogin(on host: String, connections: SSHLoginConnections = .shared) {
        for tab in storesOfEveryWindow.flatMap(\.terminalSessions)
        where tab.host == .ssh(host) && RemoteCLICommandBuilder.goesThroughLogin(tab.command) {
            tab.connectionEndedOnPurpose = true
        }
        SSHPortForwards.shared.loginEnding(on: host)
        connections.disconnect(host)
        for store in storesOfEveryWindow { store.loginClosed(on: host) }
    }

    /// After a refresh of `host`: whether it needs Connect…, and whether its login is still open, as it may have
    /// closed on its own, such as when the Mac slept. Nothing is published when neither changed (PERF-05).
    func noteLoginState(on host: String, refreshProblem: SSHConnectionProblem?, connections: SSHLoginConnections = .shared) {
        let needsLogIn = refreshProblem?.isFixedByLoggingIn == true
        if needsLogIn != sshHostsNeedingLogIn.contains(host) {
            if needsLogIn { sshHostsNeedingLogIn.insert(host) } else { sshHostsNeedingLogIn.remove(host) }
        }
        if !connections.isLoggedIn(host) {
            if sshHostsLoggedIn.contains(host) { sshHostsLoggedIn.remove(host) }
            connections.forgetEndedLogin(of: host)
        }
    }

    func forgetLoginState(on host: String) {
        sshHostsNeedingLogIn.remove(host)
        sshHostsLoggingIn.remove(host)
        sshHostsLoggedIn.remove(host)
    }

    private func loginOpened(on host: String) {
        sshHostsLoggedIn.insert(host)
        sshHostsNeedingLogIn.remove(host)
        if remoteHostList.hosts.contains(host) { refreshRemoteHost(host) }
    }

    private func loginClosed(on host: String) {
        sshHostsLoggedIn.remove(host)
        if remoteHostList.hosts.contains(host) { refreshRemoteHost(host) }
    }

    /// This window's store also when it is not in the registry, as in tests.
    var storesOfEveryWindow: [ConversationStore] {
        let stores = windowRegistry.stores
        return stores.contains { $0 === self } ? stores : stores + [self]
    }
}
