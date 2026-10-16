# Sidebar layout, hosts, and menus

[Back to requirements](../README.md)

## Layout

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| SBL-01 | The sidebar's width is draggable and remembered. A drag is measured in window coordinates so the panes never shake, widths round to whole points, and resizing triggers no conversation work. | `6332593`, `9e6c11c`, `8c199d4` | `SidebarResizeHandleTests` |
| SBL-02 | The divider shows the column-resize cursor (SwiftUI's pointer style on macOS 15 and later, pointing one way at either limit; a cursor rect on macOS 14). | `694b8fa`, `539aefe` | `SidebarResizeHandleTests` |
| SBL-03 | The divider is a one-point line. Its grab area lies over the line and the detail's leading margin and draws nothing until hovered, so the tab bar and a dark terminal run right up to it. | `825e41c` | Manual |
| SBL-04 | The header is one line: the app mark and name, then search, the notification bell, and a **+** for New session. A sidebar too narrow for the whole name shows the mark alone. The **+** sits on the same soft chip as the filter; sidebar icons are outline glyphs. | `cb9c604`, `462bcf6`, `f1aab74`, `43b52f2`, `b20f964`, `3e0b7b1`, `72be7d9` | Manual |
| SBL-05 | Search opens as a field across the header line. Escape or its × clears and closes it; an empty field closes when you click elsewhere. | `462bcf6` | `SidebarProjectFilteringTests` |
| SBL-06 | **Projects** and **Open tabs** are two sidebar views. Each keeps its own search and scroll position when switching; each window remembers its view. Switching never changes the selected terminal. | `1c369eb` | `SidebarContentPanelsTests` |
| SBL-07 | The footer is one line with **Add SSH host…** at the bottom left and Settings; it never truncates Add SSH host. | `4786422`, `462bcf6`, `b20f964` | Manual |
| SBL-08 | The sidebar can be hidden with the title-bar button beside the window buttons, View → Hide Sidebar, or ⌘B, also while a terminal has focus. Each window keeps its own choice; the hidden sidebar keeps its expansion and selection; the window's minimum width drops; in full screen the content leaves a strip for the button. | `67f5bf4`, `ca9e282` | Manual |
| SBL-09 | Colors are the theme's warm neutrals, the title bar is hidden so sidebar and detail colors run to the top, and each CLI's brand hue marks its rows and Resume button. With nothing selected, the detail shows the app mark. | `5ce2695`, `43b52f2` | `ThemeSurfaceRenderingTests` |

## Hosts

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| SBL-20 | Projects always sit under a host heading, **This Mac** first, even with no SSH hosts. A heading shows its refresh state: a spinner, when an SSH host was last copied, or a warning. The warning stays after the host's name, so pointing at it shows the error. | `a2be251`, `bc0a2e8`, `44398c8` | `HostModelTests`, `SidebarEmptyHostMessageTests` |
| SBL-21 | Each host has its own refresh button. Its **+** adds a project (folder panel with New Folder on this Mac, a checked path on SSH); while the host has archived projects, **+** opens a menu with Add project… and Archived projects (…). The added project is listed, selected, and scrolled into view. | `b8755e7`, `f2b470a`, `a658f0b`, `b20f964` | `AddProjectFromHostHeadingTests` |
| SBL-22 | An empty host says why it is empty, including what the status filters can't know for SSH hosts and other CLIs. | `412bd7c`, `8ddfcf5`, `66e5e05` | `SidebarEmptyHostMessageTests` |
| SBL-23 | An SSH host's heading shows a **⋯** on hover with the host's own settings (Connect… or Disconnect, Sign in… or Sign in again… and Sign-in command… (SSH-97–SSH-99), Forward a port… and the host's port forwards (SSH-95), tmux prefix, the shell startup check's last result, Check this host…, Remove host). Its right-click menu has every heading item, ending with the same ones. | `cd8a1a0`, `a719190`, `ec88022`, `9c9888a`, `0c2da67`, `3ecb9b82` | `RemoteTmuxPrefixChoiceTests`, `RemoteShellStartupStoreTests`, `HostCheckStoreTests`, `SSHPortForwardsTests`, `RemoteSignInsTests` |

## Rows and menus

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| SBL-40 | A session row shows how long ago it was active ("5m", "3h", "Sep 16") or its CLI's status while one runs. Rows share one hover and selection style; expanded sessions hang off a guide line. | `cb9c604`, `8fa46b7` | `SidebarSessionDateTextTests`, `CompactRelativeTimeFormatterTests` |
| SBL-41 | Pointing at a project or session row shows **⋯** (and **+** on projects), which opens the same menu as a right-click, from one shared list of items. The buttons keep their room while hidden, so nothing in the row moves. | `05e2089`, `b2f0940`, `97eff05` | Manual |
| SBL-42 | A pinned project shows a pin in place of its folder icon; a pinned session's pin follows its title, after the ellipsis when cut short. | `e929e3c` | Manual |
| SBL-43 | Projects with the same folder name show enough of their parent path to tell apart (`/srv/app` is labelled `srv`; a project at `/` is labelled `/`). | `412bd7c` | `ProjectParentLabelsTests` |
| SBL-44 | A project menu offers New session (installed CLIs, then Terminal), New terminal, Open project in Finder, **Open project in** an installed editor, Copy path, Rename, Pin, Archive, and Archive and delete sessions. | `bcd10be`, `cd9fe10`, `f623508`, `d8e8b4a`, `04b320e` | Manual |
| SBL-45 | **Open project in** lists editors found by bundle identifier (VS Code and forks, Zed, Sublime Text, Nova, Xcode, Android Studio, JetBrains IDEs) with their icons, refreshed when the app comes forward. Hidden when none is installed; disabled when the folder is gone. SSH projects list editors that support Remote - SSH and open `vscode-remote://ssh-remote+<host><path>`, with the host encoded as the extension does. | `cd9fe10`, `fd1431a` | `ExternalEditorStoreTests`, `RemoteSSHFolderURITests`, `RemoteSSHFolderOpenerTests` |
| SBL-46 | The session menu is shared by the sidebar row and the preview's More menu: Resume, Branch, Rename, Pin, Archive (DEL-33), Move to for Claude Code (DSC-54), Copy session ID, Reveal, Copy and Export conversation, Delete. When a tab runs the session it offers **Close terminal…** instead of Resume; when another window has it, **Show in Other Window** and **Move Tab to This Window**. | `97eff05`, `2c368d5`, `5b35d08`, `0f3fd89`, `70a1137`, `310819e0`, `4e97aec` | `ConversationSharingControllerTests` |
| SBL-47 | A click on a session shows its preview. If its CLI runs, the click shows its tab, or reattaches in a new tab when it runs in tmux with no tab. Double-click resumes. | `b4c6d11`, `f1e5820`, `d5c9dfc` | `RunningCLISelectionTests` |
| SBL-48 | **Open tabs** groups this window's tabs by project in tab bar order. A group heading shows the project in its tab-group color, its SSH host, and its tab count, lined up with its rows; rows are one line. Clicking a heading collapses it (chevron); a collapsed group shows its most pressing status; a search expands every group without forgetting which were collapsed; a project whose last tab closed opens expanded next time. The heading offers the project's ⋯ and + for folder actions only. | `0a8d9d0`, `3e01aba`, `416db47` | `OpenTabGroupCollapseTests` |
| SBL-49 | An expanded project lists its pinned sessions, its new sessions, then its 10 most recent other sessions, followed by **Show N more**, which lists 20 more each click (all of them when one would be left). One session past the limit is listed rather than hidden. A search or a status filter lists every match. The session a window shows, by any means, has its row listed. Collapsing the project goes back to 10; each window keeps its own count. Shift-click ranges skip hidden rows. | `10ccc7e` | `ListedProjectSessionRowsTests`, `ProjectSessionRowLimitsTests` |
| SBL-50 | Each CLI has its own icon in session rows, menus, the notification bell, and the preview header: an asterisk for Claude Code, a hexagon with a `>_` prompt cut out for Codex, a sparkle for Antigravity, a ghost for Kiro, a block O for OpenCode, and π for Pi. Shapes tell the CLIs apart without color, and none is a generic terminal or code symbol, which would fit every CLI. Icons fit the row's 14-point icon column. | `0297e57` | `ProviderIconImageTests` |
