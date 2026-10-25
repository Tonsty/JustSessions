import SwiftUI

/// A labelled bookmark's label above its message in the reader (RDR-51), as the conversation map shows it in place of
/// the letter (TAB-10): beside who wrote the message where it starts a turn, else on a line of its own. The gutter keeps
/// the letter, which has no room for a label at a reading window's default width. This view alone reads the bookmarks
/// inside an entry, so a label added, changed, or removed re-evaluates these small views, never `TranscriptEntryView`'s
/// body, and lays the entries out again only when a line of its own comes or goes (PERF-73).
struct TranscriptBookmarkLabel: View {
    @Environment(\.transcriptSearchEntryIndex) private var entryID
    @Environment(\.transcriptBookmarkLetters) private var letters

    var body: some View {
        if let label = letters.bookmark(forEntryID: entryID)?.label {
            HStack(spacing: 4) {
                Image(systemName: "bookmark.fill")
                    .imageScale(.small)
                Text(verbatim: label)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .font(ThemeFont.caption.weight(.semibold))
            .foregroundStyle(ThemePalette.secondaryText)
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .background(ThemePalette.trackFill, in: RoundedRectangle(.small))
            // The letter's own label reads it, with the tags (RDR-51).
            .accessibilityHidden(true)
        }
    }
}
