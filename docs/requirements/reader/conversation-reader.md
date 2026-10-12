# Conversation reader

[Back to requirements](../README.md)

The preview beside the sidebar and the separate reading windows share one reader. Performance rules for it are in [performance budgets](../performance/budgets.md#reader).

## Content

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| RDR-01 | Every supported CLI's conversation can be read without starting the CLI: your messages and the agent's replies, with runs of tool calls collapsed into one expandable row. | `ed256ab`, `4197645` | `TranscriptBuilderTests`, per-provider `*TranscriptReaderTests` |
| RDR-02 | Pi previews follow the current branch (the parent chain from the last entry); branches left behind with `/tree` are not shown. `/skill` shows as typed; compaction, branch summaries, and failed replies show as notes. | `d89ae09` | `PiActiveBranchTests`, `PiPreviewedEntryTests` |
| RDR-03 | Images you attached and images a tool returned are shown in place for Claude Code, Codex, and Pi, at the reading column's width, with their shape reserved from the image header before they decode. | `d4f0a5d` | `TranscriptImageTests` |
| RDR-04 | Markdown, tables, and code blocks render readably; wide tables and code scroll sideways; code blocks have **Copy**. | `51f3711` | `TranscriptMarkdownParserTests`, `TranscriptReadingRenderingTests` |
| RDR-05 | Copy conversation and Export conversation (Markdown or plain text) are offered from the session's and the tab's menus. | `2c368d5` | `ConversationExportFormattingTests`, `ConversationExportLoadingTests` |
| RDR-06 | A session open in another window says so in its preview and offers **Show** and, when tmux runs it, **Move Here**. | `0f3fd89`, `70a1137` | `SessionTabAcrossWindowsTests` |

## Paging and position

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| RDR-20 | Large conversations load in pages, starting at the latest messages or the saved reading position. | `172ef9b` | `TranscriptPagingModelTests`, `TranscriptPageSourceTests` |
| RDR-21 | Pages load automatically as the viewport nears either end, including inside a tall message and right after a restored position. **Load earlier / later messages** stay for manual loading and retries. First and latest jump past what is loaded. | `ff803b7` | `TranscriptAutomaticPagingTests`, `TranscriptPagingViewportTests` |
| RDR-22 | Loading a page keeps the message being read at the same offset, even while scrolling, and restores it in the layout pass that moves it, before the window draws. | `ff803b7`, `5ae6c53` | `TranscriptPagingScrollTests`, `TranscriptScrollRestorationTests` |
| RDR-23 | The reader keeps three pages, and up to eight while short pages are all near the viewport. Pages never push each other out in a loop. | `ff803b7`, `5ae6c53` | `TranscriptPagingViewportTests` |
| RDR-24 | Scrolling never freezes or bounces: a wheel scroll ends a restoration once it has placed the reader. | `5ae6c53` | `TranscriptScrollViewReadingPositionTests` |
| RDR-25 | A turn's label comes from the entry before its page in the session, so labels never appear or move as pages load and leave. | `5ae6c53` | `TranscriptPagingRenderingTests` |
| RDR-26 | Opening a session whose CLI is still writing never fails: the index scan fails only if the file shrinks, and appended lines extend the index on the next refresh. | `6f9363f`, `b48e8af` | `TranscriptIncrementalIndexTests` |
| RDR-27 | Switching sessions restores each one's reading position while the window stays open, including inside a long message. Positions are not kept across restarts. A reading window keeps its own until it closes. | `51f3711` | `TranscriptReadingPositionTests`, `TranscriptTallMessageReadingPositionTests` |
| RDR-28 | Unpaged transcripts arrive with their Markdown prepared before the first layout, so no message changes height after the position is restored. | `bc5d66d` | `PreparedTranscriptMarkdownTests` |

## Controls

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| RDR-40 | Text size: A− and A+, or ⌘+ (also ⌘=), ⌘−, and ⌘0, from 12 to 22 points, default 15. | `51f3711`, `19b4af9` | `TranscriptReadingTextSizeTests`, `ZoomInEqualsKeyTests` |
| RDR-41 | Width: a toolbar button switches between a readable column (`TranscriptReadingWidth.readableColumnWidth`, 760 points) and the full window width. Readable is the default. | `fdd8e43` | `TranscriptReadingWidthTests`, `TranscriptReadingWidthLayoutTests` |
| RDR-42 | Text size and width are shared by the preview and every reading window and remembered after quitting. Changing either keeps the message being read at the same offset. | `fdd8e43`, `5fb0094`, `19b4af9` | `TranscriptReadingWidthPositionTests`, `TranscriptReadingTextSizeTests` |
| RDR-43 | Find (⌘F or the toolbar's magnifying glass) ignores case and accents and covers message text, code, table cells, and tool summaries. Return or ⌘G goes next, Shift-Return or ⇧⌘G back, wrapping at both ends; Escape closes. The selected match is highlighted and revealed, opening a tool summary's disclosure. Each reader has its own Find. | `c6f7cd4` | `TranscriptSearchContextTests`, `TranscriptAttributedTextTests` |
| RDR-44 | Automatic paging pauses while Find is open or a drag is selecting text, and resumes at the current boundary when either ends. Reader shortcuts never reach a running CLI's terminal. | `c6f7cd4`, `ff803b7` | `TranscriptAutomaticPagingTests` |
| RDR-45 | The reading window button sits at the end of the reading toolbar. A reading window opens at the current position without changing the selected terminal; opening it again for the same session brings that window forward. | `51f3711`, `33f32d4` | `SessionReadingWindowTests` |
| RDR-46 | Creating the reader's text view never crashes (it overrides `init(frame:textContainer:)` for macOS 26). | `fa40be7` | `TranscriptTextViewTests` |
| RDR-47 | A selection runs across paragraphs, list items, code, table cells, tool summaries, and messages. Drag across them, with the reader scrolling while the pointer is held past its edge, or Shift-click to extend. ⌘A selects all loaded text. ⌘C, or Copy from the right-click menu, copies it in reading order: list markers kept, a tab between table cells, a blank line between blocks. A double or triple click selects a word or line within its block; a click, or Escape while Find is closed, clears it. Every block draws the selection in the accent while the reader has the keyboard. Text looks and lays out as it did when each block was its own selectable SwiftUI text. | `263336d` | `TranscriptTextSelectionCoordinatorTests`, `TranscriptTextSelectionCopyTests`, `TranscriptTextSelectionTests`, `TranscriptTextViewTests` |
