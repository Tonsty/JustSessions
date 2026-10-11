import Foundation

/// A new folder under `/tmp` for a test's sockets: the usual temporary folder's path is longer than a Unix socket's
/// address holds. The test removes it with `defer`.
func makeShortSocketFolder() -> String {
    "/tmp/jst-\(UUID().uuidString.prefix(8))"
}
