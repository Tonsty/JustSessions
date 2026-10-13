import Foundation
import Testing
@testable import JustSessions

struct ClaudeTranscriptTailTests {
    @Test func readsTheLastTimestampAndTheLastCustomTitle() {
        let tail = ClaudeTranscriptTail(lines: jsonLines([
            #"{"type":"custom-title","customTitle":"First name","timestamp":"2026-09-24T10:00:00Z"}"#,
            #"{"type":"custom-title","customTitle":"Second name"}"#,
            #"{"type":"user","timestamp":"2026-09-24T11:00:00Z","message":{"content":"Keep going"}}"#,
            #"{"type":"summary","summary":"No timestamp here"}"#,
            "not json",
        ]))

        #expect(tail.latestTimestamp == ConversationMetadata.date("2026-09-24T11:00:00Z"))
        #expect(tail.latestCustomTitle == "Second name")
    }

    @Test func aTranscriptWithNeitherSaysNothing() {
        let tail = ClaudeTranscriptTail(lines: jsonLines([#"{"type":"user","message":{"content":"Hi"}}"#]))

        #expect(tail.latestTimestamp == nil)
        #expect(tail.latestCustomTitle == nil)
        #expect(tail.relocatedWorkingDirectory == nil)
    }

    /// Claude Code 2.1.296 writes a `relocated` line when `/cd` moves a session, and again with the session's other
    /// metadata. The last one names the folder the session is in now.
    @Test func readsTheFolderOfTheLastRelocatedLine() {
        let tail = ClaudeTranscriptTail(lines: jsonLines([
            #"{"type":"relocated","sessionId":"s1","relocatedCwd":"/Users/me/first-move"}"#,
            #"{"type":"user","cwd":"/Users/me/first-move","timestamp":"2026-10-13T10:00:00Z","message":{"content":"Keep going"}}"#,
            #"{"type":"relocated","sessionId":"s1","relocatedCwd":"/Users/me/second-move"}"#,
            #"{"type":"user","cwd":"/Users/me/second-move/web","timestamp":"2026-10-13T11:00:00Z","message":{"content":"Build it"}}"#,
        ]))

        #expect(tail.relocatedWorkingDirectory == "/Users/me/second-move")
    }

    @Test func aRelocatedLineOlderThanTheTimestampAndTitleIsStillRead() {
        let tail = ClaudeTranscriptTail(lines: jsonLines([
            #"{"type":"relocated","sessionId":"s1","relocatedCwd":"/Users/me/other"}"#,
            #"{"type":"user","cwd":"/Users/me/other","timestamp":"2026-10-13T10:00:00Z","message":{"content":"Keep going"}}"#,
            #"{"type":"custom-title","customTitle":"Moved session"}"#,
            #"{"type":"assistant","timestamp":"2026-10-13T10:01:00Z","message":{"content":"Done"}}"#,
        ]))

        #expect(tail.latestTimestamp == ConversationMetadata.date("2026-10-13T10:01:00Z"))
        #expect(tail.latestCustomTitle == "Moved session")
        #expect(tail.relocatedWorkingDirectory == "/Users/me/other")
    }

    @Test func onlyTheEndOfALongTranscriptIsRead() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("\(UUID().uuidString).jsonl")
        let filler = String(repeating: #"{"type":"assistant"}"# + "\n", count: 13_000)
        #expect(filler.utf8.count > ClaudeTranscriptTail.maximumByteCount)
        let earlyTitle = #"{"type":"custom-title","customTitle":"Early name"}"# + "\n"
        let lastLine = #"{"type":"user","timestamp":"2026-09-24T11:00:00Z"}"# + "\n"
        try (earlyTitle + filler + lastLine).write(to: file, atomically: true, encoding: .utf8)

        let tail = ClaudeTranscriptTail(file: file)
        #expect(tail.latestCustomTitle == nil)
        #expect(tail.latestTimestamp == ConversationMetadata.date("2026-09-24T11:00:00Z"))
    }
}
