import Foundation

/// Where an SSH host's login made with Connect… stands, for its heading and ⋯ menu.
enum SidebarSSHHostLogin: Equatable {
    /// `needsLogIn` when the last refresh asked for a password, a code, or a new host key's approval.
    case notLoggedIn(needsLogIn: Bool)
    case loggingIn
    case loggedIn
}
