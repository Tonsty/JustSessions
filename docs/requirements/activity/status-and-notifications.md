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
| ACT-20 | Claude Code's state (busy, waiting with what it waits for, idle, shell) comes from its live registry. | `8fa46b7` | `ClaudeLiveSessionActivityTests`, `ClaudeLiveSessionRegistryTests` |
| ACT-21 | Codex's state comes from its session file's turn records, read once to the end and then only as it grows. A turn that started before the CLI did counts as idle. Codex records no approval wait, so a Codex waiting on you reads as working. | `8fa46b7`, `ec5e77a` | `CodexRolloutTurnTrackerTests`, `CodexTurnStateTests` |
| ACT-22 | Pi and OpenCode report working, waiting, and idle through the app's extension: Pi from `agent_start` to `agent_settled` (0.80.4+) and waiting while an extension prompt is open (0.84.4+); OpenCode waiting while a permission or question of the session or a subagent is open, working while busy or retrying. | `f648db1` | `PiAndOpenCodeActivityEndToEndTests` |
| ACT-23 | Activity is synced once a second for every tab on this Mac and every session running in tmux with no tab. Antigravity, Kiro CLI, and SSH hosts report only that the CLI runs. | `8fa46b7` | `CLIActivitySyncTests`, `DetachedCLIActivityTmuxTests` |
| ACT-24 | Each window counts other windows' tabs, and doesn't follow their CLIs as detached tmux sessions, so only the window with the tab reports on it. | `0f3fd89` | `SessionStatusAcrossWindowsTests` |

## Notifications

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| ACT-40 | A Claude Code, Codex, Pi, or OpenCode session on this Mac posts a macOS notification when its turn ends. Claude Code, Pi, and OpenCode also notify when they stop mid-turn for your answer; Codex never sends that kind. | `33931f7`, `ec5e77a`, `f648db1` | `SessionNotificationSyncTests`, `SessionAttentionTrackerTests` |
| ACT-41 | Sessions in tmux with no tab notify too. A session whose tab is selected (or shown in a split) while the app is in front stays quiet. Plain terminals never notify. | `33931f7`, `ff8f38f`, `f623508` | `SessionNotificationSyncTests` |
| ACT-42 | Clicking a notification opens the session's tab in whichever window has it, or reattaches to its CLI in tmux. | `33931f7`, `0f3fd89` | `SessionNotificationSyncTests` |
| ACT-43 | Settings → General turns each kind off; the needs-input toggle notes that Codex can't send it. Notifications and the unseen marks read the same transitions from one attention tracker. | `33931f7`, `ab6eae7`, `8353f1e` | `SessionNotificationPreferencesTests`, `SessionAttentionSourceTests` |
