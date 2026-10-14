import Foundation

/// The tmux versions an SSH host may run, as far as they differ in what a JustSessions session uses. Commands for the
/// host's tmux ask it `tmux -V` and give each version only what it understands; `caseStatement(_:)` writes that.
/// tmux 1.8, the first with `new-session -A`, is the oldest that can run a session. Each difference here was tried
/// against tmux 1.8, 1.9a, 2.0 to 2.7, 3.0a, 3.2a, 3.4, and 3.6a, and the keys also over SSH against 1.8 and 3.4.
enum RemoteTmuxGeneration: CaseIterable {
    /// tmux 1.8 to 2.0. The mouse option is `mode-mouse`. A target has no `=` asking for exactly one session's name,
    /// and before 2.0 `set-option -q` still fails on an option tmux doesn't know, which skips the commands after it.
    case before2_1
    /// tmux 2.1, which has `mouse` and `=`, but no `None` key to turn a prefix off.
    case version2_1
    /// tmux 2.2 and 2.3, whose `xterm-keys` is still off by default.
    case before2_4
    /// tmux 2.4 to 3.1, which can't keep a failed CLI's pane (`remain-on-exit failed`).
    case before3_2
    /// tmux 3.2 and later, and any version `tmux -V` names otherwise, such as `next-3.7` or `openbsd-7.6`.
    case current

    /// A `case` pattern for what `tmux -V` prints; the last generation takes every other answer.
    private var casePattern: String {
        switch self {
        case .before2_1: #""tmux "[01].* | "tmux 2.0"*"#
        case .version2_1: #""tmux 2.1"*"#
        case .before2_4: #""tmux 2."[23]*"#
        case .before3_2: #""tmux 2."* | "tmux 3."[01] | "tmux 3."[01][a-z]"#
        case .current: "*"
        }
    }

    /// The option that lets the mouse wheel scroll the tab, through tmux's copy mode.
    var mouseOption: String { self == .before2_1 ? "mode-mouse" : "mouse" }

    /// Whether the window needs `xterm-keys on`, off by default before tmux 2.4, for Shift, Option, or Control with an
    /// arrow, Home, or End to reach the CLI: without it, Shift-Left reached it as Left.
    var needsXtermKeys: Bool {
        switch self {
        case .before2_1, .version2_1, .before2_4: true
        case .before3_2, .current: false
        }
    }

    /// Whether `set-option -q` skips an option this tmux doesn't know, as `allow-passthrough` before tmux 3.3.
    var skipsUnknownQuietOptions: Bool { self != .before2_1 }

    /// A prefix key no one presses, which turns tmux's prefix off. Before `None` came in tmux 2.2, it is
    /// Control-Option-Shift-Insert: Mac keyboards have no Insert key.
    var unusedPrefixKey: String {
        switch self {
        case .before2_1, .version2_1: "C-M-S-IC"
        case .before2_4, .before3_2, .current: "None"
        }
    }

    /// What comes before a session's name in a target for exactly that session. tmux before 2.1 takes a plain name,
    /// which it matches exactly first; it would match a longer name only when no session has this one, and no
    /// JustSessions name is the start of another, as each ends in an id of a fixed length.
    var exactSessionPrefix: String { self == .before2_1 ? "" : "=" }

    /// Whether a failed CLI's pane can stay, so the tab shows what it printed.
    var keepsFailedPanes: Bool { self == .current }

    /// `case $(tmux -V 2>/dev/null) in … esac` for `sh`, running `commands` of the host's tmux generation. Generations
    /// in a row with the same commands share a branch.
    static func caseStatement(_ commands: (RemoteTmuxGeneration) -> String) -> String {
        var branches: [(patterns: [String], commands: String)] = []
        for generation in allCases {
            let generationCommands = commands(generation)
            if branches.last?.commands == generationCommands {
                branches[branches.count - 1].patterns.append(generation.casePattern)
            } else {
                branches.append(([generation.casePattern], generationCommands))
            }
        }
        let lastIndex = branches.count - 1
        let cases = branches.enumerated().map { index, branch in
            let pattern = index == lastIndex ? "*" : branch.patterns.joined(separator: " | ")
            return "\(pattern)) \(branch.commands) ;;"
        }
        return (["case $(tmux -V 2>/dev/null) in"] + cases + ["esac"]).joined(separator: "\n")
    }

    /// Sets `exact` to what comes before `$name` in a target for exactly that session: `"$exact$name"`, or
    /// `"$exact$name:"` for its pane.
    static let exactSessionPrefixAssignment = caseStatement { "exact=\(ShellQuoting.quoted($0.exactSessionPrefix))" }
}
