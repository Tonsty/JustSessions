import Observation
import SwiftUI

/// The hovered block, read only by the card's and band's own bodies, so hovering redraws neither the Canvas nor the terminal.
@MainActor
@Observable
final class ConversationMapHover {
    struct Card: Equatable {
        let blockIndex: Int
        /// The outline's revision it was built from: the same index in a newer outline can be a grown or another block.
        let revision: Int
        let speaker: String
        let timestamp: Date?
        let snippet: String
        let letter: String?
        /// The bookmark's label and tags (RDR-51), which the card shows above and below its message's first words.
        var label: String? = nil
        var tags: [String] = []
        /// The card's top in the map column, kept inside its height.
        let top: CGFloat
        let bandMinY: CGFloat
        let bandHeight: CGFloat
        /// The card hangs left of the column, over the terminal.
        let trailingInset: CGFloat
    }

    private(set) var card: Card?
    /// Where the pointer was when the card was built, so an outline update can rebuild it there.
    @ObservationIgnored private(set) var point: CGPoint?

    func show(_ card: Card, at point: CGPoint) {
        self.point = point
        if self.card != card { self.card = card }
    }

    func hide() {
        point = nil
        if card != nil { card = nil }
    }
}

/// What a click on the hovered block opens, in a card like a tab's (TabHoverCardSurface), never a `.help` tooltip (TAB-10).
struct ConversationMapHoverCard: View {
    let hover: ConversationMapHover

    var body: some View {
        if let card = hover.card {
            TabHoverCardSurface {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(verbatim: card.speaker)
                            .font(ThemeFont.callout.weight(.semibold))
                            .foregroundStyle(ThemePalette.ink)
                        if let timestamp = card.timestamp {
                            // As the reader shows a message's time (TranscriptEntryView.swift).
                            Text(timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(ThemeFont.caption)
                                .foregroundStyle(ThemePalette.secondaryText)
                        }
                        Spacer(minLength: 0)
                        if let letter = card.letter {
                            Text("Bookmark \(letter)")
                                .font(ThemeFont.caption)
                                .foregroundStyle(ThemePalette.secondaryText)
                        }
                    }
                    if let label = card.label {
                        Text(verbatim: label)
                            .font(ThemeFont.callout.weight(.semibold))
                            .foregroundStyle(ThemePalette.ink)
                            .lineLimit(2)
                    }
                    if !card.snippet.isEmpty {
                        Text(verbatim: card.snippet)
                            .font(ThemeFont.callout)
                            .foregroundStyle(card.label == nil ? ThemePalette.ink : ThemePalette.secondaryText)
                            .lineLimit(3)
                    }
                    MessageBookmarkTagList(tags: card.tags)
                }
            }
            .padding(.trailing, card.trailingInset)
            .offset(y: card.top)
            .allowsHitTesting(false)
            // The map's own element and actions say this.
            .accessibilityHidden(true)
        }
    }
}

/// The hovered block's band, drawn under the bars in the hover band color.
struct ConversationMapHoverBand: View {
    let hover: ConversationMapHover
    let color: UInt32

    var body: some View {
        if let card = hover.card {
            Rectangle()
                .fill(Color(hexValue: color))
                .frame(height: card.bandHeight)
                .offset(y: card.bandMinY)
                .allowsHitTesting(false)
        }
    }
}
