# Performance

[Back to JustSessions](../../README.md) · [Build and release](build-and-release.md) · [Source layout](source-layout.md)

This page tracks known responsiveness problems, the evidence for each, and what has been done about it. Update an item's status when its pull request merges, and add new findings with their measurements.

## Baseline: v1.0.8, 7 October 2026

A dev build of `083d92e` (v1.0.8) was profiled for 27 minutes of ordinary use: searching, scrolling the transcript of a session that wasn't running, switching tabs, and running CLIs in terminals. The recording was made in 13 two-minute chunks.

| Measure | Result |
| --- | --- |
| Main thread busy | 269 s in total; 7–37% of each chunk, 44 s of 120 s in the worst |
| Freezes (Hangs instrument) | 18, from 257 to 523 ms; 15 of them between 18:33 and 18:36, while reading and searching a transcript |
| Background CPU | 1–5 s per chunk; one 6 s burst of message-search indexing used 2.4 cores |

The main thread's 269 busy seconds went to two kinds of work. **Terminals** are the largest steady cost; **SwiftUI** causes the freezes.

| Work | Share | What it is |
| --- | --- | --- |
| Terminal drawing | 43% | SwiftTerm drawing rows on the CPU. In chunks spent mostly in terminals, it was 57–69% of the busy time, at up to 200 ms per second. Parsing the same output took about 12 ms per second. |
| Terminal output parsing | 13% | SwiftTerm reading the CLIs' output. |
| SwiftUI updates | 13% | Re-rendering the window's one view tree. |
| Other layout and drawing | 11% | The rest of each display cycle. |
| Hover, hit testing, and cursor updates | 8% | Run on mouse moves, through every view in the transcript: 28% of the busy time in the worst chunk. |
| Accessibility | 5% | Includes SwiftUI walking the whole responder tree to find the accessibility focus. |
| Transcript text bodies | 1% | 1.3 s in one chunk, copying text to search it with no search active. |

The accessibility walk was most of each freeze. SwiftUI only does it while an accessibility client is connected, such as Raycast, a window manager, a password manager, or VoiceOver. cmux measured Raycast querying a window about [32 times a second](https://github.com/manaflow-ai/cmux/issues/2985).

The tree is large because the transcript lays out every loaded entry, up to `TranscriptPagingModel.maximumRetainedPageCount` pages. It uses a plain `VStack` on purpose; see `TranscriptScrollView.transcriptEntries`.

## Terminal engines: Ghostty and SwiftTerm

`TerminalEngineMeasurements` runs the same output through a tab of each engine, on 9 October 2026. A script started with the tab's own `startProcess` writes the output to the tab's pseudo-terminal, so it reaches each terminal as a CLI's does. The test window is ordered front, so both engines draw.

**Method:**
- **Machine:** Apple M4 Pro, 12 cores (8 performance, 4 efficiency), 24 GB, macOS 26.6.1, the built-in Liquid Retina XDR display.
- **Build:** commit `9998098`, built by `swift test -c release` with Xcode 27.0 (Swift 6.4, macOS 27.0 SDK), not the release's SDK. SwiftTerm is the 1.15.0 fork, drawing on the CPU; Ghostty is libghostty-spm `2.2.2026100901`.
- **Runs:** three of each, alternating which engine goes first. Each result is the median, with the lowest and highest in brackets. Each memory run had a process of its own.
- **Load:** the machine was busy, so absolute CPU figures are noisy; compare the engines. Blender used 60–120% of a core and 13 GB throughout, a running copy of the app 30–80%, and WindowServer 35–48%, with bursts from Spotlight and media analysis. The load average was 5–9.
- **CPU:** process CPU from `getrusage`, as a percentage of one core. The scripts writing the output are child processes, so they don't count. Main-thread CPU comes from `thread_info`.
- **Gaps:** `MainThreadPerfHeartbeat` ticks every 20 ms. On this machine its longest gap was 25–30 ms even with the main thread almost idle, so a gap under about 30 ms is no hitch.
- **Frames:** for SwiftTerm, calls to its view's `draw(_:)`. For Ghostty, each frame its renderer hands to its layer, as the layer's new contents.

The workloads:
1. **Repaint:** 8 rows rewritten 30 times a second for 5 s, with a spinner, as in `TerminalVisibilityMeasurements`. One tab, shown.
2. **Bulk:** 20 MB in 175,920 log lines, colored, every fifth in truecolor and about every seventh with CJK text, written by `cat`. One tab, shown. Timed until the terminal has parsed all of it and its screen shows the last line.
3. **Hidden tabs:** the repaint in 5 or 10 tabs, one shown, the rest hidden through `setWorkspaceActive(false)`.
4. **Memory:** before any tab, with 10 idle tabs, and after the bulk stream in all 10 tabs. A tab's share is a tenth of the change.

**Repaint, one tab:**

| Measure | Ghostty | SwiftTerm |
| --- | --- | --- |
| Process CPU, % of one core | 4.4 (3.9–4.8) | 15.3 (13.4–15.8) |
| Main-thread CPU, % of one core | 1.2 (1.1–1.2) | 14.8 (12.9–15.3) |
| Longest main-thread gap | 28.7 ms (28.5–31.8) | 31.6 ms (28.5–41.0) |
| Frames drawn in 5 s | 151 | 149 (147–149) |

**Bulk stream, one tab:**

| Measure | Ghostty | SwiftTerm |
| --- | --- | --- |
| Time until parsed and on screen | 0.21 s (0.20–0.22) | 0.79 s (0.77–0.80) |
| Process CPU, % of one core | 352 (343–366) | 123 (122–123) |
| Process CPU time, from the medians | 0.74 s | 0.97 s |
| Main-thread CPU, % of one core | 65 (61–65) | 98 (98–99) |
| Longest main-thread gap | 26.5 ms (26.0–27.5) | 31.3 ms (30.0–32.4) |
| Frames drawn | 379 (291–381) | 35 (34–35) |

Ghostty parsed the stream about four times as fast, across several threads. It handed its layer more frames than a display can show in that time; how many reached the screen is unconfirmed.

**Repaint, one tab shown and the rest hidden:**

| Tabs | Process CPU, Ghostty | Process CPU, SwiftTerm | Main thread, Ghostty | Main thread, SwiftTerm | Longest gap, Ghostty | Longest gap, SwiftTerm |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 4.4% | 15.3% | 1.2% | 14.8% | 28.7 ms | 31.6 ms |
| 5 | 6.1% (5.4–6.8) | 18.9% (16.6–20.0) | 1.5% | 17.5% | 29.3 ms | 29.8 ms |
| 10 | 7.1% (6.7–7.3) | 17.2% (16.8–20.5) | 1.8% | 15.3% | 30.0 ms | 27.7 ms |

Each hidden Ghostty tab added about 0.3% of a core, mostly off the main thread. Hidden SwiftTerm tabs added 2–4% in all, more with 5 tabs than with 10, so the load's noise is as large as their cost. Both engines drew 149–151 frames for the shown tab.

**Memory, in MB:** the medians of three runs. The runs differed by at most 2.3 MB per tab, and for SwiftTerm by under 0.5 MB.

| Measure | Ghostty | SwiftTerm, 500 lines | SwiftTerm, 10,000 lines, shipped |
| --- | --- | --- | --- |
| Footprint before any tab | 59.8 | 59.9 | 60.0 |
| Footprint with 10 idle tabs | 212.5 | 82.6 | 83.4 |
| Footprint per idle tab | 15.3 | 2.3 | 2.3 |
| Footprint after the stream in all 10 tabs | 285.4 | 77.8 | 384.8 |
| Footprint added per full tab | 7.4 | −0.5 | 30.1 |
| Resident memory added per full tab | 55.1 | 8.4 | 39.2 |
| Scrollback kept, rows × columns | 46,341 × 125 | 540 × 115 | 10,040 × 115 |

The footprint is what Activity Monitor's Memory column shows. Read the table with these points in mind:
- **An idle Ghostty tab** costs about 15 MB, nearly all of it graphics memory: the surfaces it draws into, which hidden tabs keep too. With 10 idle tabs, `vmmap` showed 98 MB of "owned unmapped (graphics)", 30 MB of IOSurface, and 7 MB of IOAccelerator memory.
- **Ghostty's scrollback isn't in the footprint.** `vmmap` shows its terminal pages as "Memory Tag 240": with 10 full tabs, 477 MB resident but only 4 MB dirty, and the footprint is `vmmap`'s dirty total. Resident memory gives the real cost, about 55 MB per full tab. Whether macOS can reclaim those pages without losing scrollback is unconfirmed.
- **For SwiftTerm, the footprint is the cost.** Its resident figure also counts memory the allocator freed and kept.
- **One run per process.** In a process that had already run the same case, the footprint counted 0–22 MB per full SwiftTerm tab with 10,000 lines instead of 30: memory the process freed and then reused wasn't counted again.

**Scrollback differs by engine.** A Ghostty tab keeps far more scrollback than SwiftTerm does by default: 46,341 rows here, against SwiftTerm's 500 lines. Full, it holds about 55 MB, against well under 1 MB for SwiftTerm's 500 lines, or 30 MB for 10,000. A SwiftTerm tab keeps 10,000 lines (`SelectableTerminalView.scrollbackLineCount`), so terminal Find reaches that far back. Only the main screen keeps scrollback, so a CLI in tmux, which draws on the alternate screen, adds none. The app sets no limit for Ghostty, so Ghostty's default `scrollback-limit` applies. Upstream documents it as 10,000,000 bytes, so how Ghostty counts it against these 55 MB is unconfirmed.

**Profile:** one 5-second `sample` of the repaint for each engine.
- **SwiftTerm:** the main thread was busy in 721 of 3,675 samples, 20%. Parsing the output (`feed`) took 12 of them, and Core Animation's commit, drawing the view, 693. No other thread did measurable work. The drawing went to:
  - 251 samples in `NSView` drawing, where SwiftTerm's `drawTerminalContents` records each row's text;
  - 417 in updating the layer's backing store, which replays those commands. 316 of them rasterized glyphs into the 16-bit RGBA backing store this XDR display gets (`RGBAf16_mark_constmask`, `vCGCompositeConstMask_ARGB16F_vec`).
- **Ghostty:** the main thread was busy in 28 of 3,459 samples, under 1%: committing the layer's new contents, and handing output on. Ghostty's renderer thread took 29 samples, Metal's command queue 21, Ghostty's output parsing 6, and reading the pseudo-terminal 5. All threads together were busy in 94 samples, against SwiftTerm's 726.

**The libghostty-spm fork, 12 October 2026.** The pin moved to the fork's `2.2.2026100901-justsessions.2`; see [libghostty](build-and-release.md#libghostty). It makes the AppKit view's `paste(_:)` overridable, so a Ghostty tab can paste an image from the Edit menu, and it passes on Ghostty's search counts. The Paste runs only when the user pastes, and the search cases only during a search. The fork downloads the same `libghostty.a`. `TerminalEngineMeasurements` ran on the base (`db2d71d`, upstream `2.2.2026100901`) and on the fork (`90b0d60`), alternating base, fork, base, fork.

**Method:**
- **Machine:** Apple M4 Max, 14 cores (10 performance, 4 efficiency), 36 GB, macOS 27.0.1.
- **Build:** release build from `swift test -c release`.
- **Load:** other builds were running. The load average was 3–13.
- **Runs:** each figure below is the median of the test's three runs in that round. Memory is one run per round, each in a process of its own.

| Ghostty | Base, round 1 / 2 | Fork, round 1 / 2 |
| --- | --- | --- |
| Repaint, 1 tab: process CPU | 5.8% / 5.0% | 4.8% / 5.2% |
| Repaint, 1 tab: main thread | 1.5% / 1.6% | 1.4% / 1.5% |
| Repaint, 1 tab: longest main-thread gap | 24.0 / 29.6 ms | 29.7 / 28.3 ms |
| Repaint, 5 tabs, 1 shown: process CPU | 7.6% / 4.2% | 7.6% / 7.5% |
| Repaint, 10 tabs, 1 shown: process CPU | 5.8% / 2.9% | 8.9% / 6.0% |
| Bulk 20 MB: time | 0.19 / 0.20 s | 0.20 / 0.20 s |
| Bulk 20 MB: process CPU | 356% / 361% | 353% / 353% |
| Footprint per idle tab | 25.6 / 23.2 MB | 25.6 / 25.2 MB |
| Footprint added per full tab | 4.9 / 7.4 MB | 5.7 / 5.1 MB |
| Resident memory added per full tab | 52.1 / 54.5 MB | 52.9 / 52.2 MB |

No difference stands out from the load's noise:
- **CPU, one tab:** the fork used 4.8–5.2% of a core against the base's 5.0–5.8%, and main-thread CPU within 0.2 points of it.
- **CPU, hidden tabs:** the fork's medians were higher in three of four cases, but single runs overlap. With 10 tabs, the base's runs spanned 2.3–8.7% and the fork's 5.3–9.6%. The base's 5-tab median fell from 7.6% to 4.2% between its own two rounds.
- **Memory:** the base's two rounds differed by up to 2.5 MB per tab, and the fork stays within the base's range.
- **Frames:** every repaint drew 150–151 frames.

**The SwiftTerm fork's modified arrow keys, 13 October 2026.** The pin moved to the fork's `1.15.0-justsessions.3`; see [SwiftTerm fork](build-and-release.md#swiftterm-fork). It changes only how `keyDown` sends arrows, Home, and End with Shift, Option, or Control, which runs when such a key is pressed; these workloads press no key. `TerminalEngineMeasurements` (repaint, bulk, and hidden tabs) ran on the base (`ab2e037`, `1.15.0-justsessions.2`) and on the fork (`f4a5e68`, rebased since as `34d9523`), alternating base, fork, base, fork.

**Method:**
- **Machine:** Apple M4 Max, 14 cores, 36 GB, macOS 27.0.1.
- **Build:** release build from `swift test -c release`, Swift 6.4.
- **Load:** other sessions were running. The load average was 8–12.
- **Runs:** each figure below is the median of the test's three runs in that round.

| SwiftTerm | Base, round 1 / 2 | Fork, round 1 / 2 |
| --- | --- | --- |
| Repaint, 1 tab: process CPU | 5.3% / 5.7% | 7.4% / 6.3% |
| Repaint, 1 tab: main thread | 3.9% / 4.2% | 5.7% / 4.7% |
| Repaint, 1 tab: longest main-thread gap | 24.7 / 24.9 ms | 24.9 / 24.8 ms |
| Repaint, 5 tabs, 1 shown: process CPU | 6.2% / 6.7% | 21.1% / 7.8% |
| Repaint, 10 tabs, 1 shown: process CPU | 8.7% / 13.1% | 21.3% / 10.0% |
| Bulk 20 MB: time | 0.79 / 0.78 s | 0.78 / 0.80 s |
| Bulk 20 MB: process CPU | 123% / 123% | 118% / 119% |

No difference stands out from the load's noise:
- **Hidden tabs:** every engine ran high in the fork's round 1, Ghostty too, whose library didn't change: its 5-tab runs took 7.3–8.3% of a core against 2.5–5.0% in the other rounds. In round 2 the fork's medians were 7.8% and 10.0%, against base runs of 6.0–7.8% with 5 tabs and 7.6–18.7% with 10.
- **CPU, one tab:** the fork's medians were 1–2 points higher, but single runs overlap: the base's spanned 5.0–11.3% and the fork's 4.9–13.7%.
- **Bulk:** the fork took 0.78–0.80 s and 118–119% of a core, against the base's 0.78–0.79 s and 123%.
- **Frames:** the repaint runs drew 146–150 frames on the base and 144–150 on the fork.

**The SwiftTerm fork on 1.20.0, 15 October 2026.** The pin moved to the fork's `1.20.0-justsessions.1`; see [SwiftTerm fork](build-and-release.md#swiftterm-fork). It brings 81 upstream commits. Among them, cells in the default background are left to the layer's background color instead of being filled, and a cell's width is rounded to the nearest pixel, so the bench's tabs have 122 columns instead of 115. `TerminalEngineMeasurements` (repaint, bulk, hidden tabs, and SwiftTerm's two memory cases) ran on the base (`f507cf6`, `1.15.0-justsessions.3`) and on the branch (`084f8bf`), alternating base, branch, base, branch.

**Method:**
- **Machine:** Apple M4 Max, 14 cores (10 performance, 4 efficiency), 36 GB, macOS 27.0.1.
- **Build:** release build from `swift test -c release`, Xcode 27.0, Swift 6.4.
- **Load:** other sessions were running. The load average was 2.7–6.0. The display was kept awake with `caffeinate -d -i`.
- **Runs:** each figure below is the median of the test's three runs in that round. Memory is one run per round, each in a process of its own.

| SwiftTerm | Base, round 1 / 2 | 1.20, round 1 / 2 |
| --- | --- | --- |
| Repaint, 1 tab: process CPU | 15.0% / 14.9% | 13.2% / 13.1% |
| Repaint, 1 tab: main thread | 11.7% / 11.7% | 9.9% / 9.8% |
| Repaint, 1 tab: longest main-thread gap | 29.8 / 27.9 ms | 24.2 / 29.1 ms |
| Repaint, 5 tabs, 1 shown: process CPU | 17.1% / 16.6% | 15.8% / 15.6% |
| Repaint, 10 tabs, 1 shown: process CPU | 20.3% / 19.5% | 18.9% / 17.9% |
| Bulk 20 MB: time | 0.73 / 0.70 s | 0.69 / 0.70 s |
| Bulk 20 MB: process CPU | 124.6% / 123.4% | 124.5% / 124.8% |
| Footprint per idle tab | 3.2 / 3.2 MB | 3.0 / 3.1 MB |
| Footprint added per full tab | 30.2 / 30.8 MB | 30.7 / 31.4 MB |
| Resident memory added per full tab | 35.3 / 33.6 MB | 35.7 / 30.5 MB |

- **Repaint:** 1.20 used 1.0–1.8 points less of a core in every repaint case, on a grid with 6% more columns. With one tab, single runs overlap only at 14.3–14.4% of process CPU (base 14.3–17.0%, 1.20 12.7–14.4%), and main-thread CPU doesn't overlap (base 10.8–16.4%, 1.20 9.7–10.6%). Ghostty, which didn't change, used 5.1–5.4% with one tab in both, so the load stayed steady. Which upstream change saves the time wasn't profiled.
- **Bulk and memory:** no change beyond the noise. Bulk took 0.69–0.70 s against the base's 0.70–0.73 s. Footprint per tab moved by at most 1.2 MB, while resident memory per full tab differed by 5.2 MB between 1.20's own two rounds. With the 10,000-line scrollback case, a full tab added 30.7 MB of footprint in both 1.20 rounds against the base's 29.9–30.4 MB, and 35.7–37.2 MB resident against 34.7–35.4 MB.
- **Frames:** every SwiftTerm repaint drew 147–150 frames on both.
- **Metal, off:** it still draws hidden tabs, 470–484 frames with 10 tabs on both, so it stays off (PERF-84).

## Work items

| # | Item | Status |
| --- | --- | --- |
| 1 | [Timestamp parsing](#1-timestamp-parsing) | Done: #46 |
| 2 | [Transcript text searches only during Find](#2-transcript-text-searches-only-during-find) | Done: #46 |
| 3 | [Fast `AttributedString` to `String` conversion](#3-fast-attributedstring-to-string-conversion) | Done: #46 |
| 4 | [One position marker view per transcript entry](#4-one-position-marker-view-per-transcript-entry) | Done: issue #53 |
| 5 | [Text selection on very long blocks](#5-text-selection-on-very-long-blocks) | Done: selection across blocks PR |
| 6 | [Terminal drawing](#6-terminal-drawing) | Done for Ghostty, the engine you can choose in Settings: libghostty PR. SwiftTerm's Metal drawing measured and not turned on: issue #52 |
| 7 | [The search context changes on every transcript update](#7-the-search-context-changes-on-every-transcript-update) | Done: scrolling PR |
| 8 | [Scrolling re-rendered every transcript entry](#8-scrolling-re-rendered-every-transcript-entry) | Done: scrolling PR |
| 9 | [SwiftUI's scroll position tracking](#9-swiftuis-scroll-position-tracking) | Done: issue #55 |
| 10 | [Message search decoded every image](#10-message-search-decoded-every-image) | Done: issue #59 |
| 11 | [Codex's compacted records are parsed in full](#11-codexs-compacted-records-are-parsed-in-full) | To investigate |
| 12 | [Every reader decoded its own images](#12-every-reader-decoded-its-own-images) | Done: issue #62 |
| 13 | [Each OpenCode page read every message's data](#13-each-opencode-page-read-every-messages-data) | Done: issue #60 |
| 14 | [A CLI activity change updates only the rows in view](#14-a-cli-activity-change-updates-only-the-rows-in-view) | Measured, no change: issue #61 |
| 15 | [Terminals in minimized windows drew as if in sight](#15-terminals-in-minimized-windows-drew-as-if-in-sight) | Done: issue #63 |
| 16 | [Typing beside flooding terminals](#16-typing-beside-flooding-terminals) | Measured, no change: issue #58 |
| 17 | [SSH connections during a remote refresh](#17-ssh-connections-during-a-remote-refresh) | Changed, not measured live: issue #64 |
| 18 | [Workspace windows repeated discovery and message indexing](#18-workspace-windows-repeated-discovery-and-message-indexing) | Done: issue #57 |
| 19 | [The working spinner re-rendered the window 30 times a second](#19-the-working-spinner-re-rendered-the-window-30-times-a-second) | Done: #180 |
| 20 | [The notification bell's list on each sidebar redraw](#20-the-notification-bells-list-on-each-sidebar-redraw) | Measured, no change: issue #176 |
| 21 | [Every sidebar row hosted its hover menus](#21-every-sidebar-row-hosted-its-hover-menus) | Done: #199 |
| 22 | [The first right-click built the window's accessibility tree](#22-the-first-right-click-built-the-windows-accessibility-tree) | Measured, no change |
| 23 | [Show N more under each project](#23-show-n-more-under-each-project) | Measured, no change |
| 24 | [A growing Codex session's search text was read in full on every change](#24-a-growing-codex-sessions-search-text-was-read-in-full-on-every-change) | Done: issue #56 |
| 25 | [What a tab switch still costs](#25-what-a-tab-switch-still-costs) | Done: #218 and this change |
| 26 | [Refreshing hosts on their own](#26-refreshing-hosts-on-their-own) | Measured on the test VM; done |
| 27 | [Typing in a Rename dialog](#27-typing-in-a-rename-dialog) | Done: this change |
| 28 | [Dragging a tab or a group along the tab bar](#28-dragging-a-tab-or-a-group-along-the-tab-bar) | Done: this change |
| 29 | [Typing in an SSH tab](#29-typing-in-an-ssh-tab) | Done: #235 |
| 30 | [Starting a CLI in an SSH tab ran bash's command-not-found handler](#30-starting-a-cli-in-an-ssh-tab-ran-bashs-command-not-found-handler) | Done: this change |

### 1. Timestamp parsing

**Evidence:** the 14 s indexing burst spent 2.9 s in `ISO8601DateFormatter`, which parses through ICU. Its two shared formatters sat behind one lock, so the indexer's parallel readers also waited for each other.

**Change:** `ISO8601TimestampParser` uses `Date.ISO8601FormatStyle`. In a benchmark of 200,000 timestamps it took 0.52 µs each, against 28 µs, and as a value it needs no lock. On 1,380 timestamps sampled from local Claude, Codex, Gemini, and pi sessions, it gave the same dates. On other inputs:

- **Finer fractions:** it keeps micro- and nanoseconds, which the formatter cut to milliseconds.
- **A leap second (`:60`):** it accepts it, which the formatter didn't.
- **A leading space:** it rejects it, which the formatter accepted. No CLI writes either form.

### 2. Transcript text searches only during Find

**Evidence:** `TranscriptSearchableText` copied its whole text into a `String` and searched it on every body evaluation, even with no query. It also read the whole environment with `@Environment(\.self)`, so any environment change re-ran it ([objc.io](https://talk.objc.io/episodes/S01E409-environment-preference-updates)).

**Change:** without a query, the body returns plain `Text` straight away. Only the view that draws highlighted matches reads the whole environment, which it needs to resolve theme colors.

Since [item 5](#5-text-selection-on-very-long-blocks), every block is an AppKit text view and none reads the whole environment: the reader resolves its text colors once from the theme and color scheme, and a block converts its text for AppKit only when its text, style, colors, or matches change.

### 3. Fast `AttributedString` to `String` conversion

**Evidence:** the indexing burst spent 1.9 s in the standard library's generic `String.init`, reading an `AttributedString` one character at a time. The cause is the SDK, not the code:

- Built with the macOS 26.5 SDK, as the release workflow's `macos-latest` runner builds, `String(text.characters)` compiles to the generic `String.init`.
- Built with Xcode 27's SDK, it calls Foundation's own conversion.
- `String(text.characters[...])` calls Foundation's conversion with either SDK.

On 10,163 text blocks from real Claude replies, the 26.5 SDK build took 348 ms the first way and 3.5 ms the second, with identical results. The v1.0.8 release binary calls the generic initializer in:
- `PreparedTranscriptMarkdown`, which prepares every transcript page;
- the search segments;
- `TranscriptSearchableText`;
- search highlighting;
- the Markdown parser's code blocks.

**Change:** these call sites now use `plainText`, which converts through the slice. Search highlighting also stops converting the text before each run again, which made it quadratic in the number of runs.

The Markdown parse itself stays. The search index stores the text as the reader displays it, block by block, so it needs the parsed blocks.

### 4. One position marker view per transcript entry

**Evidence:** each transcript entry has a `TranscriptEntryPositionMarker` background, an `NSViewRepresentable` that records the reading position. Each one adds two AppKit views, the marker and SwiftUI's host for it, and the profile shows them visited by:
- the accessibility focus walk;
- hit testing on every mouse move;
- AppKit's tracking-area updates.

In `TranscriptInteractionMeasurements`, after item 8, removing the markers takes the median scroll step from 9.7 to 4.8 ms with 240 entries, and from 34 to 17 ms with 640. It takes 200 hit tests from 494 to 417 ms. Those runs also skip the reader's own scroll handling, such as recording the reading position, so not all of the difference is the views.

**Change:** the entries' `Layout` records their ordered frames as it places them, and one AppKit observer converts those stack-local frames to scroll-view coordinates. A scroll update binary-searches the ordered frames instead of scanning every entry. Direct entry lookup remains constant-time for restoration, paging, and Find. The layout hands changed frames to a pending restoration immediately, preserving the same-pass correction when a page loads above.

`TranscriptInteractionMeasurements`, release build, median of three runs each. Every metric resets to an explicit viewport first: scrolling starts at the top; hit testing, Find, and lookup start at the midpoint. Position lookup measures 1,000 searches for the first visible entry through the same type-agnostic harness adapter on both implementations:

| Entries and accessibility | AppKit views | Scroll p50 / p95 / worst | 200 hit tests | Open Find | 1,000 position lookups |
| --- | --- | --- | --- | --- | --- |
| 240, off | 2,082 → 1,604 | 5.5 / 6.6 / 9.9 → 4.0 / 5.1 / 5.4 ms | 508 → 440 ms | 59.8 → 56.1 ms | 17.0 → 0.2 ms |
| 240, on | 2,082 → 1,604 | 5.4 / 6.8 / 7.3 → 4.1 / 5.2 / 5.6 ms | 511 → 438 ms | 116 → 103 ms | 17.0 → 0.2 ms |
| 640, off | 5,482 → 4,204 | 17.4 / 20.1 / 21.7 → 13.6 / 15.4 / 16.0 ms | 1,462 → 1,319 ms | 73.4 → 91.1 ms | 43.6 → 0.2 ms |
| 640, on | 5,482 → 4,204 | 18.2 / 20.0 / 20.4 → 14.9 / 17.2 / 18.0 ms | 1,467 → 1,283 ms | 317 → 310 ms | 44.3 → 0.2 ms |

Opening Find with 640 entries and accessibility off reproducibly regressed from 73.4 to 91.1 ms. A supplemental investigation with temporary instrumentation, which the committed harness does not include, put the extra time in synchronous SwiftUI layout during the opening turn rather than in the geometry layout: `TranscriptEntryGeometryLayout` did not place entries during that update, so rebuilding its registry is not the cause. The likely cost is the `GeometryReader` wrapper that supplies an exact transcript width to the custom layout; removing it made full-width and readable-width layout incorrect, and no small safe replacement was found. The other three Find configurations were unchanged or faster.

**Method:** Apple M4 Pro, 24 GB, macOS 26.6.1, Xcode 27.0 (Swift 6.4, macOS 27.0 SDK). The baseline was commit `895744b` with only the harness from `95ed3dd` copied over; after was `95ed3dd`. Reproduction commands:

```sh
git show 95ed3dd:Tests/JustSessionsTests/Performance/TranscriptInteractionMeasurements.swift > /tmp/issue-53-fair/TranscriptInteractionMeasurements.swift
git switch --detach 895744b
cp /tmp/issue-53-fair/TranscriptInteractionMeasurements.swift Tests/JustSessionsTests/Performance/TranscriptInteractionMeasurements.swift
for run in 1 2 3; do JUSTSESSIONS_PERF=1 swift test -c release --filter TranscriptInteractionMeasurements; done
git reset --hard 895744b
git switch issue-53-transcript-marker-geometry
for run in 1 2 3; do JUSTSESSIONS_PERF=1 swift test -c release --filter TranscriptInteractionMeasurements; done
```

Raw output is in `/tmp/issue-53-fair/baseline.txt` and `/tmp/issue-53-fair/after.txt`. The machine was not isolated; the first 240-entry baseline run was slower than the other two, so the table reports medians rather than best runs.

### 5. Text selection on very long blocks

**Evidence:** cmux found that `Text(...).textSelection(.enabled)` on macOS lays out the whole text, and drag-selecting a long block can freeze the app ([cmux #4625](https://github.com/manaflow-ai/cmux/issues/4625)). The transcript enables selection on every Markdown block.

Every selectable block is a `SelectionTextField` in a host view. Of the window's 2,082 AppKit views with 240 entries, 840 are these, against 480 for the position markers. In `TranscriptInteractionMeasurements`, after item 8, turning selection off takes the median scroll step from 9.7 to 6.0 ms with 240 entries, and from 34 to 25 ms with 640. It also takes opening Find from 27 to 21 ms.

**Measured (issue #54):** moving `.textSelection(.enabled)` from each Markdown block, code block, and table cell to the message root was tested with `JUSTSESSIONS_PERF=1 swift test -c release --filter TranscriptInteractionMeasurements`. The unchanged baseline was run three times; the prototype once before it was rejected. SwiftUI propagated selection to every `Text` leaf, including labels and list markers, instead of making one surface. The paired `SelectionTextField` and host count rose from 420 to 660 with 240 entries, and from 1,120 to 1,760 with 640. At 640 entries with accessibility off, the median scroll step regressed from 16.5–16.9 ms to 34.4 ms in the single prototype run.

**Conclusion at the time:** keep the per-block selection. One native selection surface for the mixed message hierarchy would require a custom `NSTextView`/TextKit renderer.

**Change:** a selection now runs across blocks and messages (RDR-47), so every text block is a `TranscriptTextView`, an `NSTextView` on a TextKit 1 stack it assembles itself, and `TranscriptTextSelectionCoordinator` follows a drag across them. Each block is now a `TranscriptTextView` in an `AppKitPlatformViewHost`, and the window holds one more AppKit view per block: 420 more with 240 entries. The text view caches its measured size per width and lays out again only when placed at a width its lines don't fit. Lines are padded to the height SwiftUI gave them, so document heights are unchanged.

`TranscriptInteractionMeasurements`, release build, base `b9f72d9` and the branch run alternately, three runs each, medians. Load average was 5–8 throughout, from other sessions on the machine, so the scroll steps are slower than in item 4 on both sides:

| Entries and accessibility | AppKit views | Scroll p50 / p95 / worst | 200 hit tests | Open Find | Close Find |
| --- | --- | --- | --- | --- | --- |
| 240, off | 1,300 → 1,720 | 11.0 / 11.6 / 11.9 → 10.8 / 11.8 / 12.0 ms | 487 → 397 ms | 53.2 → 33.8 ms | 24.8 → 22.3 ms |
| 240, on | 1,300 → 1,720 | 10.8 / 11.4 / 12.5 → 10.2 / 10.9 / 12.1 ms | 493 → 397 ms | 55.6 → 48.2 ms | 25.1 → 19.4 ms |
| 640, off | 3,400 → 4,520 | 30.4 / 34.2 / 39.2 → 31.3 / 34.9 / 35.3 ms | 1,295 → 1,092 ms | 96.6 → 96.1 ms | 63.3 → 60.7 ms |
| 640, on | 3,400 → 4,520 | 29.8 / 32.1 / 33.0 → 29.6 / 31.5 / 32.7 ms | 1,325 → 1,057 ms | 144 → 130 ms | 71.7 → 61.1 ms |

Scrolling is within run-to-run noise, hit testing is 15–20% faster, and Find is no slower. Document heights matched exactly: 29,576 and 78,876 points. Dragging across a single very long block, the case cmux reported, was not measured.

### 6. Terminal drawing

**Evidence:** this is the largest steady cost: 43% of the main thread's busy time over the whole recording, and up to a fifth of a core while new output took about 1%. When a change reaches the bottom row, SwiftTerm repaints from the changed rows down to the bottom of the view. TUI status lines and spinners do that constantly. The app uses SwiftTerm 1.15.0, through its [fork](build-and-release.md#swiftterm-fork), with CPU drawing.

**Change:** Ghostty, which you can choose under Settings › Appearance › Terminal › Engine, draws with Metal on its own renderer thread, and parses output off the main thread. In the repaint workload, the main thread spent 1.2% of a core on a Ghostty tab, against 14.8% on a SwiftTerm tab; see [Terminal engines](#terminal-engines-ghostty-and-swiftterm).

**SwiftTerm's Metal drawing, measured (issue #52):** the pinned SwiftTerm already has a Metal renderer, off by default, behind `setUseMetal(_:)`; no upgrade is needed to try it. It keeps each row in GPU buffers and redraws only the rows that changed, and falls back to Core Graphics if Metal can't start. The app doesn't turn it on; `TerminalEngineMeasurements` does, for its *SwiftTerm (Metal)* case, so Ghostty, SwiftTerm, and SwiftTerm with Metal run through the same output. Release build, three runs each, medians:

| Workload | SwiftTerm | SwiftTerm, Metal | Ghostty |
| --- | --- | --- | --- |
| Repaint, 1 tab: CPU | 8.8% | 8.8% | 3.4% |
| Repaint, 1 tab: main thread | 6.4% | 7.0% | 0.8% |
| Repaint, 1 tab: longest main-thread gap | 28 ms (25–35) | 182 ms (157–218) | 24 ms |
| Repaint, 1 tab: frames drawn of 150 | 150 | 136 (134–140) | 150 |
| Bulk 20 MB: time | 0.78 s | 0.79 s | 0.20 s |
| Repaint, 5 tabs, 1 shown: CPU | 10.8% | 14.3% | 4.8% |
| Repaint, 10 tabs, 1 shown: CPU | 11.9% | 19.2% | 5.6% |
| Repaint, 10 tabs, 1 shown: frames drawn | 149 | 481 | 150 |

At this SwiftTerm revision, Metal saves no CPU on these workloads, drops about a tenth of the frames, and stalls the main thread for 150–200 ms at a time where Core Graphics stays under 35 ms. With hidden tabs it costs more, not less: a hidden tab's Metal view keeps drawing, since `setNeedsDisplay` on an `MTKView` isn't stopped by a hidden ancestor the way `draw(_:)` is, so the app's hidden-tab batching (`TerminalOutputCoalescer`) would be partly undone. **Not turned on**, and no switch for it is shipped. The measurement case stays so the comparison can be run again after a SwiftTerm upgrade. Not checked: how Metal looks, selection highlights, the cursor, IME, transparency, and Retina scaling, which need a person at a real terminal.

**Plan for SwiftTerm, the default engine:**
1. Upgrade to SwiftTerm 1.20.0 by rebasing the fork onto it. Version 1.16.0 notes improved baseline performance, and 1.20.0 is the last release before breaking changes.
2. Run `TerminalEngineMeasurements` again. Metal is worth turning on only if the gaps, the dropped frames, and the hidden-tab drawing are gone and the CPU saving is real.
3. Then check visually: selection, insets, transparency, the cursor, and the app's own drawing.

The draft line-layout cache ([SwiftTerm #449](https://github.com/migueldeicaza/SwiftTerm/pull/449)) is not merged.

### 7. The search context changes on every transcript update

**Evidence:** `TranscriptScrollView` set `transcriptSearchContext` with a new `reveal` closure on every body evaluation. SwiftUI can't compare closures, so each transcript update re-ran every text block and tool-call list, and remeasured them. With the closure removed, the median scroll step halved: from 71 to 37 ms with 240 entries.

**Change:** the context holds the position controller instead of a closure, and is `Equatable`. It compares the query, the selected match, the navigation revision, and the controller by identity, which is everything text blocks read. See item 8 for the measurements together.

### 8. Scrolling re-rendered every transcript entry

**Evidence:** scrolling changes `visibleEntryIndex`, the `@State` behind the transcript's `.scrollPosition(id:)`, each time a new entry reaches the top. Each change re-ran `TranscriptScrollView.body`, which rebuilt every entry, and SwiftUI then remeasured the whole non-lazy stack. In `TranscriptInteractionMeasurements`, one scroll step took a median of 71 ms with 240 entries, and 187 ms with 640. The window can't draw during those steps, so scrolling a long transcript ran at about 14 frames a second or fewer.

**Change:** the entries are their own view, `TranscriptEntriesStack`, compared by its inputs: the transcript, the provider, and the position controller. These stay the same while you scroll, so SwiftUI skips the entries. Together with item 7:

| Measure | 240 entries, before → after | 640 entries, before → after |
| --- | --- | --- |
| Median scroll step | 71 → 9.7 ms | 187 → 34 ms |
| Worst scroll step, accessibility on | 172 → 15 ms | 459 → 62 ms |
| Opening Find | 82 → 27 ms | 222 → 70 ms |

### 9. SwiftUI's scroll position tracking

**Evidence:** after item 8, much of each scroll step is SwiftUI's own tracking for `.scrollPosition(id:)` and `.scrollTargetLayout()`. On every scroll it searches the entries for the one closest to the anchor (`ScrollStateRequestTransform.findClosestSubview`), then marks the state that changed as dirty. Both grow with the number of entries.

**Change:** the reader no longer uses `.scrollPosition(id:)`, `.scrollTargetLayout()`, or `visibleEntryIndex`. `TranscriptScrollPositionController` already recorded and restored the reading position on its own. Every entry is laid out, so it finds any loaded entry's marker without SwiftUI's help. Where the reader set `visibleEntryIndex`, it also either called `ScrollViewProxy.scrollTo` or asked the controller to restore a position:
- the initial position;
- Find's navigation;
- a page loading or going to the first message with paging;
- **First message** and **Latest message** without paging.

Scrolling no longer updates `TranscriptScrollView` at all. `TranscriptInteractionMeasurements`, release build, median of three runs each:

| Measure | 240 entries, before → after | 640 entries, before → after |
| --- | --- | --- |
| Median scroll step, accessibility off | 10.3 → 4.8 ms | 35.5 → 16.3 ms |
| Median scroll step, accessibility on | 10.8 → 4.9 ms | 37.8 → 17.6 ms |
| 60 scroll steps, accessibility off | 694 → 310 ms | 2,158 → 1,000 ms |
| Worst scroll step, accessibility off | 59 → 22 ms | 56 → 37 ms |

Hit testing and the view count are unchanged. With 240 entries and accessibility off, the first time Find opens after scrolling took 49 instead of 29 ms. Opening it again took 20 instead of 28 to 30 ms. With 640 entries, and with accessibility on, opening Find took about as long as before. The first update after scrolling seems to pay once for what each scroll step paid before.

### 10. Message search decoded every image

**Evidence:** `SessionMessageTextReader` reads a session through the reader's own page source, then drops image entries. By then each image's base64 had been decoded into `Data`, and its header read with ImageIO. A page held all of them until it was done.

**Change:** the reader takes `decodesImages`, and message search turns it off. Each image keeps its entry, holding `TranscriptImage.undecoded`, so the entries after it keep their IDs and turns. The readers hand images to `TranscriptBuilder` through an `@autoclosure`, which it only runs while decoding images.

`MessageSearchReadingMeasurements` reads 100 generated messages, each with one PNG, the way search does:

| Images in each message | CPU, decoding → undecoded | Decoded image bytes a page holds |
| --- | --- | --- |
| None | 3.2 → 3.1 ms | 0 |
| 160 KiB of base64 | 40 → 31 ms | 12 MiB → 0 |
| 744 KiB of base64 | 156 → 135 ms | 49 MiB → 0 |

The gain is smaller on real sessions. On one contributor's 46 Claude Code and 163 Codex sessions with images, 3.3 GB in all, CPU went from 2.46 to 2.37 s and from 7.29 to 7.15 s. The largest page held 10 and 11 MiB of decoded images, and now holds none; the indexer reads 3 sessions at once. JSON parsing, which still reads each base64 string, takes about half of the remaining time for Claude Code, and a third for Codex. In Codex rollouts, most image bytes are in tool outputs and events, which the reader already skips without parsing; only 9% are in messages.

### 11. Codex's compacted records are parsed in full

**Evidence:** a Codex `compacted` record carries the conversation it replaced, images included. The reader only shows a note for it, but `CodexTranscriptReader.mightContainTranscriptItem` lets the line through, so the whole record is JSON-parsed. In the 163 Codex sessions of item 10, these records held 306 MiB of image base64, 16% of all of it, and more than the messages themselves.

**Plan:** measure how much reading time these records take. If it matters, add the note from the line's start, which holds the timestamp and type, without parsing the rest.
### 12. Every reader decoded its own images

**Evidence:** each `TranscriptImageView` decoded its image in a detached task of its own and kept the result. The reader lays out every loaded entry, so opening a session decodes all the images in its loaded pages at once. Opening the session again, after reading another one, decoded them all again. A second reader of the same session, such as a reading window beside the preview, decoded them a second time and kept a second copy.

**Change:** `TranscriptImageDecoder` decodes each image once for every view that shows it. It knows an image by a SHA-256 digest of its bytes, since each reader reads its own `Data` from the session file. Views asking for an image that is decoding wait for that decode. Decoded images stay in an `NSCache` of at most 128 MiB of pixels, which also empties when memory runs low. A view that goes away stops waiting, and a decode nobody waits for any more doesn't start. The digest names the bytes, so a cached image can't be an older version of the one asked for.

It adds no limit on how many images decode at once. Decoding runs off the main thread, and it lengthened the longest main-thread gap by only about 15 ms over the same transcript without images: 224 to 237 ms, against 208 to 219 ms. A limit would only make the images in sight wait for the others.

`TranscriptImageDecodingMeasurements`, release build, two runs each. The session has 24 screenshots of 2880×1800 in 240 entries:

| Measure | Before | After |
| --- | --- | --- |
| One reader: CPU until the process settles | 1.05–1.14 s | 1.04–1.08 s |
| One reader: memory footprint growth | 413 MB | 401–414 MB |
| Opened again after closing: CPU | 1.01–1.16 s | 0.36 s |
| Opened again after closing: memory footprint growth | 378–390 MB | 66–96 MB |
| Two readers at once: CPU | 2.0–2.2 s | 1.25–1.27 s |
| Two readers at once: memory footprint growth | 580–655 MB | 422–429 MB |
| Four readers at once: CPU | 4.3–4.5 s | 2.0 s |
| Four readers at once: memory footprint growth | 1.27 GB | 515–564 MB |

Laying out the same 240 entries without images takes about 0.23 s of CPU, which each extra reader still pays. Time until settled and the longest main-thread gap barely changed, since layout dominates both. The process kept 220 to 530 MB after its readers closed before the change, and 280 to 434 MB after it. Freed memory isn't returned right away, so that measure can't show the cache's share; the cache holds at most 128 MiB.
### 13. Each OpenCode page read every message's data

**Evidence:** to read one page of an OpenCode session, `OpenCodeTranscriptIndex` read every message of the session. SQLite checked and rewrote each message's JSON, and the app then parsed it, before the page read the parts of its own few messages. A user's message keeps the diffs of the files it changed, whole files, in that JSON. Each page of a long session cost as much as reading all of its messages, and paging back through it read them all again for every page.

**Change:** the index reads only the messages' ids, in order, from OpenCode's `(session_id, time_created, id)` index, without reading their data. A page then reads the data of only its own messages, one by one, by id. Nothing is cached between reads, so a message OpenCode rewrites, as when a reply fails, shows on the next read. Each message is a record, including one whose data is unreadable or isn't a user's or an assistant's message; such a record has no entries. OpenCode writes only those two kinds, so record numbers, and the entry ids made from them, stay the same.

`OpenCodeTranscriptPagingMeasurements`, release build, median of five each, two runs before and two after:

| Measure | 1,000 messages, before → after | 10,000 messages, before → after |
| --- | --- | --- |
| Latest page | 6.4–6.8 → 1.7 ms | 50 → 2.2 ms |
| Latest page, then five earlier ones | 37 → 10 ms | 298–300 → 13 ms |
| A page in the middle | 6.2–6.3 → 1.7 ms | 50 → 2.2 ms |
| Whole session read for message search | 29 → 29 ms | 382–384 → 305–307 ms |

Message search reads a session in pages of up to 5,000 entries, so it read the index only a few times before the change. Most of its time is reading every message's data and parts, which it still needs.

### 14. A CLI activity change updates only the rows in view

**Question (issue #61):** when a CLI's activity changes, `ConversationStore` publishes, and every view that observes the store is invalidated. Does that re-render rows whose session didn't change, and would a narrower publication help?

**Measured:** `SidebarInteractionMeasurements`' store-change scenario, release build, with `Self._printChanges()` added to the sidebar's and detail view's bodies for the run. One activity change at 300 and at 2,000 sessions re-ran these bodies, every project expanded by a search, and every project collapsed:

| View | Expanded | Collapsed |
| --- | --- | --- |
| `ConversationSidebarView` | 1 | 1 |
| `WorkspaceDetailView` | 1 | 1 |
| `SidebarProjectSection` | 24–25 | 50 |
| `SidebarProjectRow` | 24 | 24 |
| `SidebarSessionRow` | 21–24 | 0 |

The same at 300 and at 2,000 sessions: the sidebar's lazy list builds only the rows in its viewport, so the count is set by the window, not the library. The turn took 15–18 ms expanded and 8–10 ms collapsed. In a Time Profiler recording of the turn and the one that follows, the app's own bodies, which filter `terminalSessions` and sum up each project's activity, were the top frame in 13% of samples; about 60% were SwiftUI re-measuring the lazy stack's rows (`_LazyLayout_Subviews.apply`, `sizeThatFits`).

**Conclusion:** the store already suppresses unchanged activity, and SwiftUI already limits the work to the rows in view. Cutting the turn further would mean making each row skip its body and layout when its own values didn't change, which needs the rows to stop observing the store and take their values from the section instead. That is a wider change to the sidebar's rows and their menus for a saving of perhaps 5–10 ms on an event that happens at most once a second per CLI. Not done.

### 15. Terminals in minimized windows drew as if in sight

**Evidence:** a tab's terminal batches its output and stops drawing while the tab is hidden behind another, but nothing told it about its window. A selected tab in a minimized window, or one covered by another window, fed and drew every byte as one in sight does. `TerminalWindowVisibilityMeasurements` replays a full-screen TUI repainting 40 rows at 30 frames a second through one `SelectableTerminalView` for 3 seconds, release build, median of five, as a share of one core:

| Window | Before | After |
| --- | --- | --- |
| In sight | 13–22% | 22% |
| Covered by another window | 15–22% | 22% |
| Minimized | 22% | 3.4% |
| Bound: the tab hidden, window in sight | 3.8–4.0% | 3.8% |

The in-sight figure varies between runs with what else the machine is doing; the bound and the minimized figure after the change are steady.

**Change:** `TerminalInsetView` follows its window's `didMiniaturize` and `didDeminiaturize` notifications and treats a minimized window's terminal as a hidden tab: output is batched at 8 Hz and drawing waits, through the same `setWorkspaceActive` both engines implement. Restoring the window flushes and redraws, as selecting a hidden tab does. The CLI keeps running and its process is read as before, so notifications and attention are unaffected. A tab dragged into another window follows that window.

A covered window is left alone. macOS reports `NSWindow.occlusionState` only to a running app, never to a test process, even one with the regular activation policy, so a check on it couldn't be tested here, and the window server's own occlusion culling already applies to its drawing. The measurement keeps the covered state as a reference.

### 16. Typing beside flooding terminals

**Question (issue #58):** every terminal's output is parsed on the main thread. SwiftTerm's `LocalProcess` yields after about 4 ms of delivery per process, and the app batches a hidden tab's output (`TerminalOutputCoalescer`), but nothing shares a budget across terminals. Does a keystroke in one tab wait behind the others' output, and would a cross-terminal scheduler help?

**Measured:** `TerminalFairnessMeasurements`, release build. A quiet SwiftTerm tab runs `cat`; 60 markers are typed into it, one every 50 ms, and each is timed until its echo is in the terminal's buffer, read from the main queue every 2 ms, so a stall there delays the reading as it delays the display. Other tabs flood from scripts on their own pseudo-terminals, visible beside it as split panes or hidden as the workspace hides them.

| Other tabs | Keystroke to echo, p50 / p95 | Flood lines parsed in about 4 s |
| --- | --- | --- |
| None | 2.3 / 6.7 ms | — |
| 1 visible, as fast as it can (about 50 MB/s) | 4.1 / 10.0 ms | 1.6 M |
| 3 visible, as fast as they can | 17 / 24 ms | 1.4 M |
| 5 hidden, as fast as they can | 34 / 44 ms | 3.1 M |
| 1 visible and 5 hidden, as fast as they can | 31 / 49 ms | 2.3 M |
| 1 visible and 5 hidden at 25,000 lines/s each, about a 2 MB/s build log | **1.9 / 4.3 ms** | 0.56 M |
| 1 visible and 5 hidden at 5,000 lines/s each | 2.1 / 4.9 ms | 0.11 M |

Keystrokes wait only when the other terminals print as fast as a pseudo-terminal carries, about 50 MB/s each and 60 MB/s parsed in all, which no CLI does. Six terminals each printing a fast build log, 12 MB/s in all, leave typing where it is alone. Making the hidden tabs' batches smaller (16 or 4 KiB instead of 64) changed nothing, since at flood rates every read from the pseudo-terminal already exceeds the batch size and is parsed on arrival; the wait is the parsing itself.

**Conclusion:** SwiftTerm's per-process budget and the app's hidden-tab batching are enough at any rate a CLI reaches. A shared budget across terminals would only matter under a synthetic flood, and would have to keep SwiftTerm's own backpressure working. Not done. The suite stays to check this again after a SwiftTerm upgrade or with Ghostty, which parses off the main thread.

### 17. SSH connections during a remote refresh

**Evidence:** a refresh runs its folder lookup and six provider copies sequentially; OpenCode and Antigravity also run snapshot and cleanup commands. Without multiplexing, each is a separate SSH login. Cached mirrors and rsync deltas already reduce the bytes copied. This change could not be timed against a live host: Multipass was unavailable and macOS Remote Login was off (`ssh localhost` was refused), so there is no handshake, snapshot, transfer, or cleanup timing and no latency claim.

**Change:** one remote-session refresh gives its folder lookup, snapshot commands, rsync copies, and cleanup commands the same app-owned OpenSSH control socket. Each refresh has a unique directory owned only by the current user, including concurrent refreshes, and explicitly asks its own master to exit before removing the directory on success, failure, or task cancellation; a 60-second persistence limit is the fallback if the app exits first. A stale socket from an earlier process has a different path. Host aliases and their users, ports, jump hosts, host-key policy, and other SSH settings still resolve normally. A host with `ControlMaster no`, `ControlPath none`, `ControlPersist no`, or a control path of its own receives no app-owned sharing.

The unit coverage checks option construction, config precedence, private and distinct socket directories, idempotent teardown, cancellation, and the same options in remote commands and rsync. A disposable Linux target and a separate macOS account remain required to verify actual reuse and teardown over SSH.
### 18. Workspace windows repeated discovery and message indexing

**Evidence:** every workspace window owned a `ConversationStore`, and every store owned its own message index and ran its own full local refresh. `SharedWorkspaceReadMeasurements` compares those isolated objects with the app-scoped service, using eight generated Codex sessions (209,256 source bytes), simultaneous cold indexing, and three release-build runs per configuration. Counts were identical in all three runs; times below are medians.

| Windows | Source reads, isolated → shared | Bytes read | Index entries / folded copies | CPU time | Wall time |
| --- | --- | --- | --- | --- | --- |
| 1 | 8 → 8 | 209,256 → 209,256 | 8 / 8 → 8 / 8 | 18.4 → 18.3 ms | 13.1 → 13.0 ms |
| 2 | 16 → 8 | 418,512 → 209,256 | 16 / 16 → 8 / 8 | 36.1 → 17.7 ms | 13.6 → 12.3 ms |
| 4 | 32 → 8 | 837,024 → 209,256 | 32 / 32 → 8 / 8 | 82.1 → 16.4 ms | 15.0 → 11.8 ms |

Repeating the identical generation caused zero additional reads in every case. A blocked-reader test starts two users while the one read is still in flight and observes one reader call, rather than merely serial calls. Another service-level case blocks full discovery until all windows have joined it. Its adapter scans were 1/2/4 with isolated stores and 1/1/1 when shared; a fake compatible tmux recorded 3/6/12 subprocess probes before and 3/3/3 after. Each configuration ran three times with the same counts.

**Change:** `WorkspaceReadService` is owned by the app and passed to each workspace. It owns one `SessionMessageIndexer`, one set of adapters and command resolver, and one in-flight full-discovery task. The indexer keeps each active search user's session set and indexes their union, so one window changing hosts, filters, or closing cannot prune or cancel another's text. Generations reject a read that finishes after an append, rename, deletion, or host removal changed the desired set. Text leaves memory only after the final search user and the existing grace delay; restarting within it reuses the in-memory index. A closed window leaves the shared discovery running for other waiters, but the final waiter synchronously marks and evicts it so an immediately opened window starts fresh. Adapter scans check cancellation between reads, tmux probes are bounded, and only the current discovery generation commits the selected tmux server. Selection, sidebar filters, expanded projects, terminal tabs, alerts, and all other presentation state remain in each window's store.

**Limits:** this is a service-level proxy, not four real SwiftUI windows. Its cold caches read zero cache bytes; it does not quantify warm cache decoding. Peak RSS was recorded for the process (about 54–56 MB) but was cumulative across cases, so it cannot isolate per-configuration memory; index-entry and folded-copy counts are the useful memory bound. The fake tmux proves subprocess coalescing but is not a live shell or SSH measurement. Periodic lightweight probes remain per window; this change shares only full refreshes and search indexing.

### 19. The working spinner re-rendered the window 30 times a second

**Evidence:** `WorkingSpinner`, the turning arc beside a session whose CLI is working, animated with a `TimelineView(.animation(minimumInterval: 1 / 30))`. Each tick invalidated the window's whole SwiftUI hosting view: in a Time Profiler trace of v1.2.4 at idle with one CLI working and five tabs open, 2,567 of 10,000 ms were inside `NSHostingView.layout` → `ViewGraphRootValueUpdater.render`, every one a full `ViewGraph.updateOutputs` pass, and `TimelineView<>.UpdateFilter.updateValue` the only per-frame trigger in them. The main thread was busy 35% of the time with nothing happening, and every click, tab switch, and keystroke queued behind those renders. A shared clock publishing one angle would have cost the same: the price is the hosting view's re-render, not the number of timelines.

Traces recorded with `xcrun xctrace record --template 'Time Profiler' --instrument Hangs --attach <pid> --time-limit 10s`, attached to the running app, this session's CLI working the whole time, no interaction. Apple M4 Pro, macOS 26.6.1, Xcode 27.0, release builds.

| Build | Main thread busy | Inside `NSHostingView.layout` | Hangs |
| --- | ---: | ---: | --- |
| v1.2.4, before | 35.0% | 25.7% | none |
| After, run 1 | 3.3% | 0.0% | none |
| After, run 2 | 3.0% | 0.0% | none |
| After, run 3 | 3.7% | 0.0% | none |
| After, run 4 | 3.5% | 0.1% | none |

**Change:** the arc is a `CAShapeLayer` in a small `NSViewRepresentable`, turned by a repeating `CABasicAnimation` on `transform.rotation.z` that the render server runs; SwiftUI draws the view once. The animation runs only while the arc can be seen — the view is in a window that is not minimized, neither it nor an ancestor is hidden, and the SwiftUI view hosting it is not at zero opacity, which is how the app keeps hidden content mounted — and is removed otherwise, so a spinner in a hidden tab, a hidden sidebar panel, or a minimized window costs the render server nothing; one in a window covered by another, or clipped out of a scroll view, still turns. Reduce Motion still shows the arc standing still. The stroke color is resolved from the view's effective appearance, as the SwiftUI arc's `ThemePalette.live` was. `WorkingSpinnerRenderingTests` checks the arc draws in the live color of each appearance, that held still it covers the pixels the SwiftUI arc did, and that no view under `Views/` animates with a per-frame `TimelineView` again; `WorkingSpinnerLifecycleTests` checks it stops and restarts with opacity and hiding, and stops on leaving the window.

**Limits:** the remaining 3–4% is Ghostty frame delivery and periodic syncs, not SwiftUI. The hosting view still re-renders whole on every state change it observes, and a tab switch and a right-click still stall in accessibility walks of it; those are separate items.

### 20. The notification bell's list on each sidebar redraw

**Question (issue #176):** the bell in the sidebar header observes the store, so it works out its list on every store change, and the activity sync now also times each wait. Does that slow the sidebar?

**Measured:** `SidebarInteractionMeasurements`, release build, Apple M4 Max, macOS 27.0.1. The bell's branch and its base, `f156493`, ran the populate, filter, store-change, and preview scenarios alternately, twice each; every figure is a median of three. Another session's builds kept the load average between 4 and 6.

| Turn, 2,000 sessions | Base, two runs | Bell, two runs |
| --- | --- | --- |
| A store change, projects collapsed | 6.8, 7.8 ms | 6.7, 7.1 ms |
| A store change, every project expanded | 28.1, 30.3 ms | 33.0, 30.9 ms |
| Listing the sessions (replace and first render) | 38.0, 39.6 ms | 39.2, 35.5 ms |
| Click to preview | 37.5, 40.5 ms | 40.7, 41.2 ms |

A first pass ran the whole suite on the base, then on the bell, minutes apart: populate and preview at 2,000 sessions took 26 and 22 ms on the base and 46 and 40 ms on the bell. Run alternately, both sides took 42–46 ms and 37–41 ms, so that gap was the machine's load changing between the passes.

The list costs one look at each window's tabs and at this window's CLIs in tmux with no tab, never at the sessions, and the store publishes the wait times only when a wait starts or ends (`WaitingForYouStartTimesSyncTests`).

**Conclusion:** no measurable change.
### 21. Every sidebar row hosted its hover menus

**Evidence:** every tab switch stalled the main thread for about 270 ms, a microhang on every click in the Hangs instrument. In a Time Profiler trace of main at f156493 (after item 19), 5 tabs open, 20 tab clicks a second apart delivered as real mouse events: 20 hangs of 252–287 ms, 7,000 ms of the 26 s inside `NSHostingView.layout`, about 350 ms per click. Inside those, `AppKitPopUpAdaptor` accounted for 2,400 ms and `ViewGraphFeatureBuffer` 1,350, with `_CFBundleCopyLocalizedString` and `CUICatalog` under them: the ⋯ and + menus of every project row, and the ⋯ of every session row. Each row kept them in the view tree at zero opacity, for the pointer to find, and each `Menu` is an `NSPopUpButton` underneath; the hosted browser with 50 projects held 49 pop-up buttons among 283 AppKit views. A tab switch changes `selectedTerminalID`, every row observing the store re-evaluates, and every pop-up button's localized title and image are resolved and its view re-registered with accessibility, whether or not anything in the row changed. The focus-responder walk the baseline named (`AccessibilityNode.updateFocusResponder`) is real but small: ~100 samples in 26 s, 5 ms per switch, visiting every SwiftUI responder node once with a protocol-conformance lookup each; the hidden tabs' terminals are 4 of those samples.

Traces recorded with `xcrun xctrace record --template 'Time Profiler' --instrument Hangs --attach <pid> --time-limit 26s`, the clicks posted by a small accessibility driver (`/tmp/axdrive click 20 1`, tab buttons in rotation, CGEvents at their centers). Apple M4 Pro, macOS 26.6.1, Xcode 27.0, release builds, this session's CLI working throughout.

A stall is a stretch of main-thread samples no more than 2 ms apart: Time Profiler records the main thread only while it runs, so the stretch is time it could not take input. The Hangs instrument reports only stalls of about 250 ms or more, which is why an earlier version of this table counted no hangs after the change; the column below is the longest stall per click, from `/tmp/perf-perclick.py <timeprofile.xml>`.

| Build | Main thread busy | Inside `NSHostingView.layout` | Longest stall per click: median (range), clicks ≥ 100 ms | Focus walk samples |
| --- | ---: | ---: | --- | ---: |
| f156493, run 1 | 34.4% | 26.9% | 270 ms (259–287), 20 of 20 | 103 |
| f156493, run 2 | 34.7% | 27.9% | 277 ms (267–286), 20 of 20 | 112 |
| f156493, run 3 | 34.9% | 28.1% | 278 ms (128–287), 20 of 20 | 111 |
| df24945 (this change), run 1 | 13.1% | 7.8% | 87 ms (79–97), 0 of 19 | 156 |
| df24945, run 2 | 12.4% | 8.0% | 85 ms (74–106), 1 of 20 | 48 |
| df24945, run 3 | 12.7% | 8.1% | 88 ms (66–107), 1 of 20 | 56 |

The driver above reads the app's accessibility tree to find the tabs, as VoiceOver or another accessibility client would, and SwiftUI then keeps that tree up to date on every change. On main a5eb0d9, with this change merged, the same 20 clicks posted at fixed points with no accessibility calls (`/tmp/axdrive clickat`, app relaunched first) stall far less:

| Main a5eb0d9 | Longest stall per click: median (range), clicks ≥ 100 ms |
| --- | --- |
| No accessibility client, run 1 | 51 ms (43–58), 0 of 19 |
| No accessibility client, run 2 | 49 ms (42–53), 0 of 18 |
| Driver reading the tree, run 1 | 90 ms (84–116), 4 of 19 |
| Driver reading the tree, run 2 | 91 ms (84–111), 5 of 20 |

**Change:** a row puts its menus in the view tree only while the pointer is over it: `SidebarProjectRow` (⋯ and +), `SidebarSessionRow` and `SidebarSubagentRow` (⋯, in an overlay that never took room), and `SidebarOpenTabGroupHeading` (⋯ and +). The count each trades with stays in the layout, faded out, beside a placeholder of the menus' size, so hovering moves nothing; `SidebarHoverMenusTests` checks each row type's size with and without the pointer and the placeholder's, hosts every row type and checks it carries no pop-up button at rest, and hosts the 300-session browser harness and checks it holds only its header's filter (one pop-up). The host heading is left as it was: one heading per SSH host, not one per row, with its menus mounted and faded. The right-click menus are unchanged; `.contextMenu` adds no view until it opens.

**Limits:** a click still costs 42–58 ms with no accessibility tree and 66–116 ms once there is one, built by an accessibility client or by the first right-click (item 22): most of it `ViewGraph.updateOutputs` and `ScrollViewCommitMutation` re-evaluating the sidebar's rows because they observe the whole store, with the tree updated alongside; that is a later item's question. The focus walk's cost is SwiftUI's per node, not the app's, and was left as measured; the 156 samples in the first after run include the driving script's own accessibility reads when it starts, against 48 and 56 in the other two and 103–112 before. A row's menus appear on hover as before. At rest they are no longer in the view tree, so VoiceOver and Full Keyboard Access no longer reach the ⋯ and + as separate controls there; the same actions remain in the row's right-click menu. This was not checked with VoiceOver or Full Keyboard Access running.

### 22. The first right-click built the window's accessibility tree

**Evidence:** in v1.2.4 a right-click on a tab or sidebar row hung the main thread for 1.09 s. Presenting the context menu, AppKit asks the window-wide `NSHostingView` for its `accessibilityChildren`, which builds SwiftUI's accessibility tree for the whole window: every sidebar row with its pop-up buttons, and the tab bar, while item 19's loop kept the graph busy. After items 19 and 21 the same path costs one stall, on the first right-click after launch; in its 157 samples, 106 are inside `NSHostingView.accessibilityChildren` and `AccessibilityNode` under `NSContextMenuImpl.presentPopup`. In these recordings the tree it built was still there afterwards, kept up to date with every change, and the tab switches that followed cost what they cost under an accessibility client.

Measured on main a5eb0d9, the app relaunched before each recording, right-clicks and clicks posted as mouse events at fixed points (`/tmp/axdrive rightclick` and `clickat`), each menu dismissed by a click beside it. `/tmp/perf-rightclick.sh` right-clicks a tab and a sidebar row in turn; `/tmp/perf-mixed.sh` switches tabs and right-clicks a row after each switch. Stalls from `/tmp/perf-perclick.py` and `/tmp/perf-stalls.py <timeprofile.xml> 2 presentPopup`; traces under `/tmp/perf-3/`. Apple M4 Pro, macOS 26.6.1, Xcode 27.0, release build.

| Recording | First right-click after launch | Later right-clicks | Tab switches after the first right-click |
| --- | --- | --- | --- |
| Right-clicks only; driver reads the window's frame (`before-cold-1`) | 145 ms, then 45 ms as the menu opens | first on a row 51–54 ms; then 33 ms or less | — |
| Right-clicks and tab switches; driver reads the window's frame (`before-mixed-1`) | 137 ms, then 61 ms | 38 ms or less | 75–95 ms |
| Right-clicks and tab switches; no accessibility calls (`noax-mixed-1`) | 138 ms, then 64 ms | 20 ms or less | 69–89 ms |

**Change:** none. Presenting the nine SwiftUI context menus as `NSMenu`s built in AppKit and popped from the view under the pointer, as the terminal's menu is, would keep AppKit from asking the window for its tree. It means writing about a dozen SwiftUI menu-content views again as AppKit builders, and the ⋯ hover menus with them so that no menu exists twice; for one stall of about 140 ms per launch, the risk of the two drifting apart was judged not worth it.

**Limits:** `NSHostingView.accessibilityChildren` still runs in the first right-click's stack. After it, tab switches cost 69–89 ms for the remainder of these recordings, about 25 s each, instead of 42–58 ms (item 21); how long the tree stays in a longer session was not measured. An accessibility client is expected to build the tree as well, as the driver did here; VoiceOver and other clients were not tested. How much updating the tree costs depends on how many views re-evaluate on a change, which is the store-wide observation question.

### 23. Show N more under each project

**Question:** an expanded project now lists 10 sessions before **Show N more** (SBL-49), and the sidebar looks up the session the window shows on every redraw to keep its row listed. Does that slow the sidebar?

**Measured:** `SidebarInteractionMeasurements`, release build, Apple M4 Max, macOS 27.0.1. The branch and its base, `b9f72d9`, ran the populate, filter, selection, and store-change scenarios alternately, twice each, after one warm-up run each; every figure is a median of three. Other sessions' builds kept the load average between 9 and 15.

| Turn, 2,000 sessions | Base, two runs | Show N more, two runs |
| --- | --- | --- |
| Listing the sessions (replace and first render) | 20.6, 15.5 ms | 15.4, 15.8 ms |
| Recency filter, All to Recent | 14.0, 13.2 ms | 15.2, 12.5 ms |
| Shift-click the last row | 38.2, 37.7 ms | 37.5, 37.0 ms |
| A store change, projects collapsed | 7.3, 6.8 ms | 6.2, 6.0 ms |
| A store change, every project expanded by a search | 7.5, 9.4 ms | 7.2, 6.9 ms |

These scenarios expand projects with a search, which lists every match, so they measure the lookup on each redraw rather than a shorter list. The lookup is one dictionary read for the shown session, one pass over the listed projects, and one over its project's sessions.

**Conclusion:** no measurable change.

### 24. A growing Codex session's search text was read in full on every change

**Evidence (issue #56):** a changed session misses the search-text cache, and `SessionMessageTextReader` read it from its first page to its last, then rewrote its cache file. A live Codex session changes with every record the CLI writes. A first attempt (`3e2cace`, branch `issue-56-incremental-search-text`) wasn't merged: it hashed every byte twice, replaced the page reader with a slower one, and resumed at the start of a final page that, at 5,000 entries and 64 MiB, was usually the whole session.

**Change:** a Codex session read again after a change saves its text with a resume state: the file's device and inode, how many bytes the text came from, a SHA-256 of those bytes, and the final page's first record, its byte offset, and how many entries came before it. When the file has only grown, `CodexSessionTextResumer` reads from the final page's start to the end into memory once, hashes the bytes before it in 1 MiB chunks, checks the saved digest, and parses only the final page onwards with the same `TranscriptPageReader` and `TranscriptRecordDecoder.pageEntries` as a full read. Every byte is read once, so the digest and the parsed records describe the same bytes while the CLI writes. Any other change, such as an amended earlier record, a same-size rewrite, truncation, or a replaced file, or more than 64 MiB from the final page's start, reads the session in full.

- **Pages:** Codex search pages are now 256 entries, 4,096 records, and 8 MiB, so the final page is small. Full and resumed reads use the same limits, so tool calls merge into the same entries either way. Other providers keep 5,000 entries, 50,000 records, and 64 MiB: the smaller pages made reading a 10,000-message OpenCode session 312–317 → 340–355 ms (`OpenCodeTranscriptPagingMeasurements`).
- **When state is kept:** a session's first read keeps none, so indexing many sessions costs no hashing. The state is kept only if the file is unchanged, modification time included, from before the read to after the hash. Sessions on an SSH host keep none and are read in full as before: rsync replaces a mirrored session's file with a new one at every copy, so it could never resume and the hash would be wasted.
- **Cache:** the cache file starts with a small header, so a stale, other-version, or other-session file is turned down without decoding its text. The format went to version 2, so every session is read once more after the update. The resume state also records the page limits its text was read with, and text read with other limits is read again in full, since where pages end decides which tool calls merge.

`IncrementalMessageSearchMeasurements` (`JUSTSESSIONS_PERF=1 swift test -c release --filter IncrementalMessageSearchMeasurements`) runs the baseline and the new path in the same build, alternating, on two copies of each log. The baseline is `main` before the change: a full read on every change, in 5,000-entry pages, saved in the first cache format. Each operation runs three times per process. The table shows the median of three processes' medians, wall time in ms, baseline → resumable. CPU time was within 2% of wall time.

| Operation | 10 MiB | 100 MiB | 500 MiB | Realistic, 27 MiB |
| --- | --- | --- | --- | --- |
| Cold extraction | 14.2 → 14.4 | 138 → 139 | 699 → 718 | 300 → 297 |
| Unchanged hit | 0.1 → 0.1 | 0.4 → 0.4 | 1.9 → 1.9 | 5.3 → 5.3 |
| First change: full read, then the hash | 14.2 → 18.8 | 137 → 179 | 702 → 905 | 301 → 307 |
| One-record append | 14.4 → 7.1 | 137 → 44 | 688 → 199 | 298 → 36 |
| 10 consecutive appends, total | 144 → 70 | 1,373 → 444 | 6,818 → 1,988 | 2,983 → 365 |
| Earlier amendment plus growth, rebuilt | 14.7 → 22.9 | 137 → 217 | 671 → 1,050 | 301 → 321 |

For a one-record append, source bytes read went from 21.0 to 10.5, 210 to 105, 1,049 to 525, and 56.7 to 28.4 MB. The baseline reads every byte twice, once to index the lines and once to decode them; a resumed read hashes or parses each byte once. Records decoded went from 2,715 to 550, 27,096 to 1,129, 135,327 to 1,172, and 10,727 to 629. Memory during a resumed append rose by up to 4.4 MiB, the tail held in memory, against at most 1.6 MiB. The cache file is still rewritten in full each time; the header adds 130–340 bytes. An unchanged hit reads no source bytes and writes nothing in either path.

The synthetic logs are the first attempt's: one message, then groups of one message and 128 hidden 3.9 KB events. The realistic log is generated in the shape of a real 27 MiB rollout: 28.3 MB, 10,722 records, mostly tool calls, their outputs, and events, about 2.6 KiB a record. Its search has 1,587 entries, against 1,583 in the larger pages, which merged more tool calls. Each run of the new path was checked against a clean full read: entry IDs, segments, and the first match of seven queries, with Chinese, accents, emoji, and Markdown bold.

**Limits of the result:**
- **Measurement:** generated logs, Codex only, one Mac with a warm page cache: Apple M4 Pro (12 cores), 24 GB, macOS 26.6.1, Swift 6.4. The machine wasn't isolated; the load average was 3–8 from other work. One 500 MiB cold run took 851 → 1,064 ms with I/O waits; the medians leave it out.
- **The hash limits the gain:** at 100 and 500 MiB, a resumed append is mostly hashing the saved bytes at about 3.4 GB/s. It is 3.1x and 3.5x faster, not in proportion to the appended record. At 10 MiB it is 2.0–2.2x.
- **Costs:** the first change after a session's first read pays a full hash on top of the full read: about 2% on the realistic log, and about 30% on the synthetic logs, which have little to parse. An amendment pays for the failed resume and the rebuild's hash: about 7% and 57%. Codex appends; it doesn't amend.
- **Smaller pages:** pages of 128 entries, 2,048 records, and 4 MiB made realistic appends 36 → 24 ms, but cold extraction at 100 MiB 5% slower, so they weren't taken.

### 25. What a tab switch still costs

**Evidence:** after items 19–21, a tab switch with no accessibility client still stalls the main thread for about 60 ms. Main 5949e7bc, 3 tabs open, measured as in item 21 with no accessibility calls: the app relaunched before each run, 20 clicks a second apart posted at the tabs' centers (`/tmp/axdrive clickat`), each click's main-thread time counted from 50 ms before its first stall to 700 ms after (`/tmp/perf-6/clickcost.py`). Each click took 96–98 ms of main-thread time, and its longest stall was 63–65 ms (medians of two runs). Nearly all of it is SwiftUI's graph update, spread thin: about 15 ms of view bodies, 5 ms of preferences, 5 ms comparing environment values, 3 ms looking up localized strings again for the text that re-renders, and the rest AttributeGraph's bookkeeping for each view it invalidates. No one view stands out; what costs is how many views a switch invalidates.

Apple M4 Pro, macOS 26.6.1, release builds, the session's own CLI working throughout; medians of two runs of 18–19 detected clicks each.

| Build | Longest stall per click: median (range), runs 1 and 2 | Main-thread time per click: median |
| --- | --- | --- |
| Main 5949e7bc | 63 ms (44–68), 65 ms (58–69) | 96, 98 ms |
| Without the tab bar's scroll to the selected tab (experiment) | 65 ms (50–69), 66 ms (58–71) | 98, 102 ms |
| Tab project keys found once (#218) | 60 ms (56–65), 62 ms (48–66) | 92, 94 ms |
| Without the sidebar at all (experiment, the most there is to gain) | 32 ms (31–34), 33 ms (31–35) | 60, 58 ms |
| `@Observable` store alone | no change: the sidebar redrew as before (body counts below) | — |
| `@Observable`, and the selection read only where it shows (this change) | 38 ms (31–44), 37 ms (32–45) | 68, 70 ms |

- **The tab bar's scroll:** `ScrollViewCommitMutation` held about 18 ms of each click, under the tab bar's `scrollTo` of the selected tab. Without the scroll that time moved into the ordinary update and the click cost the same, so the scroll was only where an update already due ran; it was left as is.
- **Project keys:** each project row's activity summary read every tab's `projectDirectoryKey`, which resolved symlinks on disk each time, 2–3 ms per click. A tab's folder and host never change, so the key is now found once when the tab opens, as a session's is; the activity summary and the key no longer show in the trace.

- **The sidebar:** with the sidebar replaced by an empty view, a click cost about half as much, so about half of each switch was the sidebar redrawing. Counting body runs per click (a log line at the start of 19 views' bodies, 20 clicks; `/tmp/perf-6/bodycount.py` and `bodies.sh`), every switch ran `ConversationBrowserView`'s body twice and with it the whole sidebar: about 140 project-section and 70 project-row bodies for some 35 projects, as each section takes closures, which SwiftUI cannot compare. `ConversationStore` was an `ObservableObject`, so any change redrew every view observing it, but making it `@Observable` alone changed none of these counts: the browser's body itself read the selected tab, for Back and Forward, text zoom, the tab commands, and the onboarding tips, and recording the switch in the Back and Forward history changed its state a second time. The sidebar's body read it to keep the shown session's row listed.

**Change:** `ConversationStore` is `@Observable`, so a view redraws only when a property it read changes, and each read of the selection moved into a small modifier or view of its own: `WorkspaceNavigationControls` (Back and Forward, which now keeps the history), `SelectedTabTextZoomTarget`, `WorkspaceTabActionsValue` (the tab commands and ⌃Tab), `OnboardingTipsPresenter`, and `HiddenShownSessionReveal`. A switch now redraws only those, the tab bar's groups and tabs, the open tabs list, the rows of the sessions with tabs, and the detail view:

| Body runs per click | Before | After |
| --- | ---: | ---: |
| `ConversationBrowserView`, `ConversationSidebarView` | 2 each | 0 |
| `SidebarProjectSection` | 140 | 0 |
| `SidebarProjectRow` | 70 | 0 |
| `SidebarSessionRow`, the rows of sessions with tabs | 6 | 3 |
| `TerminalTabGroupSection`, `TerminalTab` | 8 each | 5 each |
| `WorkspaceDetailView` | 2 | 1 |

A tab's own state, such as its CLI's activity or whether its CLI ended, lives on the tab, which is still an `ObservableObject`; views reading tabs through the store follow it through `tabStateRevision`, which every open tab's own change bumps. Selecting a tab sets no tab property to a value it already had, so this adds nothing to a switch. Other windows' notification bells read this window's terminals on screen directly, so a switch no longer bumps the other windows' revision, which redrew their browser and sidebar whenever one of this window's tabs waited for you. The store's two sidebar caches are not observed, as views write them while reading them.

With an accessibility client (`/tmp/perf-switch.sh`, which presses the tabs through accessibility), main took a median of 99 and 96 ms per click's longest stall and 144 and 138 ms of main-thread time; this change, 66 and 67 ms and 112 ms. At rest with the CLIs working, the main thread was busy 2.9% of 20 s on main and 1.9% with this change. The same 13 clicks and shortcuts (tabs, ⌘1–⌘3, ⌘[ and ⌘], ⌘⇧[ and ⌘⇧], ⌃Tab) left the same tab selected after each in both builds.

**Limits:** these runs had 3 tabs, against 5 in item 21; the sidebar's share grows with the projects it lists. What is left of a switch is mostly SwiftUI updating the tab bar, the open tabs list, and the terminal area. A symlink changed while a tab is open no longer changes its project until the tab reopens, as for sessions, which keep the key found when they were listed. A view that read a tab's state through something other than the store's tabs, and was redrawn before only because some other property of the store changed at the same time, would now miss the change; the tests and the checks above found none. Showing a session's conversation and going Back from it was not checked by hand: every listed session had a running tab.

### 26. Refreshing hosts on their own

**Evidence:** a host refreshed only when a window opened, from its heading, or after events such as a tab's CLI exiting, so a session started outside the app showed only after a manual refresh. This Mac's refresh reads only the files a CLI wrote to (PERF-20), about 50 ms with 1,400 sessions (PERF-01). An SSH host's refresh had not been timed (item 17). On 13 October 2026 it was timed against the Multipass test VM (`justsessions-test`, Ubuntu 24.04 on the same Mac, about 1 MB of Claude Code history) with `RemoteSessionDiscovery.discoverToolByTool` and `RemoteHostStatusProbe`, four runs into a new mirror: copying all six tools took 1.45 s the first time, then 0.79 to 1.19 s; the status probe took 0.12 to 0.65 s.

**Change:** `HostAutoRefresher` checks every 15 seconds while a workspace window shows on screen (not hidden, minimized, covered, or behind a locked screen), and when the app comes forward. This Mac refreshes a minute after its last refresh started, in every window, through the one shared scan (item 18). An SSH host refreshes 5 minutes after its last copy; after a failure it waits 5 minutes, then twice as long after each failure in a row, up to an hour, and a host that needs **Connect…** is left alone. The oldest window copies the host. After any successful copy, the other windows read it from disk instead of copying the host again.

**Limits:** the VM runs on the same Mac, so the timing has no real network latency and little data. A distant host or one with a large history takes longer per copy; none was timed.

### 27. Typing in a Rename dialog

**Evidence:** typing in a session's Rename dialog lagged. The name being typed was `ContentView`'s own state, so every keystroke ran `ContentView`'s body. That builds `ConversationBrowserView` with closures SwiftUI can't compare, so the whole browser and sidebar redrew, as tab switches did before item 25.

An earlier measurement found no redraw: a debug build with **no tabs open and its projects collapsed** ran none of five views' bodies while 20 characters were typed. Under the conditions below the browser and sidebar redrew on every keystroke.

**Measured:** main `a2f75614` against this change, release builds, 4 tabs open, Apple M4 Pro, macOS 26.6.1.
- **Opening the dialog:** each run relaunched the app, then opened Rename from tab 1's right-click menu, using real mouse events and an accessibility press of the menu item. The right-click builds the window's accessibility tree, as it does when you rename (item 22).
- **Typing:** 20 characters, 0.4 s apart, inside a Time Profiler trace (`/tmp/perf-7/rename-typing.sh`, `keycost.py`).
- **Busy time per keystroke:** main-thread time in the typing window, minus the quiet rate after it, divided by 20 keystrokes.

| Build | Longest stall per keystroke: median (max), runs 1 and 2 | Main-thread time per keystroke |
| --- | --- | --- |
| Main a2f75614 | 60 ms (64), 62 ms (67) | 46, 54 ms |
| This change | 14 ms (18), 12 ms (17) | 13, 16 ms |

On main, nearly all of each keystroke was SwiftUI's graph update (41–47 ms), with `ContentView`'s body running on every keystroke. Installed v1.2.9 measured the same as main: 61 and 62 ms.

Counting body runs with a log line at the start of 19 views' bodies, release builds of main `f7b4b410` and this change, 20 characters typed 0.3 s apart (`/tmp/perf-7/rename-bodies.sh`): on main every keystroke ran `ContentView`, `ConversationBrowserView`, and `ConversationSidebarView` once, 67 `SidebarProjectSection` and 42 `SidebarProjectRow` bodies, and 4 each of the tab bar's and open tabs' rows. With this change none of the 19 ran, and the field held all 20 characters.

**Change:** the Rename dialogs of a session and of a project, and what is typed in them, moved into `RenameDialogs`, a modifier of their own, so a keystroke redraws only the dialog.

Moving them showed an older bug: reopening a dialog on the same session or project showed an empty field. SwiftUI fills an alert's field only when its text differs from what the field last showed, which a second open of the same name never does. The field now gets a new identity each time a dialog opens (`openCount`), and shows the name shown now until you type. Checked on the release build, reading the field through accessibility:
- tabs 1, 1, 2, 1, 2 and 2 each opened on their name;
- a rename followed by a reopen opened on the new name;
- projects opened on their name, the same project twice included;
- typing replaced the selected name, as before.

**Limits:** one Mac, 4 tabs and about 35 projects listed; the stall on main grows with the sidebar.

### 28. Dragging a tab or a group along the tab bar

**Evidence:** each move of the pointer during a drag along the bar re-ran far more than moved. The drag was `@State` of the tab's group section, or of the tab bar for a group, so every move re-ran that view and every tab in it. A drag held in another window's bar was `TabDragBetweenWindows.shownDrag`, `@Published` on an object that every window's tab bar, group sections and split sections observed, so every move re-ran every window's bar.

**Change:**
- `TabBarDragDisplay` holds a drag in two observed properties. `placement`, which the tabs, groups and bar read, changes only as the drag starts or ends or the dragged item passes another. `drag` changes with every move, and only each item's `tabBarDragShift` reads it, so a move re-runs only the shifts.
- Each window has its own `TabBarDragDisplays` for tabs dragged in from another window, one display per group, so a move there re-runs only that bar.
- `TabBarDrag` works out the items' leading edges once, not on every read.

**Measured:** Apple M4 Max (10 performance and 4 efficiency cores, 36 GB), macOS 27.0.1, Xcode 27.0 (Swift 6.4). Release builds of main `07e575d9` and this change, three runs each, alternating.

Body runs and time per pointer move, from a temporary probe:
- **Probe:** a log line at the start of the bodies of `WorkspaceTabBar`, `TerminalTabGroupSection`, `TerminalTabGroupLabel`, `TerminalTab`, `TerminalSplitAcrossProjectsSection` and the shift.
- **Windows:** 1,400 × 300 points, each bar holding 3 groups of 6 tabs.
- **Moves:** 59 moves of 3 points, sent through `NSApp.sendEvent`, each followed by every window's layout and drawing.
- **The cross-window drag:** starts in a window of 4 tabs, goes down off its bar, then along the bar of a second window. A third window sits aside, and a fourth opens to carry the tab.
- **Locked screen:** the Mac was locked, so on both builds the probe found the window under the pointer from the app's window order instead of the window server's hit test.

| Drag | Main: bodies per move | Main: median move | This change: bodies per move | This change: median move |
| --- | --- | --- | --- | --- |
| A tab among its group's 6 | 6 tabs, the group's section and label | 0.7, 0.7, 0.7 ms | 6 shifts, 0.2–0.3 tabs | 0.3, 0.3, 0.3 ms |
| A group by its label | 18 tabs, 3 sections and labels, the bar | 2.1, 2.7, 2.9 ms | 3 shifts, 0.3 tabs | 0.9, 0.9, 0.9 ms |
| A tab into another window's bar | 40 tabs, 8 sections and labels, all 4 windows' bars, the window aside's 3 sections included | 3.8, 3.6, 3.6 ms | 7 shifts, 0.2 tabs, nothing in another window | 0.4, 0.4, 0.4 ms |

With this change a tab's body runs only as the dragged item passes another, which is the 0.2–0.3 per move.

`TabBarDragMeasurements`, with the probe taken out: the bar alone in a window out of sight, 1,400 points wide with its 18 tabs narrowed to fit, 3 drags of 120 moves of 3 points per run, each move followed by the window's layout and drawing. Each drag passes other tabs or groups, and the suite fails if one moved nothing.

| Drag | Main: median (p90) per run | This change: median (p90) per run |
| --- | --- | --- |
| A tab among its group's 6 | 0.67 (1.22), 0.67 (1.47), 0.66 (1.49) ms | 0.29 (0.90), 0.29 (0.97), 0.29 (0.78) ms |
| A group by its label | 3.18 (3.98), 2.91 (3.77), 3.48 (4.30) ms | 1.32 (2.73), 1.46 (2.62), 1.66 (2.73) ms |

What is left of a group's move is the layout and drawing of the shifted groups.

**Smoothness:** on main, tabs dragged off the bar slid back into their places just before they left. The window opened to carry them showed with the system's opening animation wherever SwiftUI put it, before it moved under the pointer and before its bar had laid the tabs out. Now the tabs hide where they were drawn, and the window opens out of sight with no animation and shows once its bar has laid them out under the pointer (TAB-65). `TabDraggingBetweenWindowsTests` checks that the new window arrives out of sight with no animation, and gets its animation back. The look on screen was not checked: the Mac was locked.

**Limits:** one Mac. The times include SwiftUI's layout and AppKit's drawing into the window, not the compositor's frame. The cross-window figures used the app's window order, not the window server's hit test, on both builds.

### 29. Typing in an SSH tab

**Question:** typing in an SSH tab lags. How much of the lag is the app's, and how much the network's?

**Evidence:** each keystroke goes from the tab through `ssh` to the host, through its tmux to the CLI, and back. The tab's own share is small (PERF-82: about 1.9 ms p50 keystroke-to-echo on this Mac). Two more waits came from settings, not from the network:

- OpenSSH 9.5 and later send a terminal's keystrokes in batches every 20 ms, with fake keystrokes for a while after typing stops (`ObscureKeystrokeTiming`), so that someone watching the network can't time each key. macOS 27's OpenSSH 10.3 has it on by default.
- tmux before 3.5 waits 500 ms after Esc to see whether a longer key sequence follows (`escape-time`). Ubuntu 24.04 ships tmux 3.4. This Mac's tmux already sets 10 ms; a tab's tmux on a host didn't.

When a tab goes through a Connect… login, its keystrokes are sent by the login's master, so the master's setting decides. With the master at the default, a tab passing `ObscureKeystrokeTiming=no` itself still took 3–10 ms at p50, against about 1 ms with the master's off.

**Change:** tabs and the Connect… master pass `ObscureKeystrokeTiming=no` (SSH-28) where this Mac's `ssh` takes it; an `ssh` older than 9.5 would refuse to connect with it. A tab's tmux sets `escape-time 10` on every attach (SSH-86).

**Measured:** the command a tab runs, written by the app's `RemoteCLICommandBuilder` with `cat` in place of the CLI, run in a pseudo-terminal against the Multipass VM (Ubuntu 24.04, tmux 3.4), from a Mac with OpenSSH 10.3. Each of 30 keystrokes was timed until its echo came back, and each of 8 Esc presses until the pane's `^[` came back. "Main" is the same command with the option and `escape-time` taken out; each run started a fresh tmux server on the VM. Runs alternated main, change, main, change; the load average was 7 to 11.

| Build | Keystroke to echo, p50 / p90 | Esc to echo, p50 | Server's `escape-time` |
| --- | --- | --- | --- |
| Main | 15.0 / 24.7 ms, 20.0 / 77.2 ms | 516, 530 ms | 500 |
| This change | 1.3 / 1.9 ms, 1.7 / 53.9 ms | 46, 48 ms | 10 |

**Limits:** the VM runs on this Mac, so its round trip is under a millisecond; over a real network the round trip comes on top of what remains, and nothing here hides it. Only showing typed keys before the host answers, as mosh does, could; that would need both engines to draw guesses and take them back. The app's GUI tab and a live Connect… login were not timed; the Connect… numbers above are from `ssh` run by hand with the same options. No macOS host was tested.

### 30. Starting a CLI in an SSH tab ran bash's command-not-found handler

**Evidence:** a tab on an SSH host whose login shell finds the CLI asks that shell for a fish function of the CLI's name before starting it (SSH-87, #236). bash has no `functions`, so it looked for a program by that name. Ubuntu's `/etc/bash.bashrc` sets a command-not-found handler for interactive shells, so the handler ran before the CLI did, in every tab's start and reconnect.

**Change:** the tab's command asks `builtin functions`, which asks only the shell. fish and zsh answer as before; bash and dash look for no program. `RemoteCLIInvocationTests` puts a `functions` program on the PATH and checks that it doesn't run.

**Measured:** the test VM (Multipass, Ubuntu 24.04, bash 5.2.21), in one interactive login shell of a user with the CLI on the PATH, as a tab's command starts. The check ran 20 times each way, alternating: with `functions` it took a median of 39.5 ms (38.2–47.1), with `builtin functions` 0.6 ms (0.6–0.8). Both ended with status 0, so the CLI would take the shell's place. The tab's whole command, as the app writes it, then ran in tmux on the VM: with bash and with fish the CLI's parent was the tmux server, and with a fish function of the CLI's name the function ran.

**Limits:** one host, on the same Mac. A host whose bash has no command-not-found handler saved only the PATH lookup. No macOS host was tested; zsh ran on this Mac only, in `RemoteCLIInvocationTests`.

### 31. A Pi session's name was looked for in its last 256 KB on every refresh

**Evidence:** Pi writes a `/name` once, as a `session_info` line. On every refresh the adapter read the last 256 KB of each session file and parsed its lines from the end until it found one. On the reporting Mac, with 338 Pi sessions totalling 1.05 GB, the largest 523 MB, that took 212 ms a refresh and found none of the 4 names, which were 0.5–5.4 MB before the end of their files.

**Change:** `PiSessionNameScan` (DSC-55) looks for the last name anywhere in the file. It byte-searches 1 MiB chunks for `"session_info"`, parses only the lines that hold it, and skips lines longer than 64 KiB without keeping them. Its result is kept per file in a `SessionFileSummaryCache` saved across launches. A file whose size and modification date haven't changed isn't read. A changed one is read on from where the last scan stopped, once the 256 bytes it ended on are still there.

**Measured:** `PiSessionNameScan` compiled with `swiftc -O` beside a stand-in for its parse of name lines, over the reporting Mac's own Pi sessions with a warm page cache, in two processes:

| Operation | Time |
| --- | --- |
| First scan of all 338 files, once per file | 627–783 ms |
| First scan of the largest file, 523 MB | 236–246 ms |
| Every file again with nothing new, reading on from each kept scan | 5 ms |
| Before: the last 256 KB of every file, parsed for a name | 212 ms |

The scan found all 4 names. Apple M4 Pro (12 cores), 24 GB, macOS 26.6.1, Swift 6.4; the machine wasn't isolated, at a load average of 5–6.

**Limits:**
- **The first launch after the update** reads each Pi session in full once, on the discovery worker: 0.6–0.8 s here.
- **The check before reading on** compares the last 256 bytes read, not a hash of every byte as #24 does. A file rewritten in place with the same bytes at that point would keep a stale name. In exchange, sessions mirrored from SSH hosts read on too, although rsync replaces their files at every copy.
- **Not measured in the app:** the numbers come from the standalone scan, not from a refresh.
- **Still read on every refresh:** an unnamed session's first prompt, up to 1 MB from the start of its file.

### 32. The activity sync went through every listed session for every tmux session

**Evidence:** on v1.2.14 with an SSH host of many sessions listed, the window stalled every few seconds; removing the host made it smooth again. A static review found no SSH command on the main actor: every `ssh` and `rsync` runs detached. What does run there, once a second, is `synchronizeCLIActivity`, and its `detachedThisMacTmuxSessions` and `detachedRemoteTmuxSessions` found the listed session of each of the app's tmux sessions, on this Mac and on every host, with `conversations.first(where:)`: a pass over every listed session, copying each `Conversation`, for every tmux session, every second. A release build with Sparkle's updater off, a thread timing a main-queue round trip every 50 ms, and timing logs in those functions ran against the test VM with 3,000 generated Claude Code sessions in 50 projects (3,365 listed with this Mac's 365), 42 of them left running in `justsessions-claude-*` tmux sessions with no tab, 14 more on this Mac, while a script on the VM appended a line to 30 random session files a second. Each sync's work before its await took 3.3–3.8 ms with this Mac's 14 tmux sessions alone, and 29–32 ms, every second, once the host's refresh had listed its 40; `sample` put nearly all of the main thread's non-idle time in those two functions, copying and comparing `Conversation` values. The same run showed each refresh listing the host 7 times, from the mirror and then from each of the 6 tools' copies, and a tool whose copy found nothing new still cost 5–24 ms on the main actor: a sort of all 3,365 (2–12 ms), a deep comparison, a dictionary of every session to sync the tabs' titles, and a save of the open tabs. Each refresh also published unchanged tmux names and login state.

**Change:** `listedSession(inTmuxSessionNamed:on:)` looks the session up in `ConversationIndex` by `Conversation.id(provider:sessionID:host:)`, so a sync costs the tmux sessions, not their product with the list. `applyRemoteHostConversations(_:of:host:)` compares a tool's copy with the tool's listed sessions in one pass and, when they are the same, leaves the list alone; the last tool's step still gives up a tab waiting for a session that is gone (SSH-61). `synchronizeTerminalTitles` goes through the index instead of building a dictionary of every session. `setTmuxSessionNames` and `noteLoginState` publish only a change (PERF-05).

**Measured:** the same probe build and VM scenario before and after, and the two measurement suites in release builds of the base commit `4f72ede2` and of `ec3f820d`. Apple M4 Max (14 cores), 36 GB, macOS 27.0.1, Swift 6.4; the VM is Ubuntu 24.04.5 with tmux 3.4 in Multipass on the same Mac. The machine wasn't isolated.

| Operation | Before | After |
| --- | --- | --- |
| A sync's main-actor work in the app, 3,365 listed, 56 in tmux with no tab, once a second | 29–32 ms | 0.5 ms |
| `CLIActivitySyncMeasurements`, median main-thread CPU a sync, 3,365 listed, 58 in tmux | 4.5 ms | 0.1 ms |
| `CLIActivitySyncMeasurements`, median main-thread CPU a sync, 10,365 listed, 100 in tmux | 20.3 ms | 0.1 ms |
| An unchanged tool's step in the app, 3,365 listed | 5.0–23.7 ms | 0.8–4.9 ms |
| `RemoteToolStepMeasurements`, median unchanged step, 3,000 sessions | 6.4 ms | 0.9 ms |
| `RemoteToolStepMeasurements`, median unchanged step, 10,000 sessions | 21.6 ms | 3.1 ms |
| `replaceConversations` per refresh of the host | 7 | 2: the mirror, and the one tool whose copy changed |
| Main-queue gaps over 30 ms in 4 minutes | 2 | 2 |

The two gaps, 36–44 ms, came with the launch and with the opening of the new session's tab in both runs.

**Limits:**
- **No gap over 30 ms came from either pattern at this size:** 30 ms a second is a steady 3% of the main thread in pieces just under the watchdog's threshold. The cost grows with the tmux sessions times the listed sessions, and the report came from a host with more of both; it wasn't reproduced there.
- **A changed tool's step still sorts and compares the whole list:** 18–19 ms with 3,365 listed, once per refresh while the VM kept writing.
- **Not changed, off the main thread:** the refresh read the 3,000 mirrored session files for about 170 s on one core (`ClaudeAdapter.discover`, 28 ms a file) because rsync replaces each file the VM wrote to, and a replaced file's summary is read again. The host stays "refreshing" meanwhile, and the copy every 10 seconds for a new tab waiting to link ([budgets, Method](../requirements/performance/budgets.md#method)) is skipped until it ends.
- **The live run showed the host's tmux sessions only in its last minute:** a host's tmux session names arrive with its status call at the end of its refresh.
- **The suites run one case at a time:** Swift Testing ran the sync suite's two cases together on the main actor, and each case's syncs ran while the other's awaited its reader's task, so both cases first reported the same 25 ms a sync whatever their size. They are `.serialized` now, and the sync suite reports the main thread's CPU time per sync beside the wall clock.

## How to profile

Attach to a running copy, so you keep your windows and sessions. Record in chunks, so you can analyze finished chunks while still using the app:

```sh
pid=$(pgrep -f 'JustSessions.app/Contents/MacOS/JustSessions' | head -1)
xcrun xctrace record --template 'Time Profiler' --instrument Hangs --attach "$pid" --time-limit 120s --output chunk.trace
xcrun xctrace export --input chunk.trace --xpath '/trace-toc/run[@number="1"]/data/table[@schema="time-profile"]' > samples.xml
xcrun xctrace export --input chunk.trace --xpath '/trace-toc/run[@number="1"]/data/table[@schema="potential-hangs"]' > hangs.xml
```

Or open the trace in Instruments. Keep these points in mind:

- **Leave the SwiftUI instrument out of CPU profiles.** Its tracing shows up in the samples. Record it separately and briefly to find which state changes cause updates.
- **Profile a build made like the release.** The release is built on GitHub's `macos-latest` runner, with the macOS 26.5 SDK for v1.0.8. A build with a newer local SDK can compile some calls differently, as item 3 shows. Check a binary's SDK with `otool -l <binary> | grep -A4 LC_BUILD_VERSION`, and build with the Command Line Tools' SDK by setting `DEVELOPER_DIR=/Library/Developer/CommandLineTools`.
- **Test with an accessibility client running.** Many users run Raycast or a window manager, and SwiftUI's accessibility work only happens while one is connected.
- **Measurement suites:** the suites in `Tests/JustSessionsTests/Performance/` record only with `JUSTSESSIONS_PERF=1`; see their doc comments.
  - `MessageSearchReadingMeasurements`: reading generated sessions with images for message search, decoding the images and leaving them undecoded.
  - `IncrementalMessageSearchMeasurements`: a growing Codex session's search text, read in full on every change against resumed, for 10, 100, and 500 MiB logs and a realistic 27 MiB one.
  - `SharedWorkspaceReadMeasurements`: isolated and app-shared message indexing and full discovery with one, two, and four workspace consumers.
  - `SidebarInteractionMeasurements`: sidebar interactions.
  - `TerminalVisibilityMeasurements`: hidden terminals.
  - `TerminalWindowVisibilityMeasurements`: a selected terminal while its window is in sight, covered, or minimized.
  - `TerminalFairnessMeasurements`: keystroke-to-echo time in a quiet terminal while other terminals flood, visible and hidden, at full and at set rates.
  - `TerminalEngineMeasurements`: Ghostty and SwiftTerm tabs under the same output, and their memory; see [Terminal engines](#terminal-engines-ghostty-and-swiftterm) and [Build and release](build-and-release.md#performance-measurements) for the commands.
  - `TranscriptInteractionMeasurements`: scrolling, hit testing, and opening Find in a 240- and 640-entry transcript, with SwiftUI's accessibility off and on. Run it with `JUSTSESSIONS_PERF=1 swift test -c release --filter TranscriptInteractionMeasurements`.
  - `OpenCodeTranscriptPagingMeasurements`: paging through OpenCode sessions of 1,000 and 10,000 messages, and reading them for message search.
  - `TranscriptImageDecodingMeasurements`: opening one, two, or four readers of a session full of screenshots, then opening it again.
  - `TabBarDragMeasurements`: one pointer move while a tab, or a group by its label, is dragged along a bar of 18 tabs in 3 groups.
