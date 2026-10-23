import CoreGraphics

/// The conversation map's sizes (TAB-09). Sizes that hold marks or letters scale with the interface size; spacing doesn't.
enum ConversationMapMetrics {
    @MainActor static var columnWidth: CGFloat { columnWidth(at: InterfaceScale.factor) }
    @MainActor static var naturalRowPitch: CGFloat { naturalRowPitch(at: InterfaceScale.factor) }
    @MainActor static var chipSide: CGFloat { chipSide(at: InterfaceScale.factor) }
    /// TAB-08's 6 points, so the first row lines up with the terminal's.
    static let verticalInset: CGFloat = 6
    static let leadingInset: CGFloat = 6
    static let chipGap: CGFloat = 3

    @MainActor static func columnWidth(at factor: CGFloat) -> CGFloat { InterfaceScale.points(70, at: factor) }
    @MainActor static func naturalRowPitch(at factor: CGFloat) -> CGFloat { InterfaceScale.points(3, at: factor) }
    @MainActor static func chipSide(at factor: CGFloat) -> CGFloat { InterfaceScale.points(14, at: factor) }
}
