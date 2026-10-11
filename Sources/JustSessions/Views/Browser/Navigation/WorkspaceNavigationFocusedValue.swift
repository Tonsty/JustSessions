import SwiftUI

/// The active window's Back and Forward, so the Go menu works while a terminal has keyboard focus.
private struct WorkspaceNavigationFocusedValueKey: FocusedValueKey {
    typealias Value = WorkspaceNavigation
}

extension FocusedValues {
    var workspaceNavigation: WorkspaceNavigation? {
        get { self[WorkspaceNavigationFocusedValueKey.self] }
        set { self[WorkspaceNavigationFocusedValueKey.self] = newValue }
    }
}
