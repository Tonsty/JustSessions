import SwiftUI

/// A disclosure group's title that opens and closes it, as its chevron does. On macOS only the system chevron responds
/// to clicks, so the title alone would do nothing.
struct ThemeDisclosureTitleButton<Title: View>: View {
    @Binding var isExpanded: Bool
    @ViewBuilder let title: Title

    var body: some View {
        Button {
            withAnimation { isExpanded.toggle() }
        } label: {
            title
        }
        .buttonStyle(ThemePlainButtonStyle(showsHover: false))
    }
}
