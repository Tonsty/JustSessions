import Foundation

/// Check this host…: logs in as the app's background commands do, checks the host's shell startup, then asks the host
/// about everything else in one command; see `RemoteHostCheckScript`. A host the app can't log in to is not asked
/// anything more. Runs `ssh` several times, so call it off the main actor.
struct RemoteHostCheck: Sendable {
    /// Room for every CLI's version within its own time limit.
    static let scriptTimeout: TimeInterval = 120

    let runner: RemoteHostCommandRunner
    let connectionCheck: RemoteHostConnectionCheck
    let shellStartupCheck: RemoteShellStartupCheck

    init(
        runner: RemoteHostCommandRunner = RemoteHostCommandRunner(),
        connectionCheck: RemoteHostConnectionCheck = RemoteHostConnectionCheck(),
        shellStartupCheck: RemoteShellStartupCheck = RemoteShellStartupCheck()
    ) {
        self.runner = runner
        self.connectionCheck = connectionCheck
        self.shellStartupCheck = shellStartupCheck
    }

    struct Outcome: Sendable {
        let report: HostCheckReport
        /// For the store to keep, as after Check shell startup; nil when it didn't run or didn't finish.
        let shellStartupResult: RemoteShellStartupCheckResult?
    }

    func check(
        host: String,
        programs: [RemoteHostCheckProgram],
        session: HostCheckSession?,
        providersWithSessions: Set<ConversationProvider>,
        thisMacSummary: String,
        now: () -> Date = Date.init
    ) -> Outcome {
        func outcome(_ findings: [HostCheckFinding], _ shellStartupResult: RemoteShellStartupCheckResult?) -> Outcome {
            Outcome(
                report: HostCheckReport(host: host, checkedAt: now(), thisMacSummary: thisMacSummary, findings: findings),
                shellStartupResult: shellStartupResult
            )
        }

        let connectionProblem = connectionCheck.problem(connectingTo: host)
        var findings = [RemoteHostConnectionFindings.connectionFinding(problem: connectionProblem, host: host)]
        guard connectionProblem == nil else { return outcome(findings, nil) }

        let shellStartupResult = shellStartupCheck.check(host: host)
        let startup = shellStartupResult?.shellStartup ?? RemoteHostShellStartups.shared.startup(on: host)
        findings.append(RemoteHostConnectionFindings.shellStartupFinding(shellStartupResult, host: host, startup: startup))

        let command = RemoteHostCheckScript.command(startup: startup, programs: programs, projectPath: session?.projectPath)
        guard let result = runner.run(host, command, Self.scriptTimeout),
              result.exitStatus != RemoteHostCommandRunner.connectionFailureExitStatus else {
            findings.append(HostCheckFinding(
                id: "script",
                status: .problem,
                title: AppLocalization.string("Host check"),
                summary: AppLocalization.string(
                    "\(host) didn't answer the rest of the check within \(Int(Self.scriptTimeout)) seconds, or the connection dropped."
                )
            ))
            return outcome(findings, shellStartupResult)
        }
        let context = RemoteHostCheckContext(
            host: host,
            shellStartup: startup,
            programs: programs,
            session: session,
            providersWithSessions: providersWithSessions
        )
        findings += RemoteHostCheckFindings.findings(in: RemoteHostCheckOutput(result.output), context: context)
        return outcome(findings, shellStartupResult)
    }
}
