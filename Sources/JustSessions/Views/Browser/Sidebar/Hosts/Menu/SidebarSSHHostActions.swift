import SwiftUI

/// What an SSH host's heading offers that this Mac's does not; see `SidebarSSHHostMenuItems`.
struct SidebarSSHHostActions {
    /// Whether the host's tmux sessions use its own prefix keys; see `RemoteTmuxPrefixOptions`.
    let usesTmuxPrefix: Binding<Bool>
    /// What the host's shell startup check found; nil before it ran. See `RemoteShellStartupCheck`.
    let shellStartupCheck: RemoteShellStartupCheckResult?
    let isCheckingShellStartup: Bool
    let onCheckShellStartup: () -> Void
    /// Connect…, for a host that asks for a password or a code; see `ConversationStore+SSHLogin`.
    let login: SidebarSSHHostLogin
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    let onRemove: () -> Void
}
