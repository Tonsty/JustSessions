import Foundation

/// A file or folder on this Mac that a link in a tab names, with the line and column a program printed after it, as in
/// `Sources/App/main.swift:42:7`.
struct TerminalLinkLocalItem: Equatable {
    enum Kind: Equatable {
        case file
        /// A folder that opens in the Finder. A package, such as an app, is a file: opening it runs or opens it.
        case folder
    }

    let url: URL
    let kind: Kind
    var lineNumber: Int? = nil
    var columnNumber: Int? = nil

    /// What is at `url` on this Mac; nil when nothing is.
    static func kind(of url: URL) -> Kind? {
        guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey]) else { return nil }
        return values.isDirectory == true && values.isPackage != true ? .folder : .file
    }

    /// The path followed by the line and column, as VS Code's `--goto` takes it: `/path/main.swift:42:7`.
    var pathWithLineAndColumn: String {
        [url.path, lineNumber.map(String.init), columnNumber.map(String.init)].compactMap(\.self).joined(separator: ":")
    }
}
