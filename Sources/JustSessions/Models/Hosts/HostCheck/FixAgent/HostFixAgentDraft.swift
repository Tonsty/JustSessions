import Foundation

/// What Fix with agent… starts, as its form shows it before you start it; see `HostFixAgentPrompt`.
struct HostFixAgentDraft: Equatable {
    var machine: HostFixAgentMachine
    /// Nil when the machine has no CLI to start.
    var provider: ConversationProvider?
    /// The prompt's part that the form lets you edit: what the check found, how JustSessions uses the host, and the
    /// rules the agent keeps to.
    var task: String
    /// The guide sections the prompt ends with.
    var guideSections: Set<JustSessionsGuideSection>
}
