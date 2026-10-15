import Foundation

/// The part of Pi's and OpenCode's extensions that tells a tab on an SSH host what the CLI does: the host's files are
/// out of the app's reach there, so the extension sets the window option that the title of the tab's tmux session
/// shows, which tmux passes on to the tab; see `RemoteCLIActivityTitle`. It does so only when started with
/// `optionVariable` naming the option, inside tmux.
///
/// The extension calls `showInTmux(activity, waitingFor)` whenever it would report, and the option changes only when
/// the value does, one `tmux` at a time. No activity empties it, so the title is the CLI's own again. What it waits for
/// is kept to one line, as a title is.
enum LiveSessionTmuxActivity {
    static let optionVariable = "JUSTSESSIONS_TMUX_ACTIVITY_OPTION"

    /// JavaScript for the top level of a module that imports `execFile` from `node:child_process`. `refresh-client -S`
    /// makes tmux before 2.6 redraw the title, as `RemoteClaudeActivityRelay` says.
    static let javascript = #"""
        // On an SSH host, the app reads what this CLI does from the title tmux gives its tab, which shows this option.
        const showInTmux = (() => {
          const option = process.env.\#(optionVariable);
          const pane = process.env.TMUX_PANE;
          if (!option || !pane) return undefined;
          let shown;
          let wanted = "";
          let isSetting = false;
          const setWanted = () => {
            if (wanted === shown) {
              isSetting = false;
              return;
            }
            isSetting = true;
            const value = wanted;
            // tmux reads an argument that ends in ";" as the end of its command.
            const argument = value.endsWith(";") ? `${value.slice(0, -1)}\\;` : value;
            const command = ["set-option", "-wq", "-t", pane, option, argument, ";", "refresh-client", "-S"];
            execFile("tmux", command, { timeout: 5000 }, () => {
              shown = value;
              setWanted();
            });
          };
          return (activity, waitingFor) => {
            const reason = (waitingFor ?? "").replace(/[\u0000-\u001f\u007f]+/g, " ").slice(0, 200);
            wanted = activity ? `${activity}:${reason}` : "";
            if (!isSetting) setWanted();
          };
        })();
        """#
}
