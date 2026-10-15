# CLI activity and notifications

[Back to requirements](../README.md)

## Status marks

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| ACT-01 | Session rows, project rows, open-tab rows, and tabs show what a CLI is doing: a turning arc while it works, an amber mark while it waits on your answer, a green dot while it waits for your next prompt, a hollow circle once it ended in a tab still open. A session nothing runs shows its age. | `8fa46b7` | `SessionActivitySummaryTests`, `ProjectActivitySummaryTests` |
| ACT-02 | A CLI that finished its turn while its terminal was off screen, or the app was in the background, shows a larger blue dot instead of the green one. It clears when its tab is selected or shown in a split, or at the next sync once the app is in front with it selected. It stays while the CLI runs, even after its notification is gone; a CLI that stops is forgotten. | `ab6eae7`, `8ddfcf5`, `a5c78bf` | `UnseenFinishedTurnsTests`, `UnseenFinishedTurnSyncTests`, `UnseenFinishedTurnEndToEndTests` |
| ACT-03 | A project, and a collapsed tab group in the bar or in Open tabs, shows the most pressing status among its sessions, from one shared summary. | `8fa46b7`, `26e7ae1`, `3e01aba` | `ProjectActivitySummaryTests` |
| ACT-04 | What a session row shows is decided by `ConversationStore.sessionRowStatusSource(of:)`, so tests check the same decision the row draws. | `4029d79` | `SessionRunStatusUnseenTests` |

## Sources

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| ACT-20 | Claude Code's state (busy, waiting with what it waits for, idle, shell) comes from its live registry. On an SSH host, a relay in the tab's tmux session passes the host's registry on to the tab through its title (SSH-90). | `8fa46b7`, `0570801` | `ClaudeLiveSessionActivityTests`, `ClaudeLiveSessionRegistryTests`, `RemoteCLIActivityTitleTests` |
| ACT-21 | Codex's state comes first from its terminal title (`tui.terminal_title=["activity","run-state","thread-id"]`, LIV-04): `Ready` is idle; `Working`, `Thinking`, `Waiting` (for a background terminal), `Starting`, and `Undoing` are working; `Action Required` (Codex 0.128+) is waiting on you, with no reason given. A title with no run state, as from Codex before 0.124 or before its first title, falls back to its session file's turn records, read once to the end and then only as it grows; there a turn that started before the CLI did counts as idle, and a wait on you reads as working. | `8fa46b7`, `ec5e77a`, `b2cb1bf` | `CodexTitleActivityTests`, `CodexRolloutTurnTrackerTests`, `CodexTurnStateTests`; live check over SSH with Codex 0.160.0 |
| ACT-22 | Pi and OpenCode report working, waiting, and idle through the app's extension: Pi from `agent_start` to `agent_settled` (0.80.4+) and waiting while an extension prompt is open (0.84.4+); OpenCode waiting while a permission or question of the session or a subagent is open, working while busy or retrying. On an SSH host, the extension passes this on to the tab through its title (SSH-91). | `f648db1`, `b3962b3` | `PiAndOpenCodeActivityEndToEndTests`, `RemoteLiveSessionReportingTests` |
| ACT-23 | Activity is synced once a second for every tab on this Mac, every session running in tmux with no tab, and every Codex, Claude Code, Pi, or OpenCode tab on an SSH host, read from its title (SSH-84). Antigravity, Kiro CLI, and other CLIs on SSH hosts report only that the CLI runs. | `8fa46b7`, `b2cb1bf`, `0570801`, `b3962b3` | `CLIActivitySyncTests`, `DetachedCLIActivityTmuxTests`, `CodexTitleActivityTests`, `RemoteCLIActivityTitleTests` |
| ACT-24 | Each window counts other windows' tabs, and doesn't follow their CLIs as detached tmux sessions, so only the window with the tab reports on it. | `0f3fd89` | `SessionStatusAcrossWindowsTests` |

## Notifications

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| ACT-40 | A Claude Code, Codex, Pi, or OpenCode session on this Mac, and a Codex, Claude Code, Pi, or OpenCode tab on an SSH host, posts a macOS notification when its turn ends. Claude Code, Pi, and OpenCode also notify when they stop mid-turn for your answer, and so does Codex 0.128 or later, from its title. | `33931f7`, `ec5e77a`, `f648db1`, `b2cb1bf`, `0570801`, `b3962b3` | `SessionNotificationSyncTests`, `SessionAttentionTrackerTests`, `CodexTitleActivityTests`, `RemoteCLIActivityTitleTests` |
| ACT-41 | Sessions in tmux with no tab notify too. A session whose tab is selected (or shown in a split) while the app is in front stays quiet. Plain terminals never notify. | `33931f7`, `ff8f38f`, `f623508` | `SessionNotificationSyncTests` |
| ACT-42 | Clicking a notification opens the session's tab in whichever window has it, or reattaches to its CLI in tmux. | `33931f7`, `0f3fd89` | `SessionNotificationSyncTests` |
| ACT-43 | Settings → General turns each kind off. Notifications and the unseen marks read the same transitions from one attention tracker. | `33931f7`, `ab6eae7`, `8353f1e`, `b2cb1bf` | `SessionNotificationPreferencesTests`, `SessionAttentionSourceTests` |
| ACT-44 | The bell in the sidebar header lists the sessions **Waiting for you** finds (SBF-22) in every window, the wait that started last first, with a blue dot while the list isn't empty. A tab whose terminal shows in its window is left out. Each row shows the CLI, the session, its project, why it waits, and for how long. | `3e0b7b1` | `NotificationBellEndToEndTests`, `NotificationBellAcrossWindowsTests`, `NotificationBellEntryOrderTests` |
| ACT-45 | A session stopped for your answer stays in the bell until its CLI stops waiting; one that finished its turn leaves once you look at it. A wait keeps its start time while reworded, through reads that tell nothing, and when its tab closes with the CLI in tmux; a question after a finished turn starts a new wait. | `3e0b7b1` | `WaitingForYouStartTimesTests`, `NotificationBellEndToEndTests` |
| ACT-46 | Clicking a bell row shows the session as its notification does (ACT-42), except that a CLI in tmux with no tab reattaches in the bell's window. The bell lists sessions whatever Settings → General or System Settings turn off. | `3e0b7b1` | `NotificationBellAcrossWindowsTests`, `NotificationBellEndToEndTests` |
