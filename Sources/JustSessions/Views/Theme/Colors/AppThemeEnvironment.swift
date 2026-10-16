import SwiftUI

extension EnvironmentValues {
    /// The theme `ThemePalette` colors are drawn in.
    @Entry var appTheme = ResolvedAppTheme(.justSessions)
}

extension View {
    /// Draws this window's `ThemePalette` colors in the theme chosen in Settings, and redraws them when it changes. Its
    /// text that names no font, and the system's own controls, follow the interface size too; see `InterfaceSizeStore`.
    func appTheme(from themeStore: AppThemeStore) -> some View {
        modifier(ChosenAppTheme(themeStore: themeStore))
    }
}

private struct ChosenAppTheme: ViewModifier {
    @ObservedObject var themeStore: AppThemeStore

    func body(content: Content) -> some View {
        content
            .tint(ThemePalette.ink)
            .environment(\.appTheme, themeStore.resolvedTheme)
            // `ThemeFont.body` is the system's own 13 points at the default interface size.
            .font(ThemeFont.body)
            .controlSize(InterfaceScale.controlSize)
    }
}
