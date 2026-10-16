import SwiftUI

/// What an SSH host's heading offers that this Mac's does not; see `SidebarSSHHostMenuItems`.
struct SidebarSSHHostActions {
    /// Whether the host's tmux sessions use its own prefix keys; see `RemoteTmuxPrefixOptions`.
    let usesTmuxPrefix: Binding<Bool>
    /// What the host's shell startup check found; nil before it ran. See `RemoteShellStartupCheck`.
    let shellStartupCheck: RemoteShellStartupCheckResult?
    /// Check this host…; see `ConversationStore+HostCheck`.
    let onCheckHost: () -> Void
    /// What the host's warning says its last check, or its last refresh's tmux, found; nil when nothing. See
    /// `SidebarHostCheckProblemWarning`.
    let hostCheckProblem: String?
    /// Shows the host's last check, from its warning.
    let onShowHostCheck: () -> Void
    /// Connect…, for a host that asks for a password or a code; see `ConversationStore+SSHLogin`.
    let login: SidebarSSHHostLogin
    let onConnect: () -> Void
    let onDisconnect: () -> Void
    /// The host's port forwards, and Forward a port…; see `SSHPortForwards`.
    let portForwards: [SSHPortForwards.Entry]
    let onForwardPort: () -> Void
    let onTryPortForwardsAgain: () -> Void
    let onStopPortForward: (SSHPortForward) -> Void
    let onRemove: () -> Void
}
