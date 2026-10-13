import Foundation

/// Each host's choice of what closing a tab does when tmux can keep its CLI running there. A host with no saved choice
/// asks each time, so only the hosts that keep running or end without asking are saved.
struct TabCloseChoicesByHost: Equatable {
    static let thisMacUserDefaultsKey = "tabCloseChoiceOnThisMac"
    static let sshHostsUserDefaultsKey = "tabCloseChoiceBySSHHost"

    private(set) var thisMacChoice: TabCloseChoice
    /// Keyed by the SSH destination, as `SessionHost.ssh` holds it.
    private(set) var sshHostChoices: [String: TabCloseChoice]

    init(thisMacChoice: TabCloseChoice = .askEachTime, sshHostChoices: [String: TabCloseChoice] = [:]) {
        self.thisMacChoice = thisMacChoice
        self.sshHostChoices = sshHostChoices.filter { $0.value != .askEachTime }
    }

    /// Unknown saved values ask each time.
    static func load(from userDefaults: UserDefaults) -> TabCloseChoicesByHost {
        let thisMacChoice = userDefaults.string(forKey: thisMacUserDefaultsKey).flatMap(TabCloseChoice.init(rawValue:))
        let savedSSHHostChoices = userDefaults.dictionary(forKey: sshHostsUserDefaultsKey) as? [String: String] ?? [:]
        return TabCloseChoicesByHost(
            thisMacChoice: thisMacChoice ?? .askEachTime,
            sshHostChoices: savedSSHHostChoices.compactMapValues(TabCloseChoice.init(rawValue:))
        )
    }

    func save(to userDefaults: UserDefaults) {
        userDefaults.set(thisMacChoice.rawValue, forKey: Self.thisMacUserDefaultsKey)
        userDefaults.set(sshHostChoices.mapValues(\.rawValue), forKey: Self.sshHostsUserDefaultsKey)
    }

    func choice(for host: SessionHost) -> TabCloseChoice {
        switch host {
        case .thisMac: thisMacChoice
        case .ssh(let destination): sshHostChoices[destination] ?? .askEachTime
        }
    }

    mutating func setChoice(_ choice: TabCloseChoice, for host: SessionHost) {
        switch host {
        case .thisMac:
            thisMacChoice = choice
        case .ssh(let destination):
            sshHostChoices[destination] = choice == .askEachTime ? nil : choice
        }
    }
}
