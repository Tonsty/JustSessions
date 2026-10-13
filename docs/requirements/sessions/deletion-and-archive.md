# Deletion and archiving

[Back to requirements](../README.md)

## Deleting sessions

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| DEL-01 | Every deletion asks first. The confirmation counts correctly ("1 session", never "1 sessions"), says how many subagent sessions go with it or stay on disk, and says which sessions are skipped and why. | `c84aeba`, `4c7df7a`, `0b2bd6c` | `SessionDeletionConfirmationTextTests`, `SessionDeletionLocalizationTests` |
| DEL-02 | On this Mac, Claude Code, Antigravity, and Pi sessions go to the Trash. Codex uses `codex delete --force` with a 60-second timeout; Kiro CLI `kiro-cli chat --delete-session`; OpenCode `opencode session delete`. | `c84aeba`, `4c7df7a`, `f568650`, `88d0c7c`, `c8af982` | `ClaudeConversationDeletionTests`, `CodexConversationDeletionTests`, `KiroConversationDeletionTests`, `OpenCodeConversationDeletionTests`, `AntigravityConversationDeletionTests` |
| DEL-03 | A Pi deletion moves the folder beside the session file first, then the file, so a failure leaves the session listed. It deletes only a regular file directly in a sessions or project folder, named for the session, whose first line is that session's header. | `d89ae09` | `PiConversationDeletionTests`, `PiStoreDeletionTests` |
| DEL-04 | On SSH hosts deletion is permanent and the confirmation says so. Pi's remote deletion is a POSIX `sh` script that also runs under `dash`, refuses symbolic links and non-regular files, and names the folder beside the session in the confirmation. | `0845ae2`, `e0831a5`, `475817a` | `RemoteConversationDeletionTests`, `PiRemoteDeletionTests` |
| DEL-05 | Several sessions can be deleted at once from a multi-selection or a project. Deleting one marks it as deleting at once, so the list and a second delete see it. | `d5c9dfc`, `4c7df7a` | `ConversationStoreDeletionTests`, `ProjectSessionDeletionTests` |
| DEL-06 | While several sessions are deleted, the sidebar's bottom shows "Deleting N of M…" with **Cancel**, which stops between sessions. The bar shows after 300 ms and never sticks at "Deleting 0 of 0". | `b82be85`, `901cbaf` | `BulkSessionDeletionTests` |
| DEL-07 | Deleting while a deletion runs joins it: the new sessions go after the others, count in the same progress bar, and get one report. Sessions asked for after Cancel are deleted once it stops. | `73cc919` | `DeletionJoiningTests` |
| DEL-08 | A host's refresh and a deletion from it never overlap. A deletion waits for the host's refresh; a refresh asked for during a deletion runs when it ends. A host heading's Refresh is unavailable while a deletion runs. | `1ca7426`, `b82be85` | `DeletionDuringRefreshTests`, `DeletionRefreshTests` |
| DEL-09 | A host that can't be reached or doesn't answer in time is skipped for the rest of the deletion; its sessions stay listed and the others are still deleted. | `b82be85`, `43ade47` | `BulkSessionDeletionTests`, `SSHConnectionProblemTests` |
| DEL-10 | A failure alert says how many were deleted, explains each cause once in plain English with what to do, has a title naming what failed, and stays shorter than the screen. **Try Again** is offered only when the cause may pass and retries only sessions still listed; OK stays the default. Alerts queue instead of replacing the one shown. | `43ade47` | `DeletionTryAgainTests`, `SessionDeletionReportTests`, `StoreAlertQueueTests` |
| DEL-11 | A session that is already gone counts as deleted and leaves the list without an error. | `43ade47` | `AlreadyGoneSessionDeletionTests` |
| DEL-12 | A session with an open tab in any window, or a CLI still running in tmux, offers **Close and delete session…**: after confirmation it closes the tabs, ends the tmux sessions, waits up to 5 seconds for the CLI to exit, also one an SSH host's alias or function started under the pane's shell (SSH-87), waits for a refresh already under way, then deletes. Selections and projects still skip such sessions. | `d06b5ee`, `81e53c6` | `CloseAndDeleteTests`, `CloseAndDeleteThisMacTmuxTests`, `RemoteTmuxEndingBeforeDeletionTests` |

## Projects and archiving

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| DEL-30 | A project stays in the sidebar after its last session is deleted, also after a restart. | `0797f30` | `SidebarProjectPersistenceTests` |
| DEL-31 | **Archive project** hides a project from the sidebar and never touches its sessions or folder. Archived projects come back from the host heading's **+** menu (**Archived projects (…)**, with a Restore button each) or its right-click menu. Restoring brings back sessions, names, and pins. Starting a session in, or adding, an archived folder restores it. | `d8e8b4a`, `f7f584a`, `a658f0b`, `b8755e7` | `AddProjectFromHostHeadingTests`, `SidebarProjectBatchRemovalTests` |
| DEL-32 | **Archive and delete sessions** deletes every deletable session, then archives the project; open-tab sessions and undeletable ones stay. When nothing can be deleted, the project stays. Several selected projects can do this together after one confirmation. | `04b320e`, `73cc919` | `ProjectSessionDeletionTests` |
