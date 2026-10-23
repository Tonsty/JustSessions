/// What the New session sheet asks to start: a tool or a terminal, on a host, in the folder typed there. The folder is
/// created first only when the sheet offered to create it and that offer was taken.
struct NewSessionRequest {
    let kind: NewSessionKind
    let host: SessionHost
    let folder: String
    let creatingMissingFolder: Bool
    /// A tool's session is deleted when its tab closes; never set for a terminal, which is no session.
    let deletesSessionWhenClosed: Bool
}
