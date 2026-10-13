import Foundation

/// The answers in `RemoteHostCheckScript`'s output, by key. What comes before the first marker, such as a shell
/// profile's greeting, belongs to no key.
struct RemoteHostCheckOutput: Equatable, Sendable {
    private(set) var textsByKey: [String: String] = [:]

    init(_ output: String) {
        let markerPrefix = RemoteHostCheckScript.marker + " "
        var key: String?
        var linesByKey: [String: [String]] = [:]
        for line in output.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix(markerPrefix) {
                let newKey = String(line.dropFirst(markerPrefix.count)).trimmingCharacters(in: .whitespaces)
                key = newKey
                linesByKey[newKey] = []
            } else if let key {
                linesByKey[key, default: []].append(String(line))
            }
        }
        textsByKey = linesByKey.mapValues {
            $0.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    /// Whether the script got as far as the login shell; false when the login shell never ran it.
    var reachedLoginShell: Bool { textsByKey["shell"] != nil }

    /// The answer, or nil when the key is missing or its answer empty.
    func text(_ key: String) -> String? {
        guard let text = textsByKey[key], !text.isEmpty else { return nil }
        return text
    }

    func exitStatus(_ key: String) -> Int32? {
        text(key).flatMap { Int32($0) }
    }
}
