import Foundation

/// The command that receives a dropped file on an SSH host. `ssh` hands it the file on standard input, and it writes
/// the file under its own name into a new private folder in `droppedFilesFolder`, so the CLI can open it there and two
/// files of the same name don't collide. It needs only POSIX `sh` and the tools every host has, unlike `scp`, which
/// needs the host's SFTP server, or `rsync`.
///
/// The folder's copies stay while the CLI that was handed them may still read them, as one that keeps running in tmux
/// after its tab closes; each copy removes those more than a week old first.
enum RemoteDroppedFileCopyScript {
    /// Relative to the home folder on the host.
    static let droppedFilesFolder = ".cache/justsessions/dropped-files"
    /// Before the private folder's absolute path, on the line the command prints last; a shell profile may print lines
    /// of its own first.
    static let folderLinePrefix = "__JUSTSESSIONS_DROPPED_FILE_FOLDER__"

    /// The exit statuses of the script's own failures. `ssh` exits with 255 for its own.
    enum ExitStatus {
        /// The folder could not be made, as when the home folder can't be written to.
        static let couldNotMakeFolder: Int32 = 70
        /// Writing the file failed, as when the host's disk is full.
        static let couldNotWrite: Int32 = 71
        /// Fewer or more bytes arrived than the file has, as when the copy was stopped or the connection lost.
        static let incomplete: Int32 = 72
    }

    /// A POSIX `sh` script, so it runs the same whatever the host's login shell is. `ssh` starts in the home folder,
    /// and `mktemp -d` makes the folder readable by its owner only. A copy that fails removes its folder.
    static let script = """
        umask 077
        folder="$HOME/\(droppedFilesFolder)"
        mkdir -p "$folder" || exit \(ExitStatus.couldNotMakeFolder)
        find "$folder" -mindepth 1 -maxdepth 1 -type d -mtime +6 -exec rm -rf {} + 2>/dev/null
        copy=$(mktemp -d "$folder/XXXXXXXX") || exit \(ExitStatus.couldNotMakeFolder)
        cat > "$copy/$1" || { rm -rf "$copy"; exit \(ExitStatus.couldNotWrite); }
        [ "$(wc -c < "$copy/$1" | tr -d ' ')" = "$2" ] || { rm -rf "$copy"; exit \(ExitStatus.incomplete); }
        printf '\(folderLinePrefix)%s\\n' "$copy"
        """

    /// Receives a file named `fileName` that is `byteCount` bytes long.
    static func command(fileName: String, byteCount: Int64) -> String {
        "sh -c \(ShellQuoting.quoted(script)) sh \(ShellQuoting.quoted(fileName)) \(byteCount)"
    }

    /// The private folder the file went into, from the last line that names one.
    static func folder(inOutput output: String) -> String? {
        output
            .split(whereSeparator: \.isNewline)
            .last { $0.hasPrefix(folderLinePrefix) }
            .map { String($0.dropFirst(folderLinePrefix.count)) }
            .flatMap { $0.hasPrefix("/") ? $0 : nil }
    }
}
