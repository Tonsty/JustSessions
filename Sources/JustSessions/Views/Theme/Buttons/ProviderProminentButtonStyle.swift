import SwiftUI

/// A filled button in one CLI's hue, for the action that starts that CLI (Resume, Start session).
struct ProviderProminentButtonStyle: ButtonStyle {
    let tint: Color
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ThemeFont.callout.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: 28)
            .background(
                RoundedRectangle(.card)
                    .fill(tint.gradient)
                    .shadow(color: tint.opacity(isEnabled ? 0.3 : 0), radius: 3, y: 1)
            )
            .contentShape(RoundedRectangle(.card))
            .modifier(ThemeButtonPressFeedback(isPressed: configuration.isPressed))
    }
}
