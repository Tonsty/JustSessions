import Foundation
import Testing
@testable import JustSessions

struct HostCheckReportTests {
    @Test func plainTextStartsWithThisMacAndShowsWhatToFixFirst() {
        let report = HostCheckReport(
            host: "devbox",
            checkedAt: Date(timeIntervalSince1970: 0),
            thisMacSummary: "JustSessions 1.2.10 · macOS 26.0.1 · OpenSSH_10.3p1",
            findings: [
                HostCheckFinding(id: "rsync", status: .passed, title: "rsync", summary: "Copies devbox's sessions to this Mac."),
                HostCheckFinding(
                    id: "cli-opencode",
                    status: .warning,
                    title: "OpenCode",
                    summary: "Found at /usr/bin/opencode, but it failed when asked for its version.",
                    hostOutput: "env: node: No such file or directory\nsecond line",
                    commandToRunYourself: "ssh devbox 'command -v opencode'"
                ),
            ]
        )

        let lines = report.plainText.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        #expect(lines[0] == "JustSessions host check: devbox")
        #expect(lines[2] == "This Mac: JustSessions 1.2.10 · macOS 26.0.1 · OpenSSH_10.3p1")
        // The warning comes first, though it was checked last.
        #expect(Array(lines[4...]) == [
            "[Warning] OpenCode: Found at /usr/bin/opencode, but it failed when asked for its version.",
            "    devbox printed:",
            "      env: node: No such file or directory",
            "      second line",
            "    Run it yourself: ssh devbox 'command -v opencode'",
            "[OK] rsync: Copies devbox's sessions to this Mac.",
            "",
        ])
        #expect(report.problemCount == 0)
        #expect(report.warningCount == 1)
    }

    @Test func problemsComeBeforeWarningsAndTheRestKeepTheirOrder() {
        let statuses: [HostCheckFinding.Status] = [.passed, .warning, .note, .problem, .passed, .warning]
        let report = HostCheckReport(
            host: "devbox",
            checkedAt: Date(timeIntervalSince1970: 0),
            thisMacSummary: "",
            findings: statuses.enumerated().map { index, status in
                HostCheckFinding(id: "\(index)", status: status, title: "", summary: "")
            }
        )
        #expect(report.findingsMostImportantFirst.map(\.id) == ["3", "1", "5", "0", "2", "4"])
    }
}
