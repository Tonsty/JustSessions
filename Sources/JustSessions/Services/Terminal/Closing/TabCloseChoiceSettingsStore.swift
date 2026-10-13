import Combine
import Foundation

/// Each host's saved choice of what closing a tab does when tmux can keep its CLI running there. A host asks each time
/// until you tick Don't ask again in that dialog for one of its tabs, or pick an answer for it in Settings.
@MainActor
final class TabCloseChoiceSettingsStore: ObservableObject {
    static let shared = TabCloseChoiceSettingsStore()

    @Published private(set) var choices: TabCloseChoicesByHost
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        choices = TabCloseChoicesByHost.load(from: userDefaults)
    }

    func choice(for host: SessionHost) -> TabCloseChoice {
        choices.choice(for: host)
    }

    func setChoice(_ newChoice: TabCloseChoice, for host: SessionHost) {
        guard newChoice != choices.choice(for: host) else { return }
        var newChoices = choices
        newChoices.setChoice(newChoice, for: host)
        newChoices.save(to: userDefaults)
        choices = newChoices
    }

    /// A removed SSH host's choice goes with it, so adding the host again asks each time.
    func forgetSSHHost(_ destination: String) {
        setChoice(.askEachTime, for: .ssh(destination))
    }
}
