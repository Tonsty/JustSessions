import Foundation
import Observation

/// How large the app draws its own interface: the sidebar, tabs, preview, sheets, and Settings. Terminals keep their own
/// font size (Settings → Appearance → Terminal) and the conversation its reading text size, each with ⌘+ and ⌘−.
///
/// `ThemeFont`, `ThemeGlyphSize`, and the fixed sizes that hold text read `scale` through `InterfaceScale`, so a view
/// that draws with them redraws when it changes, without being told: SwiftUI follows every `@Observable` property a
/// body reads. macOS ignores SwiftUI's Dynamic Type sizes, so the app scales its type itself.
@MainActor
@Observable
final class InterfaceSizeStore {
    static let shared = InterfaceSizeStore()

    static let defaultScale = 1.0
    static let scaleRange = 0.9...1.5
    static let scaleStep = 0.1
    static let userDefaultsKey = "interfaceScale"

    private(set) var scale: Double
    @ObservationIgnored private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        scale = Self.validScale(userDefaults.object(forKey: Self.userDefaultsKey) as? Double ?? Self.defaultScale)
    }

    func setScale(_ newScale: Double) {
        let validScale = Self.validScale(newScale)
        guard validScale != scale else { return }
        scale = validScale
        if validScale == Self.defaultScale {
            userDefaults.removeObject(forKey: Self.userDefaultsKey)
        } else {
            userDefaults.set(validScale, forKey: Self.userDefaultsKey)
        }
    }

    /// Within the range, on a step: a slider's value between steps, or a value saved by hand, takes the nearest.
    static func validScale(_ value: Double) -> Double {
        guard value.isFinite else { return defaultScale }
        let clamped = min(max(value, scaleRange.lowerBound), scaleRange.upperBound)
        let steps = ((clamped - scaleRange.lowerBound) / scaleStep).rounded()
        return ((scaleRange.lowerBound + steps * scaleStep) * 100).rounded() / 100
    }
}
