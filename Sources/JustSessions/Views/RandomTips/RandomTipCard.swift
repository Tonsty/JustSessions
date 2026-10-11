import SwiftUI

/// One random tip: a "Tip" heading with Next tip and close buttons, then the tip. Its right-click menu also turns tips
/// off, as Settings → Help does.
struct RandomTipCard: View {
    let tip: RandomTip
    let onShowNextTip: () -> Void
    let onHide: () -> Void
    let onTurnOffTips: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 0) {
                Label("Tip", systemImage: "lightbulb")
                    .font(ThemeFont.detail.weight(.medium))
                    .foregroundStyle(ThemePalette.secondaryText)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 4)
                RandomTipCardButton(title: "Next tip", systemImage: "arrow.right", action: onShowNextTip)
                    .accessibilityIdentifier("random-tip.next")
                RandomTipCardButton(title: "Hide until JustSessions opens again", systemImage: "xmark", action: onHide)
                    .accessibilityIdentifier("random-tip.hide")
            }
            Text(tip.message)
                .font(ThemeFont.callout)
                .foregroundStyle(ThemePalette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 10)
        .padding(.trailing, 4)
        .padding(.top, 4)
        .padding(.bottom, 10)
        .background(ThemePalette.raisedSurface, in: RoundedRectangle(.card))
        .overlay {
            RoundedRectangle(.card).stroke(ThemePalette.hairline)
        }
        .contextMenu {
            Button("Next tip", systemImage: "arrow.right", action: onShowNextTip)
            Button("Hide until JustSessions opens again", systemImage: "xmark", action: onHide)
            Divider()
            Button("Don't show tips", systemImage: "lightbulb.slash", action: onTurnOffTips)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("random-tip")
    }
}

/// A round icon button in the tip's heading, named by its tooltip and for VoiceOver.
private struct RandomTipCardButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(ThemeFont.glyph(.control, weight: .semibold))
                .foregroundStyle(ThemePalette.secondaryText)
                .frame(width: 22, height: 22)
                .contentShape(Circle())
        }
        .buttonStyle(ThemePlainButtonStyle(cornerRadius: nil))
        .help(title)
        .accessibilityLabel(title)
    }
}
