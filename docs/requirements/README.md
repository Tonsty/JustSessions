# Feature requirements

[Back to documentation](../README.md) · [Performance](../development/performance.md) · [Source layout](../development/source-layout.md)

This is the list of behavior JustSessions has chosen on purpose, collected from the full commit history (397 commits, 23 September to 10 October 2026). Use it to catch regressions: a change that breaks a line here is a bug unless the same pull request changes the line on purpose.

Each requirement states the current behavior, not its history. When a later commit replaced an earlier choice, only the later one is listed, and [Removed on purpose](removed-on-purpose.md) records what must not come back.

## How to use it

- **Before a behavior change**, read the files for the area you touch. If your change contradicts a line, either keep the behavior or update the line in the same pull request and say why.
- **When adding a feature**, add a line with the next free ID in its area. Keep the wording to what a user sees or what must stay true.
- **When reviewing**, check the diff against the affected lines, and against the performance budgets.
- IDs are stable. Don't reuse a retired ID; mark it *Retired* with the commit that retired it.

## Columns

| Column | Meaning |
| --- | --- |
| ID | Area prefix and number, such as `TAB-04`. |
| Requirement | What must stay true. |
| Origin | The commits that introduced or last defined it. `git show <sha>` gives the reasoning. |
| Related tests | Test suites whose names match the behavior, under `Tests/JustSessionsTests`. They were matched by name, not audited line by line, so treat them as where to look and extend, not as proof of coverage. *Manual* means no suite was found; check it by hand. |

## Areas

| Area | File |
| --- | --- |
| Product principles and cross-cutting UI rules (`PRD`) | [product-principles.md](product-principles.md) |
| Session discovery, CLIs, launching (`DSC`) | [sessions/discovery-and-launch.md](sessions/discovery-and-launch.md) |
| Following a tab's CLI, live names (`LIV`) | [sessions/live-following-and-names.md](sessions/live-following-and-names.md) |
| Deletion and archiving (`DEL`) | [sessions/deletion-and-archive.md](sessions/deletion-and-archive.md) |
| Sidebar layout, hosts, menus (`SBL`) | [sidebar/layout-and-menus.md](sidebar/layout-and-menus.md) |
| Sidebar search, filters, pins, selection (`SBF`) | [sidebar/search-filters-pins.md](sidebar/search-filters-pins.md) |
| Conversation reader (`RDR`) | [reader/conversation-reader.md](reader/conversation-reader.md) |
| Tab bar, groups, windows (`TAB`) | [terminal/tabs-and-windows.md](terminal/tabs-and-windows.md) |
| Split view (`SPL`) | [terminal/split-view.md](terminal/split-view.md) |
| Terminal rendering and input (`TRM`) | [terminal/rendering-and-input.md](terminal/rendering-and-input.md) |
| tmux, closing, reopening (`TMX`) | [terminal/lifecycle-and-tmux.md](terminal/lifecycle-and-tmux.md) |
| SSH hosts (`SSH`) | [remote/ssh-hosts.md](remote/ssh-hosts.md) |
| CLI activity and notifications (`ACT`) | [activity/status-and-notifications.md](activity/status-and-notifications.md) |
| Settings and appearance (`SET`) | [app/settings-and-appearance.md](app/settings-and-appearance.md) |
| Onboarding, help, feedback, crashes, updates (`HLP`) | [app/help-feedback-updates.md](app/help-feedback-updates.md) |
| Performance budgets (`PERF`) | [performance/budgets.md](performance/budgets.md) |
| Removed on purpose (`DNR`) | [removed-on-purpose.md](removed-on-purpose.md) |

## Scope

Included: app behavior, UI, and performance the project asked for. Left out: renames, refactors, test-timing fixes, CI plumbing, and website marketing copy. The release process lives in [AGENTS.md](../../AGENTS.md) and [release notes](../development/release-notes.md).

Exact sizes that changed several times, such as the Settings page, are named by their source constant instead of a number. The user guides ([session management](../guides/session-management.md), [getting started](../guides/getting-started.md)) describe the same behavior for users; keep both in step.
