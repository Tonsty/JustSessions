import SwiftUI

/// Under a session's title while searching: the bookmarks the search found by label or tag (SBF-05), then the text around
/// its first match in its messages (SBF-02).
struct SidebarSessionMatchDetail: View {
    let bookmarks: [MessageBookmark]
    let messageMatch: SessionMessageMatch?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if !bookmarks.isEmpty { SidebarSessionBookmarkMatch(bookmarks: bookmarks) }
            if let messageMatch { SidebarSessionMessageSnippet(snippet: messageMatch.snippet) }
        }
    }
}

/// The first bookmark found, `a · Label #tag`, and how many more the session has; clicking the row opens the first.
struct SidebarSessionBookmarkMatch: View {
    let bookmarks: [MessageBookmark]

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bookmark.fill")
                .font(ThemeFont.glyph(.control))
                .accessibilityHidden(true)
            Text(verbatim: Self.text(of: [bookmarks[0]]) ?? "")
                .lineLimit(1)
                .truncationMode(.tail)
            if bookmarks.count > 1 {
                Text("+\(bookmarks.count - 1)")
                    .layoutPriority(1)
            }
        }
        .font(ThemeFont.detail)
        .foregroundStyle(ThemePalette.secondaryText)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// `a · Label #tag #tag` for each, or nil for none; also the row's VoiceOver value.
    static func text(of bookmarks: [MessageBookmark]) -> String? {
        guard !bookmarks.isEmpty else { return nil }
        return bookmarks.map { bookmark in
            let tags = bookmark.tags.isEmpty ? "" : " " + MessageBookmarkDetails.typedText(of: bookmark.tags)
            return "\(bookmark.letter) · \(bookmark.label ?? bookmark.menuSnippet)\(tags)"
        }.joined(separator: ", ")
    }
}
