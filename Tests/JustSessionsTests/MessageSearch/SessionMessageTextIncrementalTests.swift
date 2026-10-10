import Foundation
import Testing
@testable import JustSessions

@Suite(.serialized)
struct SessionMessageTextIncrementalTests {
    private func line(_ text: String) -> String {
        #"{"timestamp":"2026-10-02T12:00:00.000Z","type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"\#(text)"}]}}"#
    }

    private func toolLine(_ name: String) -> String {
        #"{"timestamp":"2026-10-02T12:00:00.000Z","type":"response_item","payload":{"type":"function_call","name":"\#(name)","arguments":"{}"}}"#
    }

    private func append(_ bytes: Data, to file: URL) throws {
        let handle = try FileHandle(forWritingTo: file)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: bytes)
    }

    private func fullText(_ conversation: Conversation, limits: TranscriptPageLimits = SessionMessageTextReader.wholeSessionLimits) async throws
        -> SessionMessageText
    {
        try await SessionMessageTextReader.readResult(conversation, limits: limits).text
    }

    @Test func appendsOnlyReparseTheUncommittedPageAndEqualACleanRead() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("rollout.jsonl")
        let initial = (0..<7).map { $0.isMultiple(of: 2) ? line("Message \($0): Café 中文 👋") : toolLine("tool_\($0)") }
        try (initial.joined(separator: "\n") + "\n").write(to: file, atomically: true, encoding: .utf8)
        let conversation = Conversation.fixture(provider: .codex, sourceFile: file)
        let limits = TranscriptPageLimits(targetEntryCount: 2, maximumRecordCount: 20, targetByteCount: 1 << 20)
        var result = try await SessionMessageTextReader.readResult(conversation, limits: limits)

        for number in 7..<10 {
            try append(Data((line("Appended **message** \(number): naïve 中文 🧪") + "\n").utf8), to: file)
            result = try await SessionMessageTextReader.readResult(
                conversation, resuming: (result.text, try #require(result.state)), limits: limits
            )
            let clean = try await fullText(conversation, limits: limits)
            #expect(result.text == clean)
            #expect(result.decodedRecordCount < number + 1)
            #expect(result.text.entries.map(\.id) == clean.entries.map(\.id))
        }
    }

    @Test func aPartialFinalRecordIsReparsedWithoutMissingOrDuplicatingText() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("rollout.jsonl")
        let complete = line("First") + "\n"
        let partial = line("Second 中文 🧪")
        let cut = partial.utf8.index(partial.utf8.endIndex, offsetBy: -5)
        try (Data(complete.utf8) + Data(partial.utf8[..<cut])).write(to: file)
        let conversation = Conversation.fixture(provider: .codex, sourceFile: file)
        let first = try await SessionMessageTextReader.readResult(conversation)
        #expect(first.text.entries.flatMap(\.segments) == ["First"])

        try append(Data(partial.utf8[cut...]) + Data("\n".utf8), to: file)
        let updated = try await SessionMessageTextReader.readResult(
            conversation, resuming: (first.text, try #require(first.state))
        )

        let clean = try await fullText(conversation)
        #expect(updated.text == clean)
        #expect(updated.text.entries.flatMap(\.segments) == ["First", "Second 中文 🧪"])
    }

    @Test func aValidFinalRecordWithoutANewlineIsSearchableAndReparsedOnAppend() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("rollout.jsonl")
        try line("No newline").write(to: file, atomically: true, encoding: .utf8)
        let conversation = Conversation.fixture(provider: .codex, sourceFile: file)
        let first = try await SessionMessageTextReader.readResult(conversation)
        #expect(first.text.entries.flatMap(\.segments) == ["No newline"])

        try append(Data(("\n" + line("After it") + "\n").utf8), to: file)
        let updated = try await SessionMessageTextReader.readResult(
            conversation, resuming: (first.text, try #require(first.state))
        )
        let clean = try await fullText(conversation)
        #expect(updated.text == clean)
        #expect(updated.text.entries.flatMap(\.segments) == ["No newline", "After it"])
    }

    @Test func anAmendedEarlierRecordForcesAFullRebuildEvenWhenTheFileAlsoGrows() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("rollout.jsonl")
        try ([line("Original"), line("Before")].joined(separator: "\n") + "\n").write(to: file, atomically: true, encoding: .utf8)
        let conversation = Conversation.fixture(provider: .codex, sourceFile: file)
        let first = try await SessionMessageTextReader.readResult(conversation)

        try ([line("Amended!"), line("Before"), line("After")].joined(separator: "\n") + "\n").write(
            to: file, atomically: false, encoding: .utf8
        )
        let updated = try await SessionMessageTextReader.readResult(
            conversation, resuming: (first.text, try #require(first.state))
        )

        let clean = try await fullText(conversation)
        #expect(updated.text == clean)
        #expect(updated.text.entries.flatMap(\.segments) == ["Amended!", "Before", "After"])
        #expect(updated.decodedRecordCount == 3)
    }

    @Test func cacheRejectsRewritesReplacementsAndOtherProviderSemantics() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = SessionMessageTextCache(directory: directory.appendingPathComponent("Cache"))
        let file = directory.appendingPathComponent("rollout.jsonl")
        try (line("Original") + "\n").write(to: file, atomically: true, encoding: .utf8)
        let conversation = Conversation.fixture(provider: .codex, sourceFile: file)
        let result = try await SessionMessageTextReader.readResult(conversation)
        cache.save(
            result.text, state: result.state, provider: .codex,
            for: conversation.id, fingerprint: SessionMessageTextFingerprint(conversation)
        )

        try (line("Replaced") + "\n").write(to: file, atomically: true, encoding: .utf8)
        if case .missing = cache.lookup(for: conversation, fingerprint: SessionMessageTextFingerprint(conversation)) {} else {
            Issue.record("A same-size replacement must not reuse append state")
        }
        let pi = Conversation.fixture(provider: .pi, sessionID: conversation.sessionID, sourceFile: file)
        if case .missing = cache.lookup(for: pi, fingerprint: SessionMessageTextFingerprint(pi)) {} else {
            Issue.record("Pi branch selection has no append-reuse proof")
        }
    }

    @Test func simultaneousSavesAlwaysLeaveOneCompletePayload() async throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = SessionMessageTextCache(directory: directory.appendingPathComponent("Cache"))
        let file = directory.appendingPathComponent("rollout.jsonl")
        try (line("Source") + "\n").write(to: file, atomically: true, encoding: .utf8)
        let conversation = Conversation.fixture(provider: .codex, sourceFile: file)
        let fingerprint = SessionMessageTextFingerprint(conversation)
        let choices = (0..<12).map { SessionMessageText(entries: [.init(id: $0, segments: ["Choice \($0)"])]) }

        await withTaskGroup(of: Void.self) { group in
            for text in choices {
                group.addTask { _ = cache.save(text, for: conversation.id, fingerprint: fingerprint) }
            }
        }

        let saved = try #require(cache.text(for: conversation.id, fingerprint: fingerprint))
        #expect(choices.contains(saved))
    }
}
