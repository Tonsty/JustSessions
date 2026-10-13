import CoreGraphics

/// The margins and spacing `ThemeSheetLayout` gives every sheet.
enum ThemeSheetMetrics {
    /// Around the sheet's content, on every side.
    static let margin: CGFloat = 20
    /// Between the title and the line under it.
    static let titleToIntroSpacing: CGFloat = 6
    /// Between the title block, each section of the content, and the footer.
    static let sectionSpacing: CGFloat = 16
    /// A sheet with one field or a short list.
    static let compactWidth: CGFloat = 480
    /// A sheet with several sections, such as New session.
    static let regularWidth: CGFloat = 520
    /// A sheet that shows what commands printed, such as Check this host….
    static let wideWidth: CGFloat = 640
}
