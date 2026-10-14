import Foundation

/// Where the agent that fixes what a host check found runs: on the checked host itself, or on this Mac, from where it
/// reaches the host with `ssh`, as when the host can't start a CLI at all.
enum HostFixAgentMachine: Hashable, Sendable {
    case checkedHost
    case thisMac
}
