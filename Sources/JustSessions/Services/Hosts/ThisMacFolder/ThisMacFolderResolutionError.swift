import Foundation

enum ThisMacFolderResolutionError: LocalizedError, Equatable {
    case missingFolder(folder: String)
    case notAFolder(folder: String)
    case couldNotCreateFolder(folder: String)

    var errorDescription: String? {
        switch self {
        case .missingFolder(let folder):
            "There is no folder \(folder) on this Mac."
        case .notAFolder(let folder):
            "\(folder) is a file, not a folder."
        case .couldNotCreateFolder(let folder):
            "Could not create the folder \(folder). Check that you can write to its parent folder."
        }
    }
}
