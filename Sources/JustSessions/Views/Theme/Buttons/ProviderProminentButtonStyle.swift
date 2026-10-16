import SwiftUI

/// A filled button in one CLI's hue, for the action that starts that CLI (Resume, Start session). It is flat like
/// `ThemeProminentButtonStyle` and differs from it only in color.
struct ProviderProminentButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(ThemeFont.callout.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .frame(height: InterfaceScale.points(28))
            .background(RoundedRectangle(.card).fill(tint))
            .contentShape(RoundedRectangle(.card))
            .modifier(ThemeButtonPressFeedback(isPressed: configuration.isPressed))
    }
}
