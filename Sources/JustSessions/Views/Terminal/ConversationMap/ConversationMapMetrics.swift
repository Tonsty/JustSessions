import CoreGraphics

/// The conversation map's sizes (TAB-09). Sizes that hold marks or letters scale with the interface size; spacing doesn't.
enum ConversationMapMetrics {
    @MainActor static var columnWidth: CGFloat { columnWidth(at: InterfaceScale.factor) }
    @MainActor static var naturalRowPitch: CGFloat { naturalRowPitch(at: InterfaceScale.factor) }
    @MainActor static var chipSide: CGFloat { chipSide(at: InterfaceScale.factor) }
    @MainActor static var minimumRowPitch: CGFloat { minimumRowPitch(at: InterfaceScale.factor) }
    /// TAB-08's 6 points, so the first row lines up with the terminal's.
    static let verticalInset: CGFloat = 6
    static let leadingInset: CGFloat = 6
    static let chipGap: CGFloat = 3

    /// Wide enough for a bookmark's label of about 14 characters beside the start of its message's lines.
    @MainActor static func columnWidth(at factor: CGFloat) -> CGFloat { InterfaceScale.points(110, at: factor) }
    @MainActor static func naturalRowPitch(at factor: CGFloat) -> CGFloat { InterfaceScale.points(3, at: factor) }
    /// A third of the natural pitch: a longer conversation scrolls rather than squeezing further (TAB-10).
    @MainActor static func minimumRowPitch(at factor: CGFloat) -> CGFloat { InterfaceScale.points(1, at: factor) }
    @MainActor static func chipSide(at factor: CGFloat) -> CGFloat { InterfaceScale.points(14, at: factor) }
    /// The chip's text: `ThemeFont.caption`, semibold.
    @MainActor static func chipFontSize(at factor: CGFloat) -> CGFloat { InterfaceScale.points(10, at: factor) }
    /// Space either side of a label in its chip.
    @MainActor static func chipPadding(at factor: CGFloat) -> CGFloat { InterfaceScale.points(4, at: factor) }
    /// A label's chip leaves the first 12 points of its message's lines showing.
    @MainActor static func labelChipMaximumWidth(at factor: CGFloat) -> CGFloat {
        columnWidth(at: factor) - leadingInset - chipGap - InterfaceScale.points(12, at: factor)
    }
    /// The leading edge's bar while the rows scroll.
    @MainActor static func scrollThumbWidth(at factor: CGFloat) -> CGFloat { InterfaceScale.points(2, at: factor) }
    @MainActor static func scrollThumbMinimumLength(at factor: CGFloat) -> CGFloat { InterfaceScale.points(16, at: factor) }
    /// How far one notch of a mouse wheel, which reports lines rather than points, scrolls.
    static let wheelLineHeight: CGFloat = 16
}
