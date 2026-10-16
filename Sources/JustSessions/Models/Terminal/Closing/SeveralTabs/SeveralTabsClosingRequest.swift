import Foundation

/// Tabs closing together, every tab of a project's group from Close all tabs in group… or the tabs selected in Open
/// tabs, waiting for the answer to what closing them asks.
struct SeveralTabsClosingRequest: Identifiable, Equatable, Sendable {
    /// Which tabs these are, which the question's title names.
    enum Subject: Equatable, Sendable {
        case group(projectName: String)
        case selectedTabs
    }

    let id = UUID()
    let subject: Subject
    let tabIDs: [UUID]
    let question: SeveralTabsClosingQuestion
}
