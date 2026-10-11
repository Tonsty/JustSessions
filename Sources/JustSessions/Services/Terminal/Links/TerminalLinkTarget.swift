import Foundation

/// What ⌘-clicking a link in a tab opens, in the app macOS opens it with: a web page, an email address, or a file or
/// folder on this Mac. Both engines hand over the same text: an OSC 8 hyperlink's target, or the URL or path they found
/// under the pointer, such as `https://github.com`, `Sources/App/main.swift:42`, or `~/notes.md`.
struct TerminalLinkTarget: Equatable {
    let url: URL

    /// Nil for a link that opens nothing:
    /// - a URL with a scheme other than `http`, `https`, `mailto`, or `file`, since other schemes start apps that act
    ///   on what the program printed, unless it names a file, as `README.md:3` does;
    /// - a path or `file:` URL in a tab on an SSH host, whose files are on the host, not this Mac;
    /// - a file or folder that doesn't exist, or that opening would run; see `LocalFileLinkSafety`.
    ///
    /// A relative path is in `workingDirectory`, the tab's project folder, where its CLI runs. A path that doesn't
    /// exist as printed is tried without a trailing line and column, as in `main.swift:42:7`.
    init?(
        link: String,
        host: SessionHost,
        workingDirectory: String,
        homeDirectory: String = NSHomeDirectory(),
        canOpenLocalFile: (URL) -> Bool = LocalFileLinkSafety.canOpen
    ) {
        let link = link.trimmingCharacters(in: .whitespaces)
        guard !link.isEmpty else { return nil }
        var path = link
        if let url = URL(string: link), let scheme = url.scheme?.lowercased() {
            if Self.schemesOpenedAsGiven.contains(scheme) {
                self.url = url
                return
            }
            // Any other "scheme" may be a file's name, as `README.md` is in `README.md:3`, so the link is tried as a
            // path, which opens only a file that exists.
            if scheme == "file" { path = url.path }
        }
        guard host == .thisMac else { return nil }
        let absolutePath = Self.absolutePath(path, workingDirectory: workingDirectory, homeDirectory: homeDirectory)
        let candidatePaths = [absolutePath, Self.removingLineAndColumn(from: absolutePath)]
        guard let fileURL = candidatePaths.lazy.map({ URL(fileURLWithPath: $0) }).first(where: canOpenLocalFile) else {
            return nil
        }
        url = fileURL
    }

    private static let schemesOpenedAsGiven: Set<String> = ["http", "https", "mailto"]

    private static func absolutePath(_ path: String, workingDirectory: String, homeDirectory: String) -> String {
        let expandedPath: String
        if path == "~" {
            expandedPath = homeDirectory
        } else if path.hasPrefix("~/") {
            expandedPath = (homeDirectory as NSString).appendingPathComponent(String(path.dropFirst(2)))
        } else if path.hasPrefix("/") {
            expandedPath = path
        } else {
            expandedPath = (workingDirectory as NSString).appendingPathComponent(path)
        }
        // Removes `.` and `..` only. `NSString.standardizingPath` would also drop a `/private` it finds a way around.
        return URL(fileURLWithPath: expandedPath).standardizedFileURL.path
    }

    /// `main.swift:42` and `main.swift:42:7` become `main.swift`; any other path stays as it is.
    private static func removingLineAndColumn(from path: String) -> String {
        guard let suffix = path.range(of: #"(:[0-9]+){1,2}$"#, options: .regularExpression) else { return path }
        return String(path[..<suffix.lowerBound])
    }
}
