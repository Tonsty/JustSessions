import Foundation

/// SSH hosts you disconnected from with Disconnect in the host heading's ⋯ or right-click menu. The app runs nothing on
/// such a host on its own, lists its sessions from the last copy, and connects again when you choose Connect or use
/// the host; see `ConversationStore+RemoteHostDisconnect`. The choice outlives a relaunch, so a host out of reach
/// stays alone until you say otherwise.
struct DisconnectedRemoteHosts: Equatable {
    static let userDefaultsKey = "disconnectedRemoteHosts"

    private(set) var hosts: Set<String>

    init(hosts: Set<String> = []) {
        self.hosts = hosts
    }

    static func load(from userDefaults: UserDefaults) -> DisconnectedRemoteHosts {
        DisconnectedRemoteHosts(hosts: Set(userDefaults.stringArray(forKey: userDefaultsKey) ?? []))
    }

    func save(to userDefaults: UserDefaults) {
        userDefaults.set(hosts.sorted(), forKey: Self.userDefaultsKey)
    }

    func isDisconnected(_ host: String) -> Bool {
        hosts.contains(host)
    }

    mutating func setDisconnected(_ isDisconnected: Bool, for host: String) {
        if isDisconnected {
            hosts.insert(host)
        } else {
            hosts.remove(host)
        }
    }
}
