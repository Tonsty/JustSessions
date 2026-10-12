# README screenshots

Refreshed on October 10, 2026 from the current native interface at revision `e8003c06e3151130cb7d7367b6795b8be5432e17`. An isolated sample app links the production SwiftUI and AppKit views and models built by `make check`. It has its own bundle identifier, preferences, agent storage, projects, and tmux socket directory. The user's app and conversations are not screenshot content.

| Image | What it shows |
| --- | --- |
| [native-terminal.jpg](native-terminal.jpg) | The real Claude Code `/help` interface with **Projects** selected. `orbit-web` groups five sessions: two Claude Code sessions, Codex, OpenCode, and Pi. |
| [split-terminal.jpg](split-terminal.jpg) | **Open tabs** lists six terminals under one project. The split pairs Claude Code's command input with a shell showing a real Git diff. |
| [session-overview.jpg](session-overview.jpg) | The current conversation reader, project and host groups, reading controls, and Resume action. |
| [remote-desktop-sessions.jpg](remote-desktop-sessions.jpg) | A sample Claude Code conversation under the `dev-desktop` SSH host, beside local projects. |
| [tmux-keep-running.jpg](tmux-keep-running.jpg) | A running file-indexing task after closing its tab with **Keep running** and reattaching through the sidebar. |
| [tmux-close-choice.jpg](tmux-close-choice.jpg) | The actual close-tab dialog, including **Don't ask again**, Keep running, End session, and Cancel. |
| [demo-split-view.jpg](demo-split-view.jpg) | Used only by the social card. The split-view frame at 28.0 seconds of the homepage demo, recorded October 11, 2026 from v1.2.6: Claude Code and Codex side by side, with `orbit-web`, `orbit-api`, and the `devbox` SSH host in the sidebar. The window is cropped from the 3200 × 1800 recording, its rounded corners are filled with the page color, and it is scaled to 2400 × 1350. See [demo provenance](../../website/media/README.md). |

Full windows are captured at 2400 × 1440 pixels. The close-tab dialog is 520 × 540. These stills are native captures; the homepage uses a [narrated demo video](../../website/media/README.md). The Slack/social card is rendered from `demo-split-view.jpg`.

The project names, SSH hosts, and saved messages are examples. Remote history is fixture data, with no live SSH connection demonstrated. Claude Code 2.1.296, Codex 0.162.0-alpha.17.2, and OpenCode 1.18.35 are installed CLIs. Capture profiles are isolated from the user's credentials. Published footage shows local help, sample history, and local shell commands; it does not show a model response or performance benchmark. The indexing task hashes 500 disposable files. The split-view shell shows an actual uncommitted change in a sample Git repository.

When replacing assets, use the current native interface, record the source revision, and update README alt text, demo posters, social card, and highlight coordinates together. Keep raw captures and sample-app code in ignored `dist/` folders. Stop the isolated sample tmux server after capture.
