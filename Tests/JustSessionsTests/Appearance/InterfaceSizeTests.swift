import AppKit
import SwiftUI
import Testing
@testable import JustSessions

/// Settings → Appearance → Interface size: what it saves, and that the app's type and the sizes that hold it follow it.
@MainActor
@Suite(.serialized)
struct InterfaceSizeTests {
    @Test func savesOnlyASizeOnAStepWithinTheRange() throws {
        let settings = try IsolatedUserDefaults()
        defer { settings.removeSuite() }
        let store = InterfaceSizeStore(userDefaults: settings.userDefaults)
        #expect(store.scale == 1.0)

        store.setScale(1.26)
        #expect(store.scale == 1.3)
        #expect(settings.userDefaults.double(forKey: InterfaceSizeStore.userDefaultsKey) == 1.3)
        #expect(InterfaceSizeStore(userDefaults: settings.userDefaults).scale == 1.3)

        store.setScale(4)
        #expect(store.scale == 1.5)
        store.setScale(0.2)
        #expect(store.scale == 0.9)
        store.setScale(.nan)
        #expect(store.scale == 1.0)
        // The default is no saved value, so a later default applies.
        #expect(settings.userDefaults.object(forKey: InterfaceSizeStore.userDefaultsKey) == nil)

        settings.userDefaults.set(1.17, forKey: InterfaceSizeStore.userDefaultsKey)
        #expect(InterfaceSizeStore(userDefaults: settings.userDefaults).scale == 1.2)
    }

    @Test func sizesFollowTheInterfaceSizeToTheHalfPoint() {
        defer { InterfaceSizeStore.shared.setScale(1.0) }
        #expect(InterfaceScale.points(28) == 28)
        #expect(InterfaceScale.controlSize == .regular)

        InterfaceSizeStore.shared.setScale(1.3)
        #expect(InterfaceScale.points(28) == 36.5)
        #expect(InterfaceScale.points(7) == 9)
        #expect(InterfaceScale.controlSize == .large)
        InterfaceSizeStore.shared.setScale(1.5)
        #expect(InterfaceScale.controlSize == .extraLarge)
        InterfaceSizeStore.shared.setScale(0.9)
        #expect(InterfaceScale.points(28) == 25)
        #expect(InterfaceScale.controlSize == .small)
    }

    /// A view on screen that sets its text in `ThemeFont`, or takes its font from the window's root, redraws larger when
    /// the interface size changes, with nothing else telling it to.
    @Test func textOnScreenGrowsWhenTheInterfaceSizeChanges() async throws {
        defer { InterfaceSizeStore.shared.setScale(1.0) }
        InterfaceSizeStore.shared.setScale(1.0)
        let tokenText = NSHostingView(rootView: CalloutLabel())
        let rootText = NSHostingView(rootView: Text("Appearance").fixedSize().appTheme(from: .shared))
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 400, height: 200), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        let container = NSView(frame: window.contentLayoutRect)
        container.addSubview(tokenText)
        container.addSubview(rootText)
        window.contentView = container
        defer { window.close() }
        let tokenWidth = tokenText.fittingSize.width, rootWidth = rootText.fittingSize.width

        InterfaceSizeStore.shared.setScale(1.5)
        for _ in 0..<10 where tokenText.fittingSize.width < tokenWidth * 1.4 {
            try await Task.sleep(for: .milliseconds(20))
        }

        #expect(tokenText.fittingSize.width > tokenWidth * 1.4)
        #expect(rootText.fittingSize.width > rootWidth * 1.4)
    }
}

/// Reads `ThemeFont` in its body, as the app's views do.
private struct CalloutLabel: View {
    var body: some View {
        Text("Fix the login redirect loop").font(ThemeFont.callout).fixedSize()
    }
}
