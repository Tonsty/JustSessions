import Foundation

/// One question `ssh` asks while the app logs in to a host, shown in the window that started the login.
struct SSHAskpassQuestion: Identifiable, Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        /// A password, passphrase, or one-time code, typed without being shown.
        case secret
        /// Whether to trust a host key `ssh` has not seen, with its fingerprint in the prompt. `ssh` takes "yes".
        case unknownHostKey
        /// A yes or no question. `ssh` takes "yes", or the helper failing as no.
        case confirmation
        /// Something to do with no answer, such as touching a security key; `ssh` ends the helper when it is done.
        case notice
    }

    let id = UUID()
    let host: String
    let kind: Kind
    /// What `ssh` asked, as it worded it, such as "(me@devbox) Password:".
    let prompt: String
    /// What `ssh` printed since the last question, such as a sign-in banner, the options of a second factor, or
    /// "Permission denied, please try again."; nil when it printed nothing.
    let context: String?
    /// Whether `ssh` asks the secret it asked last again, which means it did not accept the answer. A refused
    /// keyboard-interactive answer is asked again with nothing printed, so this is the only sign of it.
    let isAskedAgain: Bool

    init(host: String, request: SSHAskpassRequest, context: String?, previousPrompt: String? = nil) {
        self.host = host
        prompt = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        self.context = context
        kind = switch request.hint {
        case "confirm": .confirmation
        case "none": .notice
        default: Self.asksToTrustHostKey(request.prompt) ? .unknownHostKey : .secret
        }
        isAskedAgain = kind == .secret && prompt == previousPrompt
    }

    /// OpenSSH asks "Are you sure you want to continue connecting (yes/no/[fingerprint])?" about a new host key.
    static func asksToTrustHostKey(_ prompt: String) -> Bool {
        prompt.lowercased().contains("continue connecting (yes/no")
    }

    /// What `ssh` gets when the question is answered yes, or with `typedText`.
    func answer(typedText: String = "") -> String {
        switch kind {
        case .secret: typedText
        case .unknownHostKey, .confirmation: "yes"
        case .notice: ""
        }
    }
}
