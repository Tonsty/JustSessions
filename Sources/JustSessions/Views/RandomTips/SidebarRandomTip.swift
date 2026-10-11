import SwiftUI

/// The random tip at the bottom of the sidebar, above its footer, while tips are on and the tip wasn't closed this
/// launch. It steps aside while the window's onboarding tour or a first-use tip shows, since those point at the
/// window's controls.
struct SidebarRandomTip: View {
    @Environment(\.onboardingTour) private var onboardingTour

    var body: some View {
        if let onboardingTour {
            SidebarRandomTipSlot(tipsStore: .shared, onboardingTour: onboardingTour)
        }
    }
}

private struct SidebarRandomTipSlot: View {
    @ObservedObject var tipsStore: RandomTipsStore
    @ObservedObject var onboardingTour: OnboardingTour

    private var shownTip: RandomTip? {
        onboardingTour.isRunning ? nil : tipsStore.currentTip
    }

    var body: some View {
        VStack(spacing: 0) {
            if let shownTip {
                RandomTipCard(
                    tip: shownTip,
                    onShowNextTip: tipsStore.showNextTip,
                    onHide: tipsStore.hideUntilNextLaunch,
                    onTurnOffTips: { tipsStore.setShowsTips(false) }
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .transition(.opacity)
            }
        }
        .animation(ThemeMotion.slide, value: shownTip)
    }
}
