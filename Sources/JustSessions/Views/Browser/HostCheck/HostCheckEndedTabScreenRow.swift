import SwiftUI

/// The last lines of the ended tab Check host was started from, under the report's findings, as Copy report ends with
/// them. See `TerminalSession.shownTextForHostCheck`.
struct HostCheckEndedTabScreenRow: View {
    let screenText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("What the tab showed when it ended:")
                .font(ThemeFont.detail)
                .foregroundStyle(ThemePalette.tertiaryText)
            HostCheckMonospacedText(text: screenText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
