import Foundation
import SQLite3

/// Reads `AntigravityTurnState` from a conversation database while its CLI writes it. Two small queries on indexed
/// columns, so each sync reads it afresh.
///
/// Neither number below is documented. Both were observed in Antigravity CLI 1.3.3. In eight earlier conversations
/// with turns, on the Mac they were checked on, the last execution ended at the last step in all but one, which an
/// earlier CLI had left in the middle of a turn.
enum AntigravityTurnStateReader {
    /// The `executor_metadata` field that holds the index of the execution's last step. Protobuf leaves out a zero,
    /// so an execution that ended at the first step has none.
    static let lastStepIndexField: UInt64 = 3
    /// The `steps.status` of a step that waits for you to allow it; Antigravity sets it to 3, done, once you answer.
    static let waitingForApprovalStatus: Int32 = 9

    /// Nil when the database cannot be read, such as one without `executor_metadata`.
    static func turnState(ofConversationDatabase file: URL) -> AntigravityTurnState? {
        guard let database = try? AntigravityDatabase.open(file) else { return nil }
        defer { sqlite3_close(database) }
        guard let lastEndedStepIndex = lastEndedStepIndex(in: database) else { return nil }
        return turnState(after: lastEndedStepIndex, in: database)
    }

    /// The index of the last ended execution's last step; -1 before any execution ends.
    private static func lastEndedStepIndex(in database: OpaquePointer) -> Int64? {
        var statement: OpaquePointer?
        let query = "SELECT data FROM executor_metadata ORDER BY idx DESC LIMIT 1"
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK, let statement else { return nil }
        defer { sqlite3_finalize(statement) }
        switch sqlite3_step(statement) {
        case SQLITE_DONE:
            return -1
        case SQLITE_ROW:
            guard let metadata = AntigravityDatabase.blob(statement, column: 0) else { return 0 }
            return Int64(clamping: AntigravityProtobuf.integer(in: metadata, field: lastStepIndexField) ?? 0)
        default:
            return nil
        }
    }

    private static func turnState(after lastEndedStepIndex: Int64, in database: OpaquePointer) -> AntigravityTurnState? {
        var statement: OpaquePointer?
        let query = """
            SELECT step_payload, EXISTS (SELECT 1 FROM steps WHERE idx > ?1 AND status = \(waitingForApprovalStatus))
            FROM steps WHERE idx > ?1 ORDER BY idx LIMIT 1
            """
        guard sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK, let statement else { return nil }
        defer { sqlite3_finalize(statement) }
        sqlite3_bind_int64(statement, 1, lastEndedStepIndex)
        switch sqlite3_step(statement) {
        case SQLITE_DONE:
            return .betweenTurns
        case SQLITE_ROW:
            return .inTurn(
                startedAt: AntigravityDatabase.blob(statement, column: 0).flatMap(AntigravityTranscriptTimestamp.date(in:)),
                isWaitingForApproval: sqlite3_column_int(statement, 1) != 0
            )
        default:
            return nil
        }
    }
}
