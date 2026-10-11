import SwiftUI

/// One short line for the app mark and name, then the notification bell, search, and new session as icons, so the
/// session list gets the height. Search opens into a field across the whole line, and goes back to its icon when
/// closed, or once it is empty and loses focus.
struct SidebarHeader: View {
    /// The window's store, for the bell's list.
    let store: ConversationStore
    @Binding var searchText: String
    var contentMode: SidebarContentMode = .projects
    let onNewSession: () -> Void

    @State private var isSearchOpen = false

    /// A search with text stays open, so the list is never narrowed by a field out of sight.
    private var isSearchShown: Bool {
        isSearchOpen || !searchText.isEmpty
    }

    var body: some View {
        Group {
            if isSearchShown {
                SidebarSearchField(
                    text: $searchText,
                    placeholder: searchLabel,
                    accessibilityLabel: contentMode == .projects
                        ? "Search projects by name or path and sessions by title, ID, or message text"
                        : "Search open tabs by title, project, or host",
                    onClose: closeSearch
                )
                .onboardingTourStop(searchTourStop)
            } else {
                markAndActions
            }
        }
        .frame(height: 46)
    }

    private var markAndActions: some View {
        HStack(spacing: 8) {
            // A sidebar too narrow for the whole name beside the icons shows the mark alone, not a cut-off name.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) {
                    appMark
                    Text("JustSessions")
                        .font(ThemeFont.heading)
                        .lineLimit(1)
                }
                appMark
            }
            Spacer(minLength: 4)
            HStack(spacing: 4) {
                SidebarNotificationBellButton(store: store)
                searchButton
                SidebarNewSessionButton(action: onNewSession)
                    .onboardingTourStop(.newSession)
            }
            .layoutPriority(1)
        }
        .padding(.leading, 18)
        .padding(.trailing, 12)
    }

    private var appMark: some View {
        JustSessionsMark()
            .frame(width: 21, height: 18)
    }

    private var searchButton: some View {
        Button { isSearchOpen = true } label: {
            Image(systemName: "magnifyingglass")
                .frame(width: 24, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(ThemePlainButtonStyle())
        .help(searchLabel)
        .accessibilityLabel(searchLabel)
        .onboardingTourStop(searchTourStop)
    }

    /// Search's tip is about projects and sessions, so it waits while search looks through open tabs. It moves to the
    /// field when the field opens.
    private var searchTourStop: OnboardingTourStop? {
        contentMode == .projects ? .searchSessions : nil
    }

    private var searchLabel: LocalizedStringKey {
        contentMode == .projects ? "Search projects and sessions" : "Search open tabs"
    }

    private func closeSearch() {
        searchText = ""
        isSearchOpen = false
    }
}
