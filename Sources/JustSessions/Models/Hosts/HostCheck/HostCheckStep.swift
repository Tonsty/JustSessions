import Foundation

/// The steps of Check this host…, in the order `RemoteHostCheck` runs them, so the sheet can show which one runs.
enum HostCheckStep: Int, CaseIterable, Comparable, Sendable {
    case logIn
    case shellStartup
    case cliLookup
    case hostCommand

    static func < (lhs: HostCheckStep, rhs: HostCheckStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
