import Foundation

/// Looks up a folder typed for a new session or project on this Mac and returns its absolute path. `~` is the home
/// folder, and so is the base of a relative path, as on an SSH host (`RemoteFolderResolver`). A missing folder is
/// reported, or created with any missing parents once asked to, so a typo is never created without a second look.
enum ThisMacFolderResolver {
    static func resolvedPath(of typedFolder: String, creatingMissingFolder: Bool = false) throws -> String {
        let path = absolutePath(of: typedFolder)
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) {
            guard isDirectory.boolValue else { throw ThisMacFolderResolutionError.notAFolder(folder: typedFolder) }
            return path
        }
        guard creatingMissingFolder else { throw ThisMacFolderResolutionError.missingFolder(folder: typedFolder) }
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        } catch {
            throw ThisMacFolderResolutionError.couldNotCreateFolder(folder: typedFolder)
        }
        return path
    }

    /// Standardized, so `..` and a trailing `/` don't make a second project for the same folder.
    static func absolutePath(of typedFolder: String) -> String {
        let expandedFolder = (typedFolder as NSString).expandingTildeInPath
        let absoluteFolder = expandedFolder.hasPrefix("/") ? expandedFolder : NSHomeDirectory() + "/" + expandedFolder
        return URL(fileURLWithPath: absoluteFolder).standardizedFileURL.path
    }
}
