import Foundation

enum ShellQuoting {
    /// Wraps the value in single quotes, with each single quote and backslash in it written outside the quotes as
    /// `\'` or `\\`. POSIX shells and fish read that the same way. fish reads `\'` and `\\` inside single quotes as
    /// escapes, so a backslash left inside them, as in a value quoted twice, would change the value or leave the
    /// quote open in a fish login shell.
    static func quoted(_ value: String) -> String {
        var quoted = "'"
        for character in value {
            switch character {
            case "'": quoted += #"'\''"#
            case "\\": quoted += #"'\\'"#
            default: quoted.append(character)
            }
        }
        return quoted + "'"
    }
}
