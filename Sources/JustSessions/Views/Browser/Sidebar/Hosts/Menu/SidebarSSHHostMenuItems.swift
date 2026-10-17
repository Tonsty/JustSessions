import SwiftUI

/// An SSH host's own settings: logging in with Connect…, disconnecting from the host or connecting to it again,
/// signing in with its sign-in command and setting that command, its port forwards and Forward a port…,
/// whether its tmux sessions use the host's tmux prefix, what its shell startup check last found, Check this host…, and
/// removing the host. Its heading's ⋯
/// shows only these, since the heading's + and refresh buttons already offer the rest of its right-click menu, which
/// ends with them.
struct SidebarSSHHostMenuItems: View {
    let actions: SidebarSSHHostActions

    var body: some View {
        switch actions.login {
        case .notLoggedIn:
            Button("Connect…", systemImage: "key", action: actions.onConnect)
            Button("Disconnect", systemImage: "xmark.circle", action: actions.onDisconnect)
        case .loggingIn:
            Text("Connecting…")
        case .loggedIn:
            Text("Logged in with Connect…")
            Button("Disconnect", systemImage: "xmark.circle", action: actions.onDisconnect)
        case .disconnected:
            Text("Disconnected")
            Button("Connect", systemImage: "key", action: actions.onConnectDisconnectedHost)
        }
        Divider()
        switch actions.signIn {
        case nil:
            EmptyView()
        case .signingIn?:
            Text("Signing in…")
        case .due?:
            Text("Sign-in needed")
            Button("Sign in…", systemImage: "person.badge.key", action: actions.onSignIn)
        case .signedIn?, .unknown?:
            Button("Sign in again…", systemImage: "person.badge.key", action: actions.onSignIn)
        }
        Button("Sign-in command…", systemImage: "gearshape", action: actions.onEditSignInCommand)
        Divider()
        Button("Forward a port…", systemImage: "arrow.left.arrow.right", action: actions.onForwardPort)
        ForEach(actions.portForwards) { entry in
            SidebarPortForwardMenu(
                entry: entry,
                onTryAgain: actions.onTryPortForwardsAgain,
                onStop: { actions.onStopPortForward(entry.forward) }
            )
        }
        Divider()
        Toggle(isOn: actions.usesTmuxPrefix) {
            Label("Use this host's tmux prefix", systemImage: "keyboard")
        }
        Divider()
        // A menu shows text as an item that can't be chosen.
        switch actions.shellStartupCheck?.outcome {
        case nil:
            EmptyView()
        case .interactiveStartupWorks:
            Text("Shell startup is fine")
        case .usesLoginShellOnly:
            Text("CLIs skip your interactive shell startup, which starts another program")
            shellStartupHelpButton
        case .blocked:
            Text("Your shell startup keeps CLIs from starting!")
            shellStartupHelpButton
        }
        // Also checks the shell startup again, as after you change its startup files.
        Button("Check this host…", systemImage: "stethoscope", action: actions.onCheckHost)
        Divider()
        Button("Remove host", systemImage: "minus.circle", role: .destructive, action: actions.onRemove)
    }

    private var shellStartupHelpButton: some View {
        Button("Shell startup help", systemImage: "questionmark.circle") {
            NSWorkspace.shared.open(AppLinks.userGuideSSHShellStartupURL)
        }
    }
}
