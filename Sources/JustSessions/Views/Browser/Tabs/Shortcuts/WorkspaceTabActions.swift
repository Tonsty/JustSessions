import SwiftUI

/// Commands use the active window's actions even while its AppKit terminal has keyboard focus.
struct WorkspaceTabActions {
    let tabCount: Int
    let hasSelectedTab: Bool
    /// A split, or a split chooser, shows, so the Tabs menu's split view items act on it.
    let isSplitShown: Bool
    /// The selected tab is in no split and beside no split chooser, so Add Tab to New Split View can show one.
    let canOpenSplitChooser: Bool
    let isEnabled: Bool
    let newSession: () -> Void
    let closeSelectedTab: () -> Void
    let selectAdjacentTab: (_ movingForward: Bool) -> Void
    let selectTab: (_ shortcutNumber: Int) -> Void
    let openSplitChooser: () -> Void
    /// The shown split's actions, as Chrome's split view button offers them.
    let separateShownSplit: () -> Void
    let closeShownSplitView: (_ side: TerminalSplit.Side) -> Void
    let reverseShownSplit: () -> Void
}

private struct WorkspaceTabActionsKey: FocusedValueKey {
    typealias Value = WorkspaceTabActions
}

extension FocusedValues {
    var workspaceTabActions: WorkspaceTabActions? {
        get { self[WorkspaceTabActionsKey.self] }
        set { self[WorkspaceTabActionsKey.self] = newValue }
    }
}
