# SSH hosts

[Back to requirements](../README.md)

Live SSH checks follow [SSH development testing](../../development/ssh-testing.md); simulated tests don't establish live coverage.

## Adding a host

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| SSH-01 | A host is added by `~/.ssh/config` alias or `user@hostname` and listed under its own heading below This Mac. Names that would map outside the mirrors' folder, such as `.` or `..`, are refused. | `f8eeafa`, `a2be251`, `4c7df7a` | `RemoteHostFolderSafetyTests` |
| SSH-02 | The Add SSH host sheet reads its field as ssh would: a pasted `ssh devbox` adds `devbox`; a port (`host:port`, `ssh -p`, `ssh://`) shows the `~/.ssh/config` lines to add instead; anything else says to enter only the host. Under the field it shows where an alias connects (`ssh -G`). A host that resolves to the same machine as a listed one can't be added again. | `4659901` | `RemoteHostInputTests`, `SSHHostSameMachineCheckTests`, `SSHHostConfigurationTests` |
| SSH-03 | Before adding, the app logs in the way its background commands do. A failure says why (not found, no answer, login refused, untrusted host key, …) and offers **Try again** or **Add anyway**. | `bb94daa` | `RemoteHostConnectionCheckTests`, `SSHConnectionProblemTests` |
| SSH-04 | The sheet is short: an introduction, the passwordless SSH requirement in sight, and setup help that expands. | `1fdae49` | Manual |

## Connections

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| SSH-20 | Background connections pass `-T`, `RemoteCommand=none`, and `ClearAllForwardings=yes`, so aliases set up for logging in by hand still work. Tabs pass only `RemoteCommand=none` and keep port forwards. | `bb94daa` | `NonInteractiveSSHOptionsTests`, `SSHConfigOverrideTests` |
| SSH-21 | `ssh` and `rsync` run with the login shell's environment (such as `SSH_AUTH_SOCK` for 1Password or Secretive, and the `PATH` a `ProxyCommand` needs), read once at launch. | `09cfb34` | `SSHProcessEnvironmentTests`, `LoginShellEnvironmentTests` |
| SSH-22 | A host's background commands share one login (`ControlMaster=auto`, a socket per host in `/tmp/justsessions-ssh-<uid>`, `ControlPersist=60`). A host whose config sets its own `ControlPath` keeps the user's settings. Tabs keep their own connections. Removing a host ends its shared connection. | `0489e83` | `SSHConnectionSharingTests` |
| SSH-23 | A dead connection is given up after about 30 seconds (`ServerAliveInterval 10` × 3). | `b82be85`, `43ade47` | `NonInteractiveSSHOptionsTests` |
| SSH-24 | Every shell the app starts on a host has `JUSTSESSIONS=1`, and CLIs start through `$SHELL -lic`. | `f8eeafa`, `a719190` | `RemoteCLICommandBuilderTests` |
| SSH-25 | Quoting is correct under `sh`, `bash`, `zsh`, and `dash`. | `4c7df7a`, `475817a` | `ShellQuotingPropertyTests` |

## Shell startup check

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| SSH-40 | The app checks a host's shell startup by running its shell in a terminal with a marker and tracing bash's or zsh's startup to find where it stopped. If `$SHELL -lc` runs the marker, the host uses it for every command; otherwise the host is blocked. | `a719190` | `RemoteShellStartupCheckTests`, `RemoteShellStartupCheckEndToEndTests` |
| SSH-41 | A host is checked when added, on its first refresh without a result, after a failed refresh or one that finds no CLIs (once per run), and any time from **Check shell startup** in its ⋯ menu, which also shows the last result. A blocked host shows a ! warning that opens the guide. | `a719190`, `1b9c8db`, `ec88022` | `RemoteShellStartupStoreTests`, `RemoteShellStartupTests` |

## Listing and copying

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| SSH-60 | Each tool's history is copied with `rsync` into the local cache and read by the same adapters as this Mac. | `f8eeafa` | `RemoteSessionMirrorTests` |
| SSH-61 | A refresh copies one tool at a time and lists each tool's sessions as soon as it is copied; other tools keep their earlier listing. The heading shows progress (such as 2/6) and its tooltip names the tool; an empty host says "Copying Codex sessions (2 of 6)…". | `ec75564` | `RemoteToolByToolListingTests`, `RemoteSessionToolByToolDiscoveryTests` |
| SSH-62 | Each copy first asks the host's login shell where each tool keeps its history (`CLAUDE_CONFIG_DIR`, `CODEX_HOME`, `KIRO_HOME`, Pi's variables and `sessionDir`), keeps it in `tool-folders.json`, and copies and deletes from there, quoting paths the host's shell would split. Antigravity uses its standard folder. | `ea38f66`, `37c0b4c` | `RemoteToolFoldersTests`, `RemoteToolFoldersLookupTests` |
| SSH-63 | Only session files leave a host. Pi's extension folders, settings, and credentials stay; OpenCode's sessions come from a snapshot built on the host with `python3`, so its accounts, credentials, and tool output never leave it. | `e0831a5`, `c8af982` | `PiRemoteMirrorTests`, `OpenCodeRemoteMirrorTests`, `AntigravityRemoteMirrorTests` |
| SSH-64 | Refresh covers every host, and each heading has its own refresh. A host that fails shows the classified reason on its heading; the others still list. A tab whose CLI exits, or a new session's tab that is left or closed, refreshes its own host. | `a2be251`, `b20f964`, `bb94daa` | `HostRefreshAndLaunchTests` |
| SSH-65 | The installed CLIs on a host are found with `command -v` in the same call that lists its tmux sessions. | `12abb26` | `RemoteHostStatusProbeTests`, `InstalledCLIsTests` |

## Sessions on a host

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| SSH-80 | Resume, Branch, New session, and Delete work on SSH hosts for all six CLIs, through `ssh -t` and the host's login shell. | `f8eeafa`, `0845ae2`, `5c1f348`, `88d0c7c`, `e0831a5`, `c8af982` | `Remote/*/…LaunchTests`, `Remote/*/…DeletionTests` |
| SSH-81 | A folder typed for a new session or project is looked up on the host first, so a typo is reported in the sheet. A missing folder can be created with **Create folder and add** in Add project, or **Create folder and start** (**Create folder and open terminal**) in New session (`mkdir -p`); editing the path or changing the host withdraws the offer. | `a2be251`, `f2b470a`, `860985d` | `RemoteFolderResolverTests`, `RemoteNewSessionTests`, `HostRefreshAndLaunchTests` |
| SSH-82 | Remote CLIs run in `tmux new-session -A` under a name tied to the session, so a dropped connection or closed tab leaves them running and resuming reattaches. Hosts without tmux run the CLI directly. Closing a remote tab asks Keep running or End session, as on this Mac; an ended tab offers Reconnect; sessions still running on a host are marked and can be ended from the sidebar. | `fefce02`, `a4101ee` | `RemoteTmuxKeepAliveTests`, `RemoteTmuxReattachTests` |
| SSH-83 | A new session on a host links to the first session that appears in its project, except Claude Code with `--session-id` support (DSC-42). | `0845ae2`, `5c8ad54` | `RemoteNewSessionTests`, `RemoteClaudeNewSessionLinkingTests` |
| SSH-84 | SSH hosts report only whether a CLI runs, not what it is doing, so they show no activity detail and send no notifications. | `8fa46b7` | `CLIActivitySyncTests` |
