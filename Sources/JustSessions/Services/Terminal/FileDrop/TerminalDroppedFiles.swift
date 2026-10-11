import AppKit

enum TerminalDroppedFiles {
    /// The files a drag onto a terminal carries. A drag of anything else, such as text or a web link, carries none.
    static func urls(on pasteboard: NSPasteboard) -> [URL] {
        pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
    }
}
