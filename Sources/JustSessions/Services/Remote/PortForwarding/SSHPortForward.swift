import Foundation

/// A port on this Mac forwarded to `localhost:<remotePort>` on an SSH host; see `SSHPortForwards`. Only this Mac can
/// use it: it listens on 127.0.0.1.
struct SSHPortForward: Hashable, Sendable {
    static let validPorts = 1...65535

    let host: String
    let localPort: Int
    let remotePort: Int

    /// What to type in a browser or a client on this Mac.
    var address: String { "localhost:\(localPort)" }

    var browserURL: URL? { URL(string: "http://localhost:\(localPort)") }

    /// `ssh -L`'s argument.
    var specification: String { "127.0.0.1:\(localPort):localhost:\(remotePort)" }
}

/// The `ssh` commands of port forwarding. Forwards are added to a running connection one by one with `-O forward`, from
/// an `ssh` that reads no config (`-F /dev/null`), so neither it nor the connection, which is made with
/// `ClearAllForwardings=yes`, starts the `LocalForward` lines of the user's `~/.ssh/config`: an open tab holds those
/// ports, and the forward would fail for them.
enum SSHPortForwardCommands {
    enum Request: String {
        case forward
        case cancel
    }

    /// A connection that carries forwards and runs nothing: the background commands' settings (SSH-20, SSH-23), in
    /// the foreground, listening on `controlPath` for the forwards to add.
    static func connectionArguments(host: String, controlPath: String) -> [String] {
        ["-N", RemoteHostCommandRunner.noTerminalOption]
            + RemoteHostCommandRunner.nonInteractiveSSHOptions
            + [
                "-o", "ExitOnForwardFailure=no",
                "-o", "ControlMaster=yes",
                "-o", "ControlPath=\(controlPath)",
                "-o", "ControlPersist=no",
                "--", host,
            ]
    }

    static func requestArguments(_ request: Request, _ forward: SSHPortForward, controlPath: String) -> [String] {
        [
            "-F", "/dev/null", "-o", "BatchMode=yes", "-S", controlPath,
            "-O", request.rawValue, "-L", forward.specification, "--", forward.host,
        ]
    }

    /// Opens one connection to the forward's port on the host, as a program on this Mac would through the forward,
    /// and closes it at once; a host that refuses forwarding refuses it.
    static func probeArguments(_ forward: SSHPortForward, controlPath: String) -> [String] {
        [
            "-F", "/dev/null", "-o", "BatchMode=yes", "-S", controlPath,
            "-W", "localhost:\(forward.remotePort)", "--", forward.host,
        ]
    }
}
