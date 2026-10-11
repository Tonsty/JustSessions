import SwiftUI

/// A view's one primary action, filled with the theme's ink: a sheet's default action, and the primary action in
/// Settings and on the onboarding tour's cards. An action that starts a CLI takes `ProviderProminentButtonStyle`.
struct ThemeProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ThemeFont.callout.weight(.semibold))
            .foregroundStyle(ThemePalette.inkForeground)
            .padding(.horizontal, 14)
            .frame(height: 28)
            .background(RoundedRectangle(.card).fill(ThemePalette.ink))
            .contentShape(RoundedRectangle(.card))
            .modifier(ThemeButtonPressFeedback(isPressed: configuration.isPressed))
    }
}
