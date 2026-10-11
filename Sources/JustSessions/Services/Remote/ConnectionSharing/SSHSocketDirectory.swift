import Darwin
import Foundation

/// Private folders for app-owned SSH control sockets. `/tmp` is open to every user, so the root is used only when
/// it is a real folder of this user that no one else can enter; anyone who connects to a socket uses that connection.
enum SSHSocketDirectory {
    /// Makes a new directory for one refresh. A unique path keeps a stale socket left by a crashed app, or another
    /// refresh of the same host, from ever being mistaken for this refresh's master.
    static func makeRefreshDirectory(at rootPath: String, identifier: UUID = UUID()) -> URL? {
        makeDirectory(at: rootPath, named: "refresh-\(identifier.uuidString)")
    }

    /// Makes a new directory for one login made with Connect…, unique for the same reason as a refresh's.
    static func makeLoginDirectory(at rootPath: String, identifier: UUID = UUID()) -> URL? {
        makeDirectory(at: rootPath, named: "login-\(identifier.uuidString)")
    }

    private static func makeDirectory(at rootPath: String, named name: String) -> URL? {
        guard preparedRoot(at: rootPath) != nil else { return nil }
        let directory = URL(fileURLWithPath: rootPath, isDirectory: true).appendingPathComponent(name, isDirectory: true)
        guard mkdir(directory.path, 0o700) == 0 else { return nil }
        return directory
    }

    /// The root, created when missing, or nil when it isn't safe to use.
    static func preparedRoot(at path: String) -> String? {
        if mkdir(path, 0o700) != 0, errno != EEXIST { return nil }
        var status = stat()
        guard lstat(path, &status) == 0,
              status.st_mode & S_IFMT == S_IFDIR,
              status.st_uid == getuid(),
              status.st_mode & 0o077 == 0 else { return nil }
        return path
    }
}
