import SwiftUI

/// The app's animations, so the same kind of change moves at the same pace everywhere.
enum ThemeMotion {
    /// A disclosure chevron turning as its group opens or closes.
    static let disclosure: Animation = .easeOut(duration: 0.12)
    /// Tabs, groups, and pinned rows sliding into their new places.
    static let slide: Animation = .easeOut(duration: 0.15)
}
