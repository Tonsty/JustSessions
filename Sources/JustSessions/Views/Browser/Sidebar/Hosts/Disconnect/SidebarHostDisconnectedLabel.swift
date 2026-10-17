import SwiftUI

/// Says a disconnected SSH host is, where its heading otherwise shows when it was last copied; see
/// `ConversationStore+RemoteHostDisconnect`.
struct SidebarHostDisconnectedLabel: View {
    let host: SessionHost

    var body: some View {
        Text("Disconnected")
            .font(ThemeFont.caption)
            .foregroundStyle(ThemePalette.tertiaryText)
            .fixedSize()
            .accessibilityLabel(Text("\(host.displayName) is disconnected"))
    }
}
