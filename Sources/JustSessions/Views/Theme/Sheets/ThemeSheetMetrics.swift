import CoreGraphics

/// The margins and spacing `ThemeSheetLayout` gives every sheet. Its widths follow the interface size, so a sheet's text
/// wraps the same at every size; the margins and spacing don't.
@MainActor
enum ThemeSheetMetrics {
    /// Around the sheet's content, on every side.
    nonisolated static let margin: CGFloat = 20
    /// Between the title and the line under it.
    nonisolated static let titleToIntroSpacing: CGFloat = 6
    /// Between the title block, each section of the content, and the footer.
    nonisolated static let sectionSpacing: CGFloat = 16
    /// A sheet with one field or a short list.
    static var compactWidth: CGFloat { InterfaceScale.points(480) }
    /// A sheet with several sections, such as New session.
    static var regularWidth: CGFloat { InterfaceScale.points(520) }
    /// A sheet that shows what commands printed, such as Check this host….
    static var wideWidth: CGFloat { InterfaceScale.points(640) }
}
