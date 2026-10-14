import Foundation

/// A new session that starts with its first message already sent, as the agent that fixes what a host check found;
/// see `HostFixAgentPrompt`. Each tool takes the message its own way, and keeps its session open after answering it.
extension ConversationProvider {
    /// The arguments that send `prompt` as the session's first message, to go after the tool's executable.
    func initialPromptArguments(_ prompt: String) -> [String] {
        // A leading `-` would read as an option, and Pi reads a leading `@` as a file to attach.
        let promptArgument = prompt.hasPrefix("-") || prompt.hasPrefix("@") ? " " + prompt : prompt
        switch self {
        case .claude, .codex, .pi: return [promptArgument]
        case .kiro: return ["chat", promptArgument]
        case .opencode: return ["--prompt", promptArgument]
        case .antigravity: return ["--prompt-interactive", promptArgument]
        }
    }
}
