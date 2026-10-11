import Combine
import Foundation

/// The random tip at the bottom of the sidebar: whether tips show at all, set in Settings → Help, and the tip showing.
/// Each launch shows one, picked at random among those not shown yet. Next tip shows another, and closing the tip hides
/// tips until the next launch. Every workspace window shows the same tip.
@MainActor
final class RandomTipsStore: ObservableObject {
    /// Created at launch, once onboarding has decided whether its tour is due. A launch that is to show the tour shows
    /// no random tip, so a fresh install meets the tour on its own.
    static let shared = RandomTipsStore(
        userDefaults: .standard,
        waitsForNextLaunch: OnboardingTipsStore.shared.shouldShow(.tour)
    )
    static let showsTipsKey = "showsRandomTips"
    static let shownTipsKey = "randomTipsShown"

    @Published private(set) var showsTips: Bool
    /// The tip the sidebar shows; nil while tips are off, or closed until the next launch.
    @Published private(set) var currentTip: RandomTip?
    private var rotation: RandomTipRotation
    private let userDefaults: UserDefaults
    private let randomIndex: (Int) -> Int

    init(
        userDefaults: UserDefaults,
        waitsForNextLaunch: Bool,
        randomIndex: @escaping (Int) -> Int = { Int.random(in: 0..<$0) }
    ) {
        self.userDefaults = userDefaults
        self.randomIndex = randomIndex
        showsTips = userDefaults.object(forKey: Self.showsTipsKey) as? Bool ?? true
        let savedShownTips = (userDefaults.stringArray(forKey: Self.shownTipsKey) ?? []).compactMap(RandomTip.init(rawValue:))
        rotation = RandomTipRotation(shownTips: Set(savedShownTips))
        if !waitsForNextLaunch {
            showNextTip()
        }
    }

    /// Shows another tip in place of the one showing.
    func showNextTip() {
        guard showsTips else { return }
        currentTip = rotation.nextTip(after: currentTip, randomIndex: randomIndex)
        userDefaults.set(RandomTip.allCases.filter(rotation.shownTips.contains).map(\.rawValue), forKey: Self.shownTipsKey)
    }

    /// Closes the tip; the next launch shows another.
    func hideUntilNextLaunch() {
        currentTip = nil
    }

    /// Settings → Help's switch, and the tip's Don't show tips. Turning tips on shows one right away.
    func setShowsTips(_ showsTips: Bool) {
        guard showsTips != self.showsTips else { return }
        self.showsTips = showsTips
        userDefaults.set(showsTips, forKey: Self.showsTipsKey)
        if showsTips {
            showNextTip()
        } else {
            currentTip = nil
        }
    }
}
