import Foundation

/// A new, empty folder for one test; the test removes it with `defer`.
func makeTemporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent("JustSessionsTests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
}

/// Writes `script` to `file` and makes it executable, standing in for an installed CLI. A stand-in a test gives a
/// time limit is written with `writeTimedStandIn(_:to:)`.
@discardableResult
func writeExecutableScript(_ script: String, to file: URL) throws -> URL {
    try script.write(to: file, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: file.path)
    return file
}

/// Writes a `#!/bin/sh` stand-in that a test gives a time limit, and runs it once first, ending at a line added after
/// `#!/bin/sh`, so that run does nothing the test could count.
///
/// macOS checks each newly written executable the first time it runs, one file at a time, about 140 ms each; a file
/// that has run once starts in milliseconds. With the whole suite writing stand-ins in parallel, that queue reached
/// seconds, past the few seconds such a test gives its stand-in. The run here waits its turn before the test starts
/// timing. It must not wait on the main thread: running every stand-in once there held up the main-actor tests, and
/// two of them failed in each run.
@discardableResult
func writeTimedStandIn(_ script: String, to file: URL) throws -> URL {
    dispatchPrecondition(condition: .notOnQueue(.main))
    let shebang = "#!/bin/sh\n"
    precondition(script.hasPrefix(shebang), "A timed stand-in is a #!/bin/sh script")
    try writeExecutableScript(shebang + standInFirstRunExit + script.dropFirst(shebang.count), to: file)
    let process = Process()
    process.executableURL = file
    process.environment = [standInFirstRunVariable: "1"]
    process.standardInput = FileHandle.nullDevice
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    let exited = DispatchSemaphore(value: 0)
    process.terminationHandler = { _ in exited.signal() }
    try process.run()
    exited.wait()
    return file
}

private let standInFirstRunVariable = "JUSTSESSIONS_TEST_STAND_IN_FIRST_RUN"
private let standInFirstRunExit = "[ -z \"$\(standInFirstRunVariable)\" ] || exit 0\n"
