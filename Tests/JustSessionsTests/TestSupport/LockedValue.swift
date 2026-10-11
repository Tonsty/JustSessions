import Foundation

/// A value that tests change from other threads, such as a fake server's, and read from the test.
final class LockedValue<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValue: Value

    init(_ value: Value) {
        storedValue = value
    }

    var value: Value { lock.withLock { storedValue } }

    func update(_ change: (inout Value) -> Void) {
        lock.withLock { change(&storedValue) }
    }
}
