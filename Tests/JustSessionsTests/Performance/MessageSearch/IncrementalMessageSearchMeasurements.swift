import Darwin
import Foundation
import Testing
@testable import JustSessions

/// Measures persisted Codex search-text extraction for cold reads, unchanged cache hits, small appends, and rebuilds,
/// as `Perf | <scenario> | <metric> | <value>` lines. Each configuration runs three times.
///
/// The suite records nothing unless `JUSTSESSIONS_PERF` is set:
///     JUSTSESSIONS_PERF=1 swift test -c release --filter IncrementalMessageSearchMeasurements
@Suite(.serialized)
struct IncrementalMessageSearchMeasurements {
    static let runCount = 3

    @Test(arguments: [10, 100, 500])
    func codexSearchText(sizeMiB: Int) async throws {
        guard SidebarInteractionMeasurements.isEnabled else { return }
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("rollout.jsonl")
        try writeFixture(sizeMiB: sizeMiB, to: file)
        let conversation = Conversation.fixture(provider: .codex, sourceFile: file)
        let scenario = "incremental Codex search text, \(sizeMiB) MiB"

        var cold: [Sample] = []
        var initial: SessionMessageTextReadResult?
        for run in 0..<Self.runCount {
            let cache = SessionMessageTextCache(directory: directory.appendingPathComponent("Cold-\(run)"))
            let measured = try await measure {
                let result = try await SessionMessageTextReader.readResult(conversation)
                let written = cache.save(
                    result.text, state: result.state, provider: .codex,
                    for: conversation.id, fingerprint: SessionMessageTextFingerprint(conversation)
                )
                return (result, written)
            }
            cold.append(measured.sample)
            initial = measured.result
        }
        report(cold, scenario: scenario, operation: "cold extraction")

        let cache = SessionMessageTextCache(directory: directory.appendingPathComponent("Live"))
        var current = try #require(initial)
        _ = cache.save(
            current.text, state: current.state, provider: .codex,
            for: conversation.id, fingerprint: SessionMessageTextFingerprint(conversation)
        )
        var unchanged: [Sample] = []
        for _ in 0..<Self.runCount {
            let measured = try await measure {
                guard case .current(let text) = cache.lookup(
                    for: conversation, fingerprint: SessionMessageTextFingerprint(conversation)
                ) else { throw MeasurementError.cacheMiss }
                return (SessionMessageTextReadResult(
                    text: text, state: nil, sourceByteCountRead: 0, decodedRecordCount: 0
                ), 0)
            }
            unchanged.append(measured.sample)
        }
        report(unchanged, scenario: scenario, operation: "unchanged cache hit")

        var appends: [Sample] = []
        for run in 0..<Self.runCount {
            try append(Data((searchLine("Appended \(run) Café 中文 🧪") + "\n").utf8), to: file)
            let measured = try await measure {
                let fingerprint = SessionMessageTextFingerprint(conversation)
                guard case .reusable(let text, let state) = cache.lookup(for: conversation, fingerprint: fingerprint) else {
                    throw MeasurementError.cacheMiss
                }
                let result = try await SessionMessageTextReader.readResult(conversation, resuming: (text, state))
                let written = cache.save(
                    result.text, state: result.state, provider: .codex,
                    for: conversation.id, fingerprint: fingerprint
                )
                return (result, written)
            }
            current = measured.result
            appends.append(measured.sample)
            try await assertEquivalent(current, toCleanReadOf: conversation)
        }
        report(appends, scenario: scenario, operation: "one-record append")

        var rebuilds: [Sample] = []
        for run in 0..<Self.runCount {
            try amendFirstMarker(in: file, to: run.isMultiple(of: 2) ? UInt8(ascii: "B") : UInt8(ascii: "A"))
            try append(Data((searchLine("Growth after amendment \(run)") + "\n").utf8), to: file)
            let measured = try await measure {
                let fingerprint = SessionMessageTextFingerprint(conversation)
                guard case .reusable(let text, let state) = cache.lookup(for: conversation, fingerprint: fingerprint) else {
                    throw MeasurementError.cacheMiss
                }
                let result = try await SessionMessageTextReader.readResult(conversation, resuming: (text, state))
                let written = cache.save(
                    result.text, state: result.state, provider: .codex,
                    for: conversation.id, fingerprint: fingerprint
                )
                return (result, written)
            }
            current = measured.result
            rebuilds.append(measured.sample)
            try await assertEquivalent(current, toCleanReadOf: conversation)
        }
        report(rebuilds, scenario: scenario, operation: "amendment rebuild")
    }

    private struct Sample {
        let wall: Duration
        let cpu: Duration
        let sourceBytes: UInt64
        let decodedRecords: Int
        let peakRSSBytes: UInt64
        let cacheBytesWritten: Int
    }

    private struct Measured {
        let result: SessionMessageTextReadResult
        let sample: Sample
    }

    private enum MeasurementError: Error { case cacheMiss }

    private func measure(
        _ operation: () async throws -> (SessionMessageTextReadResult, Int)
    ) async throws -> Measured {
        let cpuStart = Self.processCPUTime()
        let wallStart = ContinuousClock.now
        let (result, cacheBytesWritten) = try await operation()
        return Measured(
            result: result,
            sample: Sample(
                wall: ContinuousClock.now - wallStart,
                cpu: Self.processCPUTime() - cpuStart,
                sourceBytes: result.sourceByteCountRead,
                decodedRecords: result.decodedRecordCount,
                peakRSSBytes: Self.peakRSSBytes(),
                cacheBytesWritten: cacheBytesWritten
            )
        )
    }

    private func report(_ samples: [Sample], scenario: String, operation: String) {
        let middle = samples.count / 2
        perfReport(scenario, "\(operation): median wall time", samples.map(\.wall).sorted()[middle])
        perfReport(scenario, "\(operation): median CPU time", samples.map(\.cpu).sorted()[middle])
        perfReport(scenario, "\(operation): median source bytes read", "\(samples.map(\.sourceBytes).sorted()[middle]) bytes")
        perfReport(scenario, "\(operation): median records decoded", "\(samples.map(\.decodedRecords).sorted()[middle])")
        perfReport(scenario, "\(operation): peak RSS", "\(samples.map(\.peakRSSBytes).max()! >> 20) MiB")
        perfReport(scenario, "\(operation): median cache bytes written", "\(samples.map(\.cacheBytesWritten).sorted()[middle]) bytes")
    }

    private func writeFixture(sizeMiB: Int, to file: URL) throws {
        FileManager.default.createFile(atPath: file.path, contents: nil)
        let handle = try FileHandle(forWritingTo: file)
        defer { try? handle.close() }
        let first = searchLine("Marker A: First **Café** 中文 🧪") + "\n"
        try handle.write(contentsOf: Data(first.utf8))
        let padding = String(repeating: "x", count: 3_800)
        let hidden = #"{"timestamp":"2026-10-02T12:00:00.000Z","type":"event_msg","payload":{"type":"token_count","padding":"\#(padding)"}}"# + "\n"
        let visible = searchLine("Searchable checkpoint") + "\n"
        let group = Data((visible + String(repeating: hidden, count: 128)).utf8)
        let target = UInt64(sizeMiB) << 20
        var written = UInt64(first.utf8.count)
        while written < target {
            try handle.write(contentsOf: group)
            written += UInt64(group.count)
        }
    }

    private func searchLine(_ text: String) -> String {
        #"{"timestamp":"2026-10-02T12:00:00.000Z","type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"\#(text)"}]}}"#
    }

    private func append(_ data: Data, to file: URL) throws {
        let handle = try FileHandle(forWritingTo: file)
        defer { try? handle.close() }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
    }

    private func amendFirstMarker(in file: URL, to replacement: UInt8) throws {
        let handle = try FileHandle(forUpdating: file)
        defer { try? handle.close() }
        let head = try handle.read(upToCount: 512) ?? Data()
        let marker = Data("Marker ".utf8)
        guard let range = head.range(of: marker) else { throw MeasurementError.cacheMiss }
        try handle.seek(toOffset: UInt64(range.upperBound))
        try handle.write(contentsOf: Data([replacement]))
    }

    private func assertEquivalent(
        _ result: SessionMessageTextReadResult, toCleanReadOf conversation: Conversation
    ) async throws {
        let clean = try await SessionMessageTextReader.readResult(conversation)
        #expect(result.text == clean.text)
        #expect(result.text.entries.map(\.id) == clean.text.entries.map(\.id))
        let searchable = SearchableSessionText(result.text)
        for query in ["First Café", "first cafe", "中文", "🧪", "Appended"] {
            #expect(searchable.firstMatch(of: try #require(SessionMessageQuery(query)))?.entryID
                == SearchableSessionText(clean.text).firstMatch(of: try #require(SessionMessageQuery(query)))?.entryID)
        }
        #expect(result.text.entries.first?.segments.first == "Marker \(String(UnicodeScalar(amendedMarker(in: conversation.sourceFile)))): First Café 中文 🧪")
    }

    private func amendedMarker(in file: URL) -> UInt8 {
        let data = (try? Data(contentsOf: file, options: .mappedIfSafe).prefix(512)) ?? Data()
        return data.range(of: Data("Marker ".utf8)).map { data[$0.upperBound] } ?? UInt8(ascii: "A")
    }

    private static func processCPUTime() -> Duration {
        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        let microseconds = Int64(usage.ru_utime.tv_sec + usage.ru_stime.tv_sec) * 1_000_000
            + Int64(usage.ru_utime.tv_usec + usage.ru_stime.tv_usec)
        return .microseconds(microseconds)
    }

    private static func peakRSSBytes() -> UInt64 {
        var usage = rusage()
        getrusage(RUSAGE_SELF, &usage)
        return UInt64(usage.ru_maxrss)
    }
}
