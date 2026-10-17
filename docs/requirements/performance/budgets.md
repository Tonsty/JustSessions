# Performance budgets

[Back to requirements](../README.md) · [Performance log](../../development/performance.md)

Each line is a result the project measured and wants kept, with the mechanism that delivers it. A change that removes a mechanism, or touches a hot path listed here, reruns the named measurement and records the result in [performance.md](../../development/performance.md).

Measurement suites live in `Tests/JustSessionsTests/Performance/` and record only with `JUSTSESSIONS_PERF=1`; use a release build (`swift test -c release`). Numbers are from the commits named, on the hardware those commits describe. Treat them as budgets to stay near, not exact thresholds: a clear regression against them needs a reason.

## Sidebar and store

| ID | Budget and mechanism | Origin | Measurement |
| --- | --- | --- | --- |
| PERF-01 | With about 1,400 sessions (release build): a store change redraws the sidebar in about 6 ms; a search keystroke takes about 24 ms, p90 38 ms; a refresh after the first reads files for about 50 ms. | `2b6e892` | `SidebarInteractionMeasurements` |
| PERF-02 | A session's id and project key are worked out once (the key resolves symlinks, never per redraw). Listed sessions are indexed by id and by project. | `2b6e892` | `SidebarInteractionMeasurements` |
| PERF-03 | The sidebar's grouped and filtered projects, and the filter bar's counts, are cached behind input-equality checks. The current time joins at minute precision. A group stores its latest activity instead of computing it per sort comparison. Tooltip dates are formatted once per value. The selection walk is skipped while nothing is selected. | `2b6e892`, `4878267` | `SidebarInteractionMeasurements`, `FilteredSidebarProjectionTests` |
| PERF-04 | Session rows sit in the sidebar's lazy list one by one, so an expanded project builds only rows in sight. One activity change re-runs about 24 project and 24 session rows, the same at 300 and 2,000 sessions. | `2b6e892`, `4deeb13` | `SidebarInteractionMeasurements` |
| PERF-05 | The store doesn't publish when nothing changed, including unchanged CLI activity and the notification bell's wait times. | `b48e8af`, `4deeb13`, `3e0b7b1` | `SidebarStoreObservationTests`, `WaitingForYouStartTimesSyncTests` |
| PERF-06 | Dragging the sidebar divider does no conversation work, and a width change under a point causes no relayout. | `9e6c11c`, `8c199d4` | `SidebarResizeHandleTests` |
| PERF-07 | A pointer move while a tab or a group is dragged along the tab bar re-runs only the shifts of the items in its row, and nothing in another window; a tab's body runs only as the dragged item passes another. On a 1,400-point bar of 18 tabs, a move takes about 0.3 ms for a tab and 1.5 ms for a group, against 0.7 and 3.2 ms when the tabs re-ran. | `bf44b56b` | `TabBarDragMeasurements`, `TabBarDragDisplayTests` |

## Discovery and refresh

| ID | Budget and mechanism | Origin | Measurement |
| --- | --- | --- | --- |
| PERF-20 | What was read from each session file is kept while its size and modification date stay the same, so a refresh reads only files a CLI wrote to. | `2b6e892` | `SessionFileSummaryCacheTests` |
| PERF-21 | Validated discovery summaries persist across launches in `~/Library/Caches/dev.zichaoyang.justsessions/SessionSummaries`, written atomically with no data protection class (folder 0700, file 0600), so they stay readable. | `b48e8af`, `a7d1b6d` | `PersistentSessionSummaryCacheTests` |
| PERF-22 | Titles stop at the first non-blank line instead of splitting a huge prompt. Subagent summaries are cached per file and their prompts read only to the first one. | `2b6e892`, `27c9939` | `SubagentConversationsTests` |
| PERF-23 | Slow lookups run off the main thread and once: the login shell's `PATH` and environment at launch, the `--session-id` check once per command line, installed terminal fonts. | `022aad5`, `758b100`, `09cfb34`, `6cd0a7e` | `ClaudeSessionIDFlagSupportConcurrencyTests` |
| PERF-24 | A host refresh logs in once through the shared SSH connection. | `0489e83` | `SSHConnectionSharingTests` |
| PERF-25 | Timestamps parse with `Date.ISO8601FormatStyle` (about 50 times faster than `ISO8601DateFormatter`, with no lock between parallel readers). | `d47db56`, `4c7df7a` | `ISO8601TimestampParserTests` |
| PERF-26 | Only one window copies an SSH host; the others read its copy from disk. A warm copy of the test VM's six tools takes about 0.8 to 1.2 s, and the status probe 0.1 to 0.7 s (no network latency, about 1 MB of history). | `b38a341` | `SharedRemoteCopyTests`, [performance.md item 26](../../development/performance.md#26-refreshing-hosts-on-their-own) |

## Deletion

| ID | Budget and mechanism | Origin | Measurement |
| --- | --- | --- | --- |
| PERF-40 | Deleting 150 of 2,000 sessions never freezes the window (it took over two minutes before). Deleted sessions leave the list in batches at most twice a second; progress lives in its own object that only the progress bar observes. | `b82be85` | `BulkSessionDeletionTests` |
| PERF-41 | Claude Code deletion batches its index writes. | `b48e8af` | `ClaudeDeletionIndexBatchTests` |

## Reader

| ID | Budget and mechanism | Origin | Measurement |
| --- | --- | --- | --- |
| PERF-60 | Scrolling a transcript (release build, median step): about 4.8 ms with 240 entries and 16.3 ms with 640. Scrolling never updates `TranscriptScrollView`. | `6bf3385`, `ab02d9e` | `TranscriptInteractionMeasurements` |
| PERF-61 | Loaded entries are laid out in a plain stack on purpose (a lazy stack froze the window), bounded by `TranscriptPagingModel.maximumRetainedPageCount`. The entries are an Equatable `TranscriptEntriesStack` whose inputs don't change while scrolling. | `5ae6c53`, `6bf3385` | `TranscriptEntriesStackTests`, `TranscriptInteractionMeasurements` |
| PERF-62 | The search context is Equatable and holds the position controller, never a closure. The reader uses no `.scrollPosition(id:)` or `.scrollTargetLayout()`; `TranscriptScrollPositionController` records and restores position. | `6bf3385`, `ab02d9e` | `TranscriptSearchContextTests` |
| PERF-63 | Transcript text is copied and searched only while Find has a query, and converted for AppKit only when a block's text, style, colors, or matches change. No transcript view reads the whole environment. `AttributedString` converts to `String` through the character slice (`plainText`), never `String(text.characters)`. | `d47db56` | `AttributedStringPlainTextTests`, `TranscriptTextBlockTests` |
| PERF-64 | Markdown is prepared on the reader actors and reused for rendering and search. | `b48e8af` | `PreparedTranscriptMarkdownTests` |
| PERF-65 | Each image decodes once for every reader showing it, keyed by a digest of its bytes, kept in an `NSCache` of at most 128 MiB of pixels, off the main thread. Opening a session of 24 screenshots again takes about 0.36 s of CPU; four readers about 2.0 s. | `51e64b9`, `d4f0a5d` | `TranscriptImageDecoderTests`, `TranscriptImageDecodingMeasurements` |
| PERF-66 | Message search reads sessions with images left undecoded. | `5971a58` | `MessageSearchReadingMeasurements` |
| PERF-67 | A Pi session file of about 95 MiB previews in about 1.2 s: a first pass scans each line's bytes to find the current branch, a second decodes only its entries. Text-only tool results are never decoded for images. | `d89ae09`, `475817a`, `d4f0a5d` | `PiLineHeadScannerTests` |
| PERF-68 | An OpenCode page reads only its own messages; the index reads ids only. At 10,000 messages the latest page takes about 2.2 ms and five more pages about 13 ms. | `d1de1d6` | `OpenCodeTranscriptPagingMeasurements` |
| PERF-69 | Unchanged transcript indexes are reused and extended for appended lines instead of rebuilt. | `b48e8af`, `6f9363f` | `TranscriptIncrementalIndexTests` |
| PERF-70 | Message search indexes in the background, most recent first, reads each session once until it changes, and drops its text from memory a minute after the last search. | `1bb0b55` | `SessionMessageIndexerTests` |
| PERF-71 | A grown Codex session's search text resumes from its saved final page after a SHA-256 check of every byte it was read from; any other change reads it in full. A one-record append to a 27 MiB rollout takes about 36 ms instead of 300, and to a 500 MiB log about 200 instead of 690. Cold reads and cache hits stay as they were; a session's first read keeps no resume state. | `b0d40a5f` | `CodexSessionTextResumerTests`, `IncrementalMessageSearchMeasurements` |
| PERF-72 | Typing in a Rename dialog redraws only the dialog, not the browser and sidebar: about 12 ms per keystroke with 4 tabs and 35 projects, against 60 ms when it redrew them. | `46660c11` | Manual: `docs/development/performance.md` item 27 |

## Terminals

| ID | Budget and mechanism | Origin | Measurement |
| --- | --- | --- | --- |
| PERF-80 | A hidden tab's output is batched (8 Hz) and its drawing waits; selecting it flushes and redraws. | `b48e8af` | `TerminalOutputCoalescerTests`, `TerminalVisibilityMeasurements` |
| PERF-81 | A selected tab in a minimized window is treated as hidden: a TUI repainting 40 rows at 30 fps uses about 3.4% of a core instead of 22%. Restoring flushes and redraws. | `9c288ff` | `TerminalInsetViewMinimizedWindowTests`, `TerminalWindowVisibilityMeasurements` |
| PERF-82 | Typing stays at about 1.9 ms p50 keystroke-to-echo beside one visible and five hidden terminals each printing a 2 MB/s log. No cross-terminal scheduler is needed; recheck after a SwiftTerm upgrade. | `65b3637` | `TerminalFairnessMeasurements` |
| PERF-83 | A Ghostty tab pauses reading while 4 MiB of output waits. In the repaint workload its main thread uses about 1.2% of a core against SwiftTerm's 14.8%. | `8d6e97d` | `GhosttyOutputBackpressureTests`, `TerminalEngineMeasurements` |
| PERF-84 | SwiftTerm's Metal renderer stays off until `TerminalEngineMeasurements` shows main-thread gaps no worse than Core Graphics drawing (under about 35 ms when measured), no dropped frames, no extra hidden-tab drawing, and a real CPU saving. | `1533250` | `TerminalEngineMeasurements` |
| PERF-85 | In an SSH tab to the test VM, a keystroke echoes in about 1.5 ms at p50 instead of 15–20 ms (SSH-28), and Esc reaches a CLI in tmux 3.4 in about 47 ms instead of 520 ms (SSH-86). The network's round trip comes on top of both; nothing hides it. | `b0dc6dd` | Live run of the tab's command against the test VM; see [item 29](../../development/performance.md#29-typing-in-an-ssh-tab) |
| PERF-86 | Starting a CLI in an SSH tab asks only the login shell whether a function stands in for it (SSH-87): about 0.6 ms on the test VM's bash. Asked as a program, `functions` ran Ubuntu's command-not-found handler first, about 40 ms of every tab's start and reconnect. | `6e3c34a` | `RemoteCLIInvocationTests`; live timing on the test VM, see [item 30](../../development/performance.md#30-starting-a-cli-in-an-ssh-tab-ran-bashs-command-not-found-handler) |
| PERF-87 | Following sessions with no tab on an SSH host (SSH-92) costs one `tmux list-panes` per host every 3 seconds at most, through the shared connection, and none while no such session runs. One listing took 111 to 130 ms against an Ubuntu 24.04 container with tmux 3.4 and a bash login shell (20 runs); a host's slow login shell adds its startup to each. The sync never waits for it. | `b7c579e` | `RemoteDetachedActivityTests` |
| PERF-88 | The activity sync finds the listed session of each tmux session through the id index, not by going through every listed session once a second: with 3,365 sessions listed, 3,000 of them on an SSH host, and 56 running in tmux with no tab, its main-actor work fell from 29–32 ms a second to 0.5 ms in the app, and from 4.5 to 0.1 ms of main-thread CPU a sync in `CLIActivitySyncMeasurements` (20.3 to 0.1 ms with 10,365 listed and 100 running). A tool whose SSH copy lists the same sessions as before isn't relisted, so the whole list isn't sorted, compared, published, and the tabs saved for it: an unchanged step took 5–24 ms with 3,365 listed and takes 1–5 ms (21.6 to 3.1 ms with 10,000 in `RemoteToolStepMeasurements`). Unchanged tmux names and login state don't publish (PERF-05). | `ec3f820d` | `CLIActivitySyncMeasurements`, `RemoteToolStepMeasurements`, `RemoteToolByToolListingTests`, `SidebarStoreObservationTests`; live run against the test VM, see [item 32](../../development/performance.md#32-the-activity-sync-went-through-every-listed-session-for-every-tmux-session) |

## Method

- Profile a build made like the release (same SDK), with an accessibility client such as Raycast running, and leave the SwiftUI instrument out of CPU profiles. See [How to profile](../../development/performance.md#how-to-profile).
- Activity syncs once a second; a new tab waiting to link refreshes this Mac every 6 seconds and copies an SSH host every 10. On their own, while a workspace window shows on screen, this Mac refreshes every minute and each SSH host every 5 minutes. A host with sessions running in tmux and no tab open is listed every 3 seconds. Don't tighten these without measuring.
