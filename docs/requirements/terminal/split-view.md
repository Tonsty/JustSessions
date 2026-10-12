# Split view

[Back to requirements](../README.md)

Split view follows Chrome's `TabStripModel`. Rules are pure functions in `TerminalTabStrip`, `TerminalSplitLayout`, and `TerminalSplitPair`.

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| SPL-01 | Any number of splits can be open, each tab in at most one. A split's left pane is whichever of its tabs comes first in the bar. | `ccf1df7` | `TerminalTabStripTests`, `TerminalSplitRules` |
| SPL-02 | A new split moves the other tab next to the selected one, into the selected tab's group. A tab from another project goes back to its own group when the split is separated or its partner closes. A split whose group loses its project's last tab takes its left tab's project. | `ccf1df7`, `457652d` | `TerminalSplitStoreTests` |
| SPL-03 | Tab menu entries use Chrome's names: New split view with current tab, Add tab to new split view (naming each tab's project), Move tab into split view (left or right), and Arrange split view (separate, close left or right view, reverse). The Tabs menu offers Separate Views, Close Left View, Close Right View, and Reverse Views for the shown split. | `9cd4b9e`, `457652d` | `TerminalSplitStoreTests` |
| SPL-04 | A split's two tabs join into one tab in the strip, each half as wide. While the split shows, both look selected; while not, hovering either lights both. | `9cd4b9e` | Manual |
| SPL-05 | While a split shows, both terminals draw, each in a rounded outline (darker around the selected one) with a small toolbar in its corner. Each terminal ends above its toolbar, so a CLI's last rows are never covered. | `ff8f38f`, `9cd4b9e`, `457652d` | Manual |
| SPL-06 | Clicking the other pane selects its tab from the terminal's own mouse-down, so scrolling and selecting text there work; the unselected pane is dimmed in the terminal's colors. The selected terminal keeps the keyboard as tabs reorder. | `ff8f38f`, `457652d` | `TerminalSplitFocusTests` |
| SPL-07 | The divider drags with the column-resize cursor, snaps the panes even within 15 points of the middle, and reverses the views on double-click. Panes keep their widths while another tab shows. After the window narrows, the divider and VoiceOver use the fraction clamped to the current width. | `ff8f38f`, `1df57a4`, `457652d` | `TerminalSplitLayoutTests` |
| SPL-08 | The divider keeps its position only when a tab keeps its side; a new pair that merely shares a tab starts even. | `1df57a4` | `TerminalSplitLayoutTests` |
| SPL-09 | Closing either half unlinks the split; closing the shown half leaves the other in front at full width. A reopened tab still waiting to be shown starts when it joins a split. | `e0418fe`, `ff8f38f` | `TerminalSplitStoreTests` |
| SPL-10 | Moving between split panes, separating, or swapping never refreshes a host on every click; a New session or Branch tab refreshes its host only when it goes off screen. | `1df57a4`, `457652d` | `TerminalSplitStoreTests` |
| SPL-11 | The visible pane sends no notifications, and showing a tab in a split clears its unseen-turn mark. | `ff8f38f`, `ab6eae7` | `UnseenFinishedTurnEndToEndTests` |
| SPL-12 | Splits are not saved across quits; their tabs reopen on their own, each in its project's group. | `ccf1df7` | `OpenTabPersistenceTests` |
| SPL-13 | VoiceOver reads a split tab's status before its title and side. | `457652d` | Manual |
| SPL-14 | One tab, neither the selected one nor in a split, dragged over the terminals shows where it would land, as in Claude Code: the half of a new split, or the shown split's pane on that side, parted at the resize area, tinted and outlined with the tab's title. Let go, it shows there selected, beside the selected tab or in place of that pane's tab. It drops the same way from its own bar, a window carrying it, or another window; a carrying window hides while over the terminals. | `e2e3a19` | `TerminalSplitDropAreaTests`, `TerminalSplitDropStoreTests`, Manual |
| SPL-15 | A session row in Projects, a new session's row, or an Open tabs row dragged onto its window's terminals drops as SPL-14 does; a session with no tab open is resumed in a new tab first. With no tab selected, the whole area lights up, and letting go resumes the session or selects its tab. Nothing lights up for the selected tab, a split's tab, a session another window's tab runs, or one that can't be resumed. Clicking the row still selects it, and dragging within the list still pins it (SBF-41). | `dc4e62d` | `SidebarRowDropStoreTests`, `TerminalSplitDropAreaTests`, Manual |
