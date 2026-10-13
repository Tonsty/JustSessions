import SwiftUI

/// The warning after a host's name while its last refresh has failed; its tooltip says why. It sits apart from the
/// refresh status, which an SSH host's ⋯ takes the place of under the pointer, so the pointer can rest on it. Clicking
/// an SSH host's warning checks the host, which shows what on it failed; see `ConversationStore+HostCheck`.
struct SidebarHostRefreshFailureWarning: View {
    let host: SessionHost
    let failureMessage: String
    /// Nil for this Mac.
    let onCheckHost: (() -> Void)?

    var body: some View {
        if let onCheckHost {
            Button(action: onCheckHost) { icon }
                .buttonStyle(ThemePressButtonStyle())
                .help(AppLocalization.string("\(failureMessage) Click to check \(host.displayName)."))
                .accessibilityLabel("\(host.displayName) could not be refreshed: \(failureMessage)")
                .accessibilityHint("Checks this host")
        } else {
            icon
                .help(failureMessage)
                .accessibilityLabel("\(host.displayName) could not be refreshed: \(failureMessage)")
        }
    }

    private var icon: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundStyle(ThemePalette.warning)
            .frame(width: 14, height: 20)
            .contentShape(Rectangle())
    }
}
