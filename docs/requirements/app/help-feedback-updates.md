# Onboarding, help, feedback, crashes, and updates

[Back to requirements](../README.md)

## Onboarding

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| HLP-01 | A fresh install's first window walks through the sidebar once This Mac's sessions are listed: a project and its sessions (or why the list is empty), New session, and SSH hosts. Each tip is a popover on the real control, so it can be tried while shown. Installs that already had settings see nothing on their own. | `b69a51b` | `OnboardingTourTests`, `OnboardingTourStopTests` |
| HLP-02 | After the tour, tips show once each the first time a part is used: Resume and Find when reading, the right-click menu and search when reading another, the group label and sidebar toggle on the first tab, Keep running on the first tab that can, Open tabs and split view on a second tab. | `e050101`, `322b03d` | `OnboardingTipDueTests`, `OnboardingTipsStoreTests` |
| HLP-03 | Tips hide while a sheet is open or their control is scrolled away, move past a stop whose control goes out of use, and say **Skip**, not "skip tour". The tips shown are saved, so tips added later still reach existing installs. | `b69a51b`, `e050101` | `OnboardingTipsStoreTests` |
| HLP-04 | Help → Take the Tour, or Take the tour in Settings → Help, starts the tour again and shows every tip again afterwards. | `b69a51b`, `322b03d` | `OnboardingTourTests` |
| HLP-05 | Each launch, the bottom of the sidebar shows one random tip about something the app can do, picked among tips not shown yet so none repeats before all have shown. → shows another; × hides it until the next launch. A launch that shows the tour shows none, and the tip steps aside while the tour or a first-use tip shows. Settings → Help, or the tip's right-click **Don't show tips**, turns tips off for good. One tip names **Check this host…** (SSH-50), so it is known before a host fails. | `047a2ac`, `674d8ad`, `f654809` | `RandomTipsStoreTests`, `RandomTipRotationTests` |

## Help and feedback

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| HLP-20 | Settings → Help (also Help → JustSessions Help) covers the tour, how the window works, what an SSH host needs, what to check when a session is missing, and every keyboard shortcut grouped by where it applies. It links to the online Guide, not the GitHub repository. | `52b82b9`, `603eec3`, `c911be4`, `b20f964` | Manual |
| HLP-21 | **Send feedback** (Settings → General, Help → Send Feedback) opens the website Guide's feedback form in the browser with the app and macOS versions in the address. **Report an issue** opens a GitHub issue with the versions filled in. There is no in-app feedback form. | `30f1b46`, `322b03d` | `FeedbackLinksTests` |

## Crash reports

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| HLP-40 | At launch, the app looks for a crash report of its own bundle identifier written since the last launch (a week back on the first launch) and offers it once in a sheet: Report on GitHub, Report by Email, or Not Now. | `04b8a02` | `CrashReportFinderTests`, `LaunchCrashReportOfferTests` |
| HLP-41 | The report text holds the app and macOS versions, the exception, crashing libraries' messages, and up to 16 frames, with symbol and library names only, never paths. The `.ips` file is shown in Finder to attach. Nothing is sent unless the user sends it. | `04b8a02` | `CrashReportSummaryTests`, `CrashReportLinksTests` |
| HLP-42 | `make verify`'s launch check turns the offer off, so it neither shows nor marks a developer's crashes as offered. | `04b8a02` | `make verify` |

## Updates and privacy

| ID | Requirement | Origin | Related tests |
| --- | --- | --- | --- |
| HLP-60 | Sparkle checks go through the update Worker, which counts checks per UTC day and app version and stores no IP address, user agent, or other identifier. | `fcf528c` | `Cloudflare` Worker tests in `make verify` |
| HLP-61 | Release notes come from one curated catalog shared by the app, the website, and updates. The website lists only releases already published on GitHub. | `fac429c`, `80a2d81` | `AppReleaseHistoryTests`, website tests |
