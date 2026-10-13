import AppKit
import SwiftUI

/// Check this host…: what on an SSH host could keep its sessions from working, each finding with what the host
/// printed and a command to run in your own Terminal, so you can see a problem is on the host and not in the app.
/// Copy report puts it all as text on the clipboard, for an issue or for whoever runs the host. See
/// `ConversationStore+HostCheck`.
struct HostCheckSheet: View {
    let store: ConversationStore
    /// The check as the sheet opened; the store's has its report once the check finishes.
    let presentedState: HostCheckSheetState
    @Environment(\.dismiss) private var dismiss
    @State private var hasCopiedReport = false

    /// The findings scroll in a fixed height, so the sheet keeps its size from the progress to the report.
    private static let findingsHeight: CGFloat = 420

    private var state: HostCheckSheetState {
        store.hostCheck ?? presentedState
    }

    var body: some View {
        ThemeSheetLayout(
            title: Text("Check \(state.host)"),
            intro: Text(
                "Runs on \(state.host) what JustSessions runs there. When a command below fails the same way in your own Terminal, the problem is on \(state.host)."
            ),
            width: ThemeSheetMetrics.wideWidth
        ) {
            Group {
                if let report = state.report {
                    reportView(report)
                } else {
                    VStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("Checking \(state.host)…")
                            .font(ThemeFont.callout)
                            .foregroundStyle(ThemePalette.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(height: Self.findingsHeight)
        } footer: {
            Button(hasCopiedReport ? "Copied" : "Copy report", systemImage: hasCopiedReport ? "checkmark" : "doc.on.doc") {
                guard let report = state.report else { return }
                NSPasteboard.general.clearContents()
                hasCopiedReport = NSPasteboard.general.setString(report.plainText, forType: .string)
            }
            .disabled(state.isChecking)
            .help("Copy the report as text, for an issue or for whoever runs the host")
            Button("Check again", systemImage: "arrow.clockwise") { store.checkShownHostAgain() }
                .disabled(state.isChecking)
            Spacer()
            Button("Done") { dismiss() }
                .buttonStyle(ThemeProminentButtonStyle())
                .keyboardShortcut(.defaultAction)
        }
        .onChange(of: state.runID) { hasCopiedReport = false }
    }

    private func reportView(_ report: HostCheckReport) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                HostCheckStatusIcon(status: overallStatus(of: report))
                Text(verbatim: verdict(of: report))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(ThemeFont.body.weight(.medium))
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(report.findingsMostImportantFirst) { finding in
                        HostCheckFindingRow(finding: finding, host: report.host)
                        if finding.id != report.findingsMostImportantFirst.last?.id {
                            ThemeDivider()
                        }
                    }
                }
            }
            .background(ThemePalette.raisedSurface, in: RoundedRectangle(.card))
            .overlay(RoundedRectangle(.card).stroke(ThemePalette.hairline, lineWidth: 1))
            .clipShape(RoundedRectangle(.card))
            Text("This Mac: \(report.thisMacSummary)")
                .font(ThemeFont.detail)
                .foregroundStyle(ThemePalette.tertiaryText)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
    }

    private func overallStatus(of report: HostCheckReport) -> HostCheckFinding.Status {
        if report.problemCount > 0 { return .problem }
        if report.warningCount > 0 { return .warning }
        return .passed
    }

    private func verdict(of report: HostCheckReport) -> String {
        if report.problemCount > 0 {
            return AppLocalization.string("Found something on \(report.host) that keeps sessions from working; see the problems below.")
        }
        if report.warningCount > 0 {
            return AppLocalization.string("Sessions on \(report.host) can work, but see the warnings below.")
        }
        return AppLocalization.string("Found nothing on \(report.host) that keeps sessions from working.")
    }
}
