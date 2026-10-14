import SwiftUI

/// The warning after an SSH host's name while the host's last check found a problem, or its last refresh found that
/// tmux there can't reach its server, though the refresh itself worked; its tooltip says what. Clicking it shows the
/// check's report, from where Fix with agent… can start an agent to fix it. See `ConversationStore+BackgroundHostCheck`.
struct SidebarHostCheckProblemWarning: View {
    let host: SessionHost
    let problemMessage: String
    let onShowHostCheck: () -> Void

    var body: some View {
        Button(action: onShowHostCheck) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(ThemePalette.warning)
                .frame(width: 14, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(ThemePressButtonStyle())
        .help(AppLocalization.string("\(problemMessage) Click to see what the check found."))
        .accessibilityLabel("\(host.displayName) has a problem: \(problemMessage)")
        .accessibilityHint("Shows what the check found")
    }
}
