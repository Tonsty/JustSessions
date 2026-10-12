import Foundation

/// An image pasted on a tab on an SSH host, saved on this Mac for the copy to the host, which copies files
/// (`RemoteDroppedFileCopier`). Each is saved in a folder of its own, so it keeps a plain name here and on the host,
/// and the copy removes the folder once it ends; see `TerminalSSHFileDrop`.
enum TerminalPastedImageFile {
    static let baseName = "pasted-image"
    static let defaultParentFolder = FileManager.default.temporaryDirectory
        .appendingPathComponent("JustSessions pasted images", isDirectory: true)

    /// Saves `image` in a new folder in `parentFolder`, which only its owner can open, and returns the file.
    static func write(_ image: TerminalClipboardImage, in parentFolder: URL) throws -> URL {
        let folder = parentFolder.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        let file = folder.appendingPathComponent(baseName).appendingPathExtension(image.fileExtension)
        try image.data.write(to: file)
        return file
    }

    /// Removes a file `write(_:in:)` saved, with its folder.
    static func remove(_ fileURL: URL) {
        try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent())
    }
}
