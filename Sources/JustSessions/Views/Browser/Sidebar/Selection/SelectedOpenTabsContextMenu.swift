import SwiftUI

/// Right-click menu for an Open tabs row that is one of several selected.
struct SelectedOpenTabsContextMenu: View {
    let selectedTabCount: Int
    /// Asks once for them all, as Close all tabs in group… does.
    let onClose: () -> Void

    var body: some View {
        Button("Close \(selectedTabCount) tabs…", systemImage: "xmark", role: .destructive, action: onClose)
    }
}
