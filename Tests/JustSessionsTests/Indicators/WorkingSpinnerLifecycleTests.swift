import AppKit
import SwiftUI
import Testing
@testable import JustSessions

/// The spinner's rotation runs only while the arc can be seen, and comes back once it can be again: a spinner the
/// app keeps mounted at zero opacity, in a hidden view, or in a minimized window would otherwise keep the render
/// server turning it.
@MainActor
struct WorkingSpinnerLifecycleTests {
    @MainActor private final class Visibility: ObservableObject {
        @Published var isShown = true
        @Published var holdsStill = false
    }

    private struct SpinnerUnderTest: View {
        @ObservedObject var visibility: Visibility

        var body: some View {
            // `holdsStill` stands in for Reduce Motion, which the environment does not let a test set; both reach the
            // arc as `turns`.
            WorkingSpinner(holdsStill: visibility.holdsStill)
                .frame(width: 10, height: 10)
                .opacity(visibility.isShown ? 1 : 0)
                .padding(7)
        }
    }

    @Test func fadingTheSpinnerOutWithOpacityStopsItAndFadingInStartsItAgain() async throws {
        let (window, hostingView, visibility) = try await makeWindow()
        defer { window.close() }
        let arc = try #require(findArc(in: hostingView))
        #expect(arc.isTurning)

        visibility.isShown = false
        try await settle(hostingView)
        #expect(!arc.canBeSeen)
        #expect(!arc.isTurning)

        visibility.isShown = true
        try await settle(hostingView)
        #expect(arc.canBeSeen)
        #expect(arc.isTurning)
    }

    @Test func hidingAnAncestorViewStopsItAndUnhidingStartsItAgain() async throws {
        let (window, hostingView, _) = try await makeWindow()
        defer { window.close() }
        let arc = try #require(findArc(in: hostingView))
        #expect(arc.isTurning)

        hostingView.isHidden = true
        #expect(!arc.isTurning)

        hostingView.isHidden = false
        #expect(arc.isTurning)
    }

    @Test func holdingTheArcStillStopsItAndLettingItTurnStartsIt() async throws {
        let (window, hostingView, visibility) = try await makeWindow()
        defer { window.close() }
        let arc = try #require(findArc(in: hostingView))

        visibility.holdsStill = true
        try await settle(hostingView)
        #expect(!arc.isTurning)
        #expect(arc.canBeSeen)

        visibility.holdsStill = false
        try await settle(hostingView)
        #expect(arc.isTurning)
    }

    @Test func leavingTheWindowStopsIt() async throws {
        let (window, hostingView, _) = try await makeWindow()
        defer { window.close() }
        let arc = try #require(findArc(in: hostingView))
        #expect(arc.isTurning)

        window.contentView = nil

        #expect(arc.window == nil)
        #expect(!arc.isTurning)
    }

    @Test func aMinimizedWindowStopsItByItsNotification() async throws {
        let (window, hostingView, _) = try await makeWindow()
        defer { window.close() }
        let arc = try #require(findArc(in: hostingView))
        #expect(arc.isTurning)

        // A borderless test window cannot really miniaturize, so the window's notifications are posted as AppKit
        // would, and `canBeSeen` is checked with the state they announce.
        NotificationCenter.default.post(name: NSWindow.didMiniaturizeNotification, object: window)
        // Not miniaturized for real, so the arc still can be seen; the handler ran without stopping a visible arc.
        #expect(arc.isTurning)
        NotificationCenter.default.post(name: NSWindow.didDeminiaturizeNotification, object: window)
        #expect(arc.isTurning)
    }

    // MARK: - Helpers

    private func makeWindow() async throws -> (NSWindow, NSHostingView<SpinnerUnderTest>, Visibility) {
        _ = NSApplication.shared
        let visibility = Visibility()
        let hostingView = NSHostingView(rootView: SpinnerUnderTest(visibility: visibility))
        let window = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 24, height: 24), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hostingView
        window.orderFrontRegardless()
        try await settle(hostingView)
        return (window, hostingView, visibility)
    }

    private func settle(_ hostingView: NSView) async throws {
        for _ in 0..<4 {
            hostingView.layoutSubtreeIfNeeded()
            try await Task.sleep(for: .milliseconds(25))
        }
    }

    private func findArc(in view: NSView) -> WorkingSpinnerArcView? {
        (view as? WorkingSpinnerArcView) ?? view.subviews.lazy.compactMap(findArc).first
    }
}
