# Following a tab's CLI, and live names

[Back to requirements](../README.md)

A tab stays linked to the session its CLI is actually in, so its title, sidebar row, activity, and the session reopened at launch all match. The behavior is specified in Gherkin under `Tests/JustSessionsTests/Gherkin/Features` and runs in `make test`.

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| LIV-01 | A name set with `/rename` in Claude Code shows in the tab and sidebar row while the tab is open. | `397a5b7`, `2863743` | `RenameInClaudeCodeTab.feature` |
| LIV-02 | Names a CLI appends to its files apply within about a second for open tabs on this Mac: Claude Code's `custom-title` line, Pi's `session_info`, Codex's `thread_name` in `session_index.jsonl`. A name given in the app wins. | `20faa90` | `RenameFromSessionFiles.feature`, `AppendedSessionNameSourceTests` |
| LIV-03 | After `/clear`, a Claude Code tab follows its CLI to the new session, which keeps the name, and its tmux session takes the new session's name. | `2863743` | `RenameInClaudeCodeTab.feature` |
| LIV-04 | Codex tabs on this Mac start with `tui.terminal_title=["thread-id"]`, and the app's tmux passes pane titles on (`set-titles`). A tab follows Codex to the thread `/new`, `/clear`, `/resume`, or `/fork` moves it to; a thread `/new` starts appears once its first prompt is sent. | `3119b7f` | `FollowCodexThread.feature`, `CodexThreadTitleTests` |
| LIV-05 | Antigravity tabs follow the conversation named in the CLI's log ("Starting conversation update stream for …"), found once per process with `lsof`. | `03a8518` | `FollowLiveSession.feature`, `AntigravityCLILogTailTests` |
| LIV-06 | Pi and OpenCode tabs started by the packaged app carry the app's small extension (Pi `--extension`, OpenCode TUI plugin through `OPENCODE_TUI_CONFIG`), which reports the session to `LiveSessionReporting/reports/<pid>.json` and removes it on quit. A user's own `OPENCODE_TUI_CONFIG` is left in place, and that tab is not followed. | `03a8518` | `FollowLiveSession.feature`, `LiveSessionReportingTests` |
| LIV-07 | A session the CLI moved to that no refresh has listed yet gets one refresh, then the tab links to it. Every follow uses one shared linking path. | `3119b7f`, `03a8518` | `ReportedLiveSessionSourceTests` |
| LIV-08 | A session can be renamed from its tab's right-click menu and its sidebar menu. The rename is local and never changes the CLI's own title. The Rename dialog, a project's included, opens on the name shown now every time, the same session's or project's again included. | `d69b489`, `3aabdb2`, `46660c11` | `ConversationTitleAliasesTests`; the dialog's field: manual |
