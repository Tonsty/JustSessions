import AppKit
import Network

/// Forgets every host `SSHHostReachability` couldn't reach when the Mac's network changes, as when Wi-Fi or a VPN
/// connects, and when the Mac wakes, since a host out of reach before may answer now.
@MainActor
final class SSHHostReachabilityResets {
    static let shared = SSHHostReachabilityResets()

    private let reachability: SSHHostReachability
    private let pathMonitor = NWPathMonitor()
    private var wakeObserver: (any NSObjectProtocol)?

    init(reachability: SSHHostReachability = .shared) {
        self.reachability = reachability
    }

    func start() {
        guard wakeObserver == nil else { return }
        let reachability = reachability
        pathMonitor.pathUpdateHandler = { _ in reachability.forgetAll() }
        pathMonitor.start(queue: DispatchQueue(label: "JustSessions.SSHHostReachabilityResets", qos: .utility))
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { _ in reachability.forgetAll() }
    }
}
