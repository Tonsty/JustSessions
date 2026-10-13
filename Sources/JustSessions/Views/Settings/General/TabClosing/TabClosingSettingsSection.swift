import SwiftUI

/// The closing part of the General tab: what closing a tab does when its CLI can keep running in tmux, one choice per
/// host, and what closing a plain terminal does. Don't ask again in the close dialog sets the same choices.
struct TabClosingSettingsSection: View {
    /// This Mac first, then the SSH hosts, as the sidebar lists them.
    let hosts: [SessionHost]
    @ObservedObject var tabCloseChoiceSettingsStore: TabCloseChoiceSettingsStore
    @ObservedObject var plainTerminalCloseChoiceSettingsStore: PlainTerminalCloseChoiceSettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Closing tabs")
                    .font(ThemeFont.heading)
                HelpPopoverButton(
                    title: "Closing tabs",
                    explanation: "Each host has its own choice for tabs whose CLI can keep running in tmux there. A terminal's shell always ends with its tab. Don't ask again in the close dialog sets these too."
                )
                .accessibilityIdentifier("settings.help.closingTabs")
            }
            Text("When you close a CLI tab")
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                ForEach(hosts) { host in
                    HostTabCloseChoiceRow(host: host, tabCloseChoiceSettingsStore: tabCloseChoiceSettingsStore)
                }
            }
            .padding(.leading, 16)
            Picker("When you close a terminal", selection: Binding(
                get: { plainTerminalCloseChoiceSettingsStore.choice },
                set: { plainTerminalCloseChoiceSettingsStore.setChoice($0) }
            )) {
                Text("Ask each time").tag(PlainTerminalCloseChoice.askEachTime)
                Text("Close without asking").tag(PlainTerminalCloseChoice.closeWithoutAsking)
            }
            .fixedSize()
            .accessibilityIdentifier("settings.plainTerminalCloseChoice")
        }
    }
}
