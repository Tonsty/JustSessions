import SwiftUI

extension ConversationProvider {
    /// Template images inherit the foreground color, including the custom Codex, Kiro, and OpenCode icons.
    func iconImage(size: CGFloat = 13) -> Image {
        switch self {
        case .claude: Image(systemName: "asterisk")
        case .codex: Image(nsImage: CodexPromptHexagonIcon.image(size: size))
        case .antigravity: Image(systemName: "sparkle")
        case .kiro: Image(nsImage: KiroGhostIcon.image(size: size))
        case .opencode: Image(nsImage: OpenCodeBlockRingIcon.image(size: size))
        case .pi: Image(systemName: "pi")
        }
    }
}
