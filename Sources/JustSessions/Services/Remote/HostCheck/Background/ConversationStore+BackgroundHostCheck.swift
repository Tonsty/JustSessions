import Foundation

/// The app checks each SSH host on its own, as Check this host… would, so a problem there shows on the host's
/// heading before a session fails; `HostBackgroundChecker` decides when. Every check's report is kept across launches
/// and shown in every window; the heading warns of its problems, see `SidebarHostCheckProblemWarning`.
extension ConversationStore {
    /// A tab on an SSH host whose CLI ended with an error this soon after it started asks for its host to be checked,
    /// as when tmux there can't reach its server and the tab ends at once.
    static let cliEndedSoonAfterStartingInterval: TimeInterval = 30

    /// Starts a check of the host that shows no sheet; its task ends once the report is kept.
    @discardableResult
    func checkHostInBackground(_ host: String) -> Task<Void, Never>? {
        guard remoteHostList.hosts.contains(host) else { return nil }
        let programs = RemoteHostCheckProgram.all { customStartCommand(for: $0, on: .ssh(host)) }
        let providersWithSessions = Set(conversations.filter { $0.host == .ssh(host) }.map(\.provider))
        let keptShellStartupResult = shellStartupCheck(on: host)
        let check = remoteHostCheck
        return Task.detached(priority: .utility) {
            let outcome = check.check(
                host: host,
                programs: programs,
                session: nil,
                providersWithSessions: providersWithSessions,
                thisMacSummary: HostCheckThisMacSummary.current(),
                keptShellStartupResult: keptShellStartupResult,
                checksShellStartup: false
            )
            await self.applyHostCheckOutcome(outcome, host: host)
        }
    }

    /// Whether this window shows a check of the host that is still running.
    func isShowingRunningHostCheck(of host: String) -> Bool {
        hostCheck?.host == host && hostCheck?.isChecking == true
    }

    /// Saves over what is saved, which another window may have changed, and shows it in every window.
    func keepHostCheck(_ check: KeptHostCheck?, on host: String) {
        var checks = KeptHostChecks.load(from: userDefaults)
        checks.setCheck(check, for: host)
        checks.save(to: userDefaults)
        for store in windowRegistry.stores + [self] where store.keptHostChecks != checks {
            store.keptHostChecks = checks
        }
    }

    /// From a refresh's status, which this window made or another window shared.
    func setTmuxServerProblem(_ problem: String?, on host: String) {
        guard remoteHostList.hosts.contains(host), tmuxServerProblemsByHost[host] != problem else { return }
        tmuxServerProblemsByHost[host] = problem
    }

    /// When the host is removed.
    func forgetHostChecks(on host: String) {
        keepHostCheck(nil, on: host)
        tmuxServerProblemsByHost.removeValue(forKey: host)
        hostsAskingForBackgroundCheck.remove(host)
    }

    /// What the warning on the host's heading says, or nil when it shows none: the problems of the host's last check,
    /// or what the last refresh's tmux printed.
    func hostCheckProblemMessage(on host: String) -> String? {
        if let tmuxServerProblem = tmuxServerProblemsByHost[host] {
            return AppLocalization.string(
                "tmux on \(host) can't reach the tmux server running there, so its sessions can't be opened: \(tmuxServerProblem)"
            )
        }
        guard let firstProblem = keptHostChecks.check(for: host)?.report.hostProblems.first else { return nil }
        return "\(firstProblem.title): \(firstProblem.summary)"
    }

    /// See `followTabStateChanges()`.
    func noteCLIEnded(in tab: TerminalSession) {
        guard let host = tab.host.sshDestination, !tab.isPlainTerminal,
              let exitCode = tab.exitCode, exitCode != 0,
              let startedAt = tab.startedAt,
              Date.now.timeIntervalSince(startedAt) < Self.cliEndedSoonAfterStartingInterval else { return }
        hostsAskingForBackgroundCheck.insert(host)
    }
}
