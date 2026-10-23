/// Variables a Claude Code session sets in its own processes. An app opened from a shell inside one, as `make dev`
/// or `open` from Claude Code's terminal does, inherits them, and so would every CLI it starts. With
/// `CLAUDE_CODE_CHILD_SESSION` set, Claude Code takes itself for that session's child and saves no transcript ("Transcript
/// saving is off — inherited CLAUDE_CODE_CHILD_SESSION marker", Claude Code 2.1.304), so its session is never listed and
/// its tab never links. The rest name the other session, its process, and its messaging socket and token.
///
/// The names are those Claude Code 2.1.304 itself treats as one session's (`CLAUDECODE` through
/// `CLAUDE_CODE_PROCESS_WRAPPER`), and those seen in a session's shell (`CLAUDE_CODE_ENTRYPOINT` onward). Settings a
/// user gives every session, such as `CLAUDE_CONFIG_DIR`, `ANTHROPIC_API_KEY`, or `CLAUDE_CODE_USE_BEDROCK`, stay.
enum ClaudeCodeSessionEnvironment {
    static let variableNames = [
        "CLAUDECODE", "CLAUDE_CODE_SESSION_ID", "CLAUDE_CODE_CHILD_SESSION", "CLAUDE_CODE_SESSION_ATTENDED",
        "CLAUDE_CODE_CHROME_MCP_ORG_DENIED", "CLAUDE_CODE_EVAL_INTERVIEW_SESSION", "CLAUDE_CODE_BRIDGE_SESSION_ID",
        "CLAUDE_CODE_HOST_WORKTREE", "CLAUDE_CODE_HOST_WORKTREE_FENCE", "CLAUDE_BG_GATEWAY_WITHHELD",
        "CLAUDE_CODE_PROCESS_WRAPPER",
        "CLAUDE_CODE_ENTRYPOINT", "CLAUDE_CODE_EXECPATH", "CLAUDE_CODE_MESSAGING_SOCKET", "CLAUDE_CODE_MESSAGING_TOKEN",
        "CLAUDE_PID",
    ]

    static func removingSessionVariables(from environment: [String: String]) -> [String: String] {
        var cleanedEnvironment = environment
        for name in variableNames {
            cleanedEnvironment[name] = nil
        }
        return cleanedEnvironment
    }
}
