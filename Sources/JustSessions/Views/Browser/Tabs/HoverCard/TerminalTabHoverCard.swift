import SwiftUI

/// A tab's hover card: its whole title, where it runs and with which CLI, and what the CLI is doing, kept current
/// while the card shows.
struct TerminalTabHoverCard: View {
    @ObservedObject var session: TerminalSession
    let projectDisplayName: String
    /// Named once SSH hosts are added, whichever host the tab runs on.
    let hostDisplayName: String?

    var body: some View {
        TabHoverCardSurface {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: session.displayTitle)
                    .font(ThemeFont.heading)
                    .foregroundStyle(ThemePalette.ink)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: location)
                    .font(ThemeFont.detail)
                    .foregroundStyle(ThemePalette.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
                ThemeDivider()
                    .padding(.vertical, 4)
                HStack(spacing: 6) {
                    SessionStatusIndicator(status: session.runStatus)
                    Text(verbatim: session.runStatus.summary)
                        .lineLimit(1)
                }
                .font(ThemeFont.detail)
                .foregroundStyle(ThemePalette.secondaryText)
            }
        }
    }

    /// Such as "JustSessions · Claude Code", with the host after the project once SSH hosts are added.
    private var location: String {
        [projectDisplayName, hostDisplayName, session.provider?.rawValue ?? "Terminal"]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}
