import AppKit
import SwiftUI
import Testing
@testable import JustSessions

/// The ⋯ and + menus a sidebar row shows under the pointer are in the view tree only while it is there. Each is an
/// AppKit pop-up button underneath, and one or two per row, kept at zero opacity, were re-laid out and re-registered
/// with accessibility on every change the sidebar observed: most of a tab switch's 270 ms; see item 20 in
/// docs/development/performance.md.
@MainActor
struct SidebarHoverMenusTests {
    /// With 300 sessions in 50 projects, the sidebar at rest hosts only its header's filter pop-up: before, it hosted
    /// one per project row too, 49 of them, among 283 AppKit views for the window.
    @Test func rowsAtRestHostNoPopUpButtons() async throws {
        let harness = try await SidebarPerfHarness(sessionCount: 300)
        defer { harness.close() }

        let hostedViews = harness.hostedViews
        let popUpButtons = hostedViews.filter { $0 is NSPopUpButton }

        #expect(hostedViews.count > 50, "the browser is hosted (\(hostedViews.count) views)")
        #expect(popUpButtons.count <= 1, "\(popUpButtons.count) pop-up buttons at rest; a row's menus belong in the tree only under the pointer")
        #expect(hostedViews.count < 150, "\(hostedViews.count) AppKit views; the rows' menus added about 200 before")
    }

    /// The placeholder a row lays out instead of its menus takes the same room, so nothing moves under the pointer.
    @Test func thePlaceholderTakesTheMenusRoom() throws {
        _ = NSApplication.shared
        let store = ConversationStore(adapters: [], startsBackgroundPolling: false)
        let menus = NSHostingView(rootView: ProjectHoverActions(
            store: store,
            location: ProjectLocation(host: .thisMac, path: "/tmp/app"),
            projectDisplayName: "app",
            onNewSession: { _ in }
        ) { EmptyView() })
        let placeholder = NSHostingView(rootView: ProjectHoverActions<EmptyView>.placeholder)

        #expect(placeholder.fittingSize == menus.fittingSize, "placeholder \(placeholder.fittingSize) vs menus \(menus.fittingSize)")
    }
}
