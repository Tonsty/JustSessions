import SwiftUI

/// The header's bell, which lists the sessions waiting for you; see `ConversationStore+NotificationBell`. A blue dot,
/// the unseen-turn hue, marks it while the list is not empty.
struct SidebarNotificationBellButton: View {
    let store: ConversationStore
    @Environment(\.locale) private var locale
    @Environment(\.appTheme) private var appTheme
    @Environment(\.colorScheme) private var colorScheme
    @State private var isShowingList = false

    var body: some View {
        let entries = store.notificationBellEntries
        Button { isShowingList.toggle() } label: {
            Image(systemName: "bell")
                .frame(width: 24, height: 24)
                .overlay(alignment: .topTrailing) {
                    if !entries.isEmpty {
                        Circle()
                            .fill(ThemePalette.unseenTurn)
                            .frame(width: 6, height: 6)
                            .offset(x: -4, y: 4)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(ThemePlainButtonStyle())
        .help("Waiting for you")
        .accessibilityLabel("Waiting for you")
        .accessibilityValue(Text("\(entries.count) sessions"))
        .popover(isPresented: $isShowingList, arrowEdge: .bottom) {
            NotificationBellList(entries: entries) { entry in
                isShowingList = false
                store.showSession(fromNotificationBell: entry)
            }
            // A native popover can start with its own presentation environment.
            .environment(\.locale, locale)
            .environment(\.appTheme, appTheme)
            .environment(\.colorScheme, colorScheme)
            .onExitCommand { isShowingList = false }
        }
        .onDisappear { isShowingList = false }
    }
}
