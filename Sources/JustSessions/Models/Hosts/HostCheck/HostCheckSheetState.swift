import Foundation

/// The host check a window shows: while it runs, then its report. Check again keeps the sheet and starts a new run.
struct HostCheckSheetState: Identifiable, Equatable, Sendable {
    let id = UUID()
    let host: String
    let session: HostCheckSession?
    /// Changes with each run, so a run that finishes after a newer one started shows nothing.
    var runID = UUID()
    var report: HostCheckReport?
    /// The step the run is on while it runs, and since when.
    var step = HostCheckStep.logIn
    var stepStartedAt = Date.now

    var isChecking: Bool { report == nil }
}
