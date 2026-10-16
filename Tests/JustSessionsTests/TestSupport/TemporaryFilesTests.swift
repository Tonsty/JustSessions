import Foundation
import Testing

struct TemporaryFilesTests {
    /// The run `writeTimedStandIn` makes first, so macOS has checked the file, ends before anything the script does,
    /// which a test may count.
    @Test func aStandInDoesNothingUntilATestRunsIt() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let runsLog = root.appendingPathComponent("runs.log")
        let standIn = try writeTimedStandIn(
            "#!/bin/sh\necho run >> '\(runsLog.path)'\necho \"$1\"\n",
            to: root.appendingPathComponent("cli")
        )

        #expect(!FileManager.default.fileExists(atPath: runsLog.path))

        let result = BoundedProcessRunnerOutput.run(standIn, arguments: ["--version"])

        #expect(result == "--version\n")
        #expect(try String(contentsOf: runsLog, encoding: .utf8) == "run\n")
    }
}

/// What a stand-in prints when a test runs it the ordinary way.
private enum BoundedProcessRunnerOutput {
    static func run(_ executable: URL, arguments: [String]) -> String? {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        guard (try? process.run()) != nil else { return nil }
        process.waitUntilExit()
        return String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
    }
}
