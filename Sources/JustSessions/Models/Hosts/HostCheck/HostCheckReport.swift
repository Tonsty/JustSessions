import Foundation

/// What Check this host… found: this Mac's side first, so a report pasted into an issue says which app, macOS, and
/// `ssh` it came from, then each finding on the host.
struct HostCheckReport: Equatable, Sendable {
    let host: String
    let checkedAt: Date
    /// Such as "JustSessions 1.2.10 · macOS 26.0.1 · OpenSSH_10.0p2".
    let thisMacSummary: String
    let findings: [HostCheckFinding]

    var problemCount: Int { findings.count { $0.status == .problem } }
    var warningCount: Int { findings.count { $0.status == .warning } }

    /// Problems, then warnings, then the rest, each in the order they were checked, so what to fix comes first.
    var findingsMostImportantFirst: [HostCheckFinding] {
        findings.filter { $0.status == .problem }
            + findings.filter { $0.status == .warning }
            + findings.filter { $0.status != .problem && $0.status != .warning }
    }

    /// For Copy report: plain text that reads the same in an issue, a chat, or an email.
    var plainText: String {
        var lines = [
            AppLocalization.string("JustSessions host check: \(host)"),
            checkedAt.formatted(date: .numeric, time: .shortened),
            AppLocalization.string("This Mac: \(thisMacSummary)"),
            "",
        ]
        for finding in findingsMostImportantFirst {
            lines.append("[\(Self.label(for: finding.status))] \(finding.title): \(finding.summary)")
            if let hostOutput = finding.hostOutput, !hostOutput.isEmpty {
                lines.append("    " + AppLocalization.string("\(host) printed:"))
                lines += hostOutput.split(separator: "\n", omittingEmptySubsequences: false).map { "      \($0)" }
            }
            if let command = finding.commandToRunYourself {
                lines.append("    " + AppLocalization.string("Run it yourself: \(command)"))
            }
        }
        return lines.joined(separator: "\n") + "\n"
    }

    static func label(for status: HostCheckFinding.Status) -> String {
        switch status {
        case .passed: AppLocalization.string("OK")
        case .note: AppLocalization.string("Note")
        case .warning: AppLocalization.string("Warning")
        case .problem: AppLocalization.string("Problem")
        }
    }
}
