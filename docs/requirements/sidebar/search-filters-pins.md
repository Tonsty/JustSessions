# Sidebar search, filters, pins, and selection

[Back to requirements](../README.md)

## Search

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| SBF-01 | Search matches project names and paths, session titles, session IDs, and message text. | `cb71665`, `ed256ab`, `1bb0b55` | `SidebarProjectFilteringTests`, `SearchableSessionTextTests` |
| SBF-02 | Message text is what the reader shows: your messages, the CLI's replies, and tool call summaries, ignoring case and accents, up to each message's preview limit. A matching session stays under its project with the matching line under its title. | `1bb0b55` | `SessionMessageSnippetTests`, `SessionMessageTextReaderTests` |
| SBF-03 | Clicking a message match opens the reader at that message with Find showing the search, also when the session's file changes while the pages load. | `1bb0b55`, `e379e8b` | `TranscriptMatchRevealTests`, `TranscriptSearchStateRevealTests` |
| SBF-04 | Each session is read once for search, most recent first, with progress at the top of the list. Its text is cached in Caches and read again only when its file changes; text of sessions no longer listed is removed after 30 days; the text leaves memory a minute after the last search closes. | `1bb0b55` | `SessionMessageIndexerTests`, `SessionMessageTextCacheTests` |

## Filters

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| SBF-20 | The Projects filter menu offers **Last 7 days**, one CLI (listing only CLIs installed or with sessions), **Running**, and **Waiting for you**. The two status filters are exclusive. Filters never hide open tabs. | `cb9c604`, `12abb26`, `8ddfcf5`, `66e5e05` | `ConversationProviderFilterTests`, `RunningSessionsFilterTests`, `WaitingForYouTests` |
| SBF-21 | **Running** lists sessions whose CLI runs in a tab of any window or in tmux after its tab closed, on this Mac or on an SSH host as of its last refresh. | `66e5e05` | `RunningSessionsFilterTests` |
| SBF-22 | **Waiting for you** lists sessions stopped for your answer or done with a turn you haven't seen, including new sessions' tabs. Empty projects hide while a status filter is on. | `8ddfcf5` | `WaitingForYouTests` |
| SBF-23 | The recent filter moves an aging session out within a minute. | `4878267` | `FilteredSidebarProjectionTests` |

## Pins and names

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| SBF-40 | Projects and sessions can be pinned. Pins keep the order you put them in: a new pin goes last and activity never moves one. Unpinned items stay sorted by activity. | `d5c9dfc`, `dce90de` | `PinnedOrderTests`, `PinnedItemsTests` |
| SBF-41 | A pinned project drags among its host's pinned projects, a pinned session among its project's. Dragging an unpinned one up among them pins it there. A line shows the drop place, the dragged row fades, and a drop lands beside a pinned neighbor in sight so pins hidden by a filter keep their place. Off the list to either side, the line and the row's ghost hide and a drop lands nowhere; over the terminals, a session drops there instead (SPL-15). | `dce90de`, `dc4e62d` | `SidebarPinDragTests`, `PinnedOrderInSidebarTests` |
| SBF-42 | Under a project, rows go pinned sessions, then new sessions still waiting for their CLI, then the rest by last activity. | `fa39b76` | `ProjectSessionRowTests` |
| SBF-43 | A project can be given a display name, kept per project and shown everywhere the project is named. Saving an empty name or the folder name clears it. | `3aabdb2` | `ProjectDisplayNamesTests` |

## Selection

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| SBF-60 | ⌘-click toggles and Shift-click selects a range of sessions, across projects. Right-clicking a selected row resumes, branches, or deletes all of them; a bar at the bottom also offers Delete. | `d5c9dfc` | `SessionMultiSelectionTests` |
| SBF-61 | Projects can be multi-selected the same way, then archived (with or without deleting their sessions) from the bottom bar or a selected project's menu. A project's arrow expands or collapses it without changing the selection. | `e53fdf3`, `73cc919` | `ProjectMultiSelectionTests`, `SidebarProjectBatchRemovalTests` |
| SBF-62 | Clicking empty sidebar space, or Escape while the sidebar has focus, cancels a batch selection; a single session's conversation stays open. | `36f23f8` | `SessionMultiSelectionTests` |
