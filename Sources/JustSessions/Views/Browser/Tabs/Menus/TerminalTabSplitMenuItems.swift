import SwiftUI

/// The split view entries of a tab's menu, as Chrome's tab menu offers them, each a submenu but the first and each
/// followed by a separator.
struct TerminalTabSplitMenuItems: View {
    /// Nil for no entries.
    let splitMenu: TerminalTabSplitMenu?
    let onSplitAction: (TerminalTabSplitAction) -> Void

    var body: some View {
        switch splitMenu {
        case .newSplitWithSelectedTab:
            Button("New split view with current tab", systemImage: "rectangle.split.2x1") {
                onSplitAction(.newSplitWithSelectedTab)
            }
            Divider()
        case .addTabToNewSplit(let candidates):
            Menu {
                ForEach(candidates) { candidate in
                    Button(candidate.menuTitle) { onSplitAction(.addToNewSplit(candidate.id)) }
                }
            } label: {
                Label("Add tab to new split view", systemImage: "rectangle.split.2x1")
            }
            .disabled(candidates.isEmpty)
            Divider()
        case .moveIntoShownSplit:
            Menu {
                Button("Swap with left view", systemImage: "rectangle.lefthalf.inset.filled") {
                    onSplitAction(.moveIntoShownSplit(swappingWith: .left))
                }
                Button("Swap with right view", systemImage: "rectangle.righthalf.inset.filled") {
                    onSplitAction(.moveIntoShownSplit(swappingWith: .right))
                }
            } label: {
                Label("Move tab into split view", systemImage: "rectangle.split.2x1")
            }
            Divider()
        case .arrangeSplit:
            Menu {
                Button("Separate views", systemImage: "arrow.up.left.and.arrow.down.right") {
                    onSplitAction(.separateViews)
                }
                Divider()
                Button("Close left view", systemImage: "xmark") { onSplitAction(.closeView(.left)) }
                Button("Close right view", systemImage: "xmark") { onSplitAction(.closeView(.right)) }
                Divider()
                Button("Reverse views", systemImage: "arrow.left.arrow.right") { onSplitAction(.reverseViews) }
            } label: {
                Label("Arrange split view", systemImage: "rectangle.split.2x1")
            }
            Divider()
        case nil:
            EmptyView()
        }
    }
}
