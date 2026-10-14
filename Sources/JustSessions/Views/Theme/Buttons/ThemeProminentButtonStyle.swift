import SwiftUI

/// A view's one primary action, filled with the theme's ink: a sheet's default action, the primary action in Settings
/// and on the onboarding tour's cards, and Check host above a tab its host likely ended. An action that starts a CLI
/// takes `ProviderProminentButtonStyle`. A small or mini control is as tall as a small `QuietBorderedButtonStyle`.
struct ThemeProminentButtonStyle: ButtonStyle {
    @Environment(\.controlSize) private var controlSize

    private var isCompact: Bool { controlSize == .mini || controlSize == .small }
    private var shape: RoundedRectangle { RoundedRectangle(isCompact ? .control : .card) }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font((isCompact ? ThemeFont.detail : ThemeFont.callout).weight(.semibold))
            .foregroundStyle(ThemePalette.inkForeground)
            .padding(.horizontal, isCompact ? 10 : 14)
            .frame(height: isCompact ? 22 : 28)
            .background(shape.fill(ThemePalette.ink))
            .contentShape(shape)
            .modifier(ThemeButtonPressFeedback(isPressed: configuration.isPressed))
    }
}
