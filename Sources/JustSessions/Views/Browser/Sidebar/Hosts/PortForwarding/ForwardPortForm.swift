import Foundation

/// What the Forward a port sheet's fields hold. The port on this Mac is the host's port unless another is typed.
struct ForwardPortForm: Equatable {
    var remotePortText = ""
    /// Empty for the host's port.
    var localPortText = ""

    var remotePort: Int? { Self.port(in: remotePortText) }

    /// Nil while the typed port isn't one.
    var localPort: Int? {
        localPortText.trimmingCharacters(in: .whitespaces).isEmpty ? remotePort : Self.port(in: localPortText)
    }

    var canForward: Bool { remotePort != nil && localPort != nil }

    /// A port picked from those the host listens on.
    mutating func pick(_ port: Int) {
        remotePortText = String(port)
    }

    static func port(in text: String) -> Int? {
        guard let port = Int(text.trimmingCharacters(in: .whitespaces)), SSHPortForward.validPorts.contains(port) else {
            return nil
        }
        return port
    }
}
