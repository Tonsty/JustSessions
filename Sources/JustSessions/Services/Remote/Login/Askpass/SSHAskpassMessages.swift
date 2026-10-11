import Foundation

/// What the askpass helper passes to the app: what `ssh` asked, and `SSH_ASKPASS_PROMPT`, which says what kind of
/// question it is. One line of JSON each way over the login's socket; see `SSHAskpassServer`.
struct SSHAskpassRequest: Codable, Equatable, Sendable {
    let prompt: String
    /// `confirm` for a yes or no question, `none` for a notice that needs no answer, such as touching a security
    /// key; nil for text to type.
    let hint: String?
}

/// The app's answer to one `SSHAskpassRequest`: the text `ssh` gets, or nil when the question was cancelled.
struct SSHAskpassReply: Codable, Equatable, Sendable {
    let answer: String?
}

enum SSHAskpassMessageLine {
    /// Longer than any prompt or answer `ssh` handles; a line past it is not read.
    static let maximumLength = 64 << 10

    static func encoded(_ message: some Encodable) -> Data? {
        guard var data = try? JSONEncoder().encode(message) else { return nil }
        data.append(UInt8(ascii: "\n"))
        return data
    }

    /// The message on the first line of `data`, or nil until a whole line arrives or when it isn't one.
    static func decoded<Message: Decodable>(_ type: Message.Type, from data: Data) -> Message? {
        guard let end = data.firstIndex(of: UInt8(ascii: "\n")) else { return nil }
        return try? JSONDecoder().decode(type, from: data[data.startIndex..<end])
    }
}
