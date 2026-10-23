import SwiftUI

/// The reader's bookmark letters by entry ID. Only `TranscriptBookmarkMarker` reads it, so a new bookmark redraws markers
/// and leaves the entries, their layout, and their text alone.
struct TranscriptBookmarkLetters: Equatable {
    private(set) var lettersByEntryID: [Int: String] = [:]

    init(_ bookmarks: [MessageBookmark] = []) {
        lettersByEntryID = Dictionary(bookmarks.map { ($0.entryID, $0.letter) }, uniquingKeysWith: { first, _ in first })
    }

    func letter(forEntryID entryID: Int) -> String? { lettersByEntryID[entryID] }
}

extension EnvironmentValues {
    @Entry var transcriptBookmarkLetters = TranscriptBookmarkLetters()
}

/// A bookmarked message's letter in the transcript's 24-point gutter, beside its first line. Inert to the pointer.
struct TranscriptBookmarkMarker: View {
    let entryID: Int
    let topPadding: CGFloat
    @Environment(\.transcriptBookmarkLetters) private var letters

    var body: some View {
        if let letter = letters.letter(forEntryID: entryID) {
            let side = min(InterfaceScale.points(16), 20)   // 20 + 4 fills the 24-point gutter (TranscriptScrollView's padding)
            Text(verbatim: letter)
                .font(ThemeFont.caption.weight(.semibold))
                .foregroundStyle(ThemePalette.secondaryText)
                .frame(width: side, height: side)
                .background(ThemePalette.trackFill, in: RoundedRectangle(.small))
                .padding(.top, topPadding)
                .alignmentGuide(.leading) { $0[.trailing] + 4 }
                .allowsHitTesting(false)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Bookmark \(letter)"))
        }
    }
}
