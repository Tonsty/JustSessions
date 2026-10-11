import Foundation

/// Every tab of a project's group, from Close all tabs in group…, waiting for the answer to what closing them asks.
struct TabGroupClosingRequest: Identifiable, Equatable, Sendable {
    let id = UUID()
    let projectName: String
    let tabIDs: [UUID]
    let question: SeveralTabsClosingQuestion
}
