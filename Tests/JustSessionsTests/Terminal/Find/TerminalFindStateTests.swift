import Testing
@testable import JustSessions

@MainActor
struct TerminalFindStateTests {
    @Test func typingSearchesOnlyWhileTheBarShows() {
        let finder = RecordingTerminalFinder()
        let findState = TerminalFindState(finder: finder)

        findState.query = "kept"
        #expect(finder.calls.isEmpty)

        findState.show()
        #expect(findState.isPresented)
        #expect(finder.calls == [.find("kept")])
        #expect(findState.matchCount == finder.matchCount)

        findState.query = "kept!"
        #expect(finder.calls.last == .find("kept!"))
    }

    @Test func movesGoToTheFinderInTheirDirection() {
        let finder = RecordingTerminalFinder()
        let findState = TerminalFindState(finder: finder)
        findState.show()
        findState.query = "needle"

        findState.move(.towardOlder)
        findState.move(.towardNewer)

        #expect(finder.calls.suffix(2) == [.findAgain("needle", .towardOlder), .findAgain("needle", .towardNewer)])
    }

    @Test func nothingMovesWithoutAQueryOrABar() {
        let finder = RecordingTerminalFinder()
        let findState = TerminalFindState(finder: finder)
        findState.query = "needle"
        findState.move(.towardOlder)
        findState.show()
        findState.query = ""
        finder.calls.removeAll()

        findState.move(.towardOlder)

        #expect(finder.calls.isEmpty)
    }

    /// Closing ends the engine's search, which takes its highlight away, and keeps the text for the next ⌘F.
    @Test func closingEndsTheSearchAndKeepsTheText() {
        let finder = RecordingTerminalFinder()
        let findState = TerminalFindState(finder: finder)
        findState.show()
        findState.query = "needle"
        findState.isFieldFocused = true

        findState.close()

        #expect(!findState.isPresented)
        #expect(!findState.isFieldFocused)
        #expect(findState.matchCount == nil)
        #expect(findState.closeRevision == 1)
        #expect(finder.calls.last == .end)

        findState.show()
        #expect(finder.calls.last == .find("needle"))
    }

    /// ⌘F while the bar shows puts the keyboard back in its field without searching again.
    @Test func showingAgainOnlyFocusesTheField() {
        let finder = RecordingTerminalFinder()
        let findState = TerminalFindState(finder: finder)
        findState.show()
        findState.query = "needle"
        let callCount = finder.calls.count
        let focusRevision = findState.focusRevision

        findState.show()

        #expect(finder.calls.count == callCount)
        #expect(findState.focusRevision == focusRevision + 1)
    }
}

@MainActor
private final class RecordingTerminalFinder: TerminalTextFinding {
    enum Call: Equatable {
        case find(String)
        case findAgain(String, TerminalFindDirection)
        case end
    }

    var calls: [Call] = []
    let matchCount = TerminalFindMatchCount(total: 3, selectedNumber: 1, exceedsCountLimit: false)

    func findText(_ query: String) -> TerminalFindMatchCount? {
        calls.append(.find(query))
        return matchCount
    }

    func findTextAgain(_ query: String, direction: TerminalFindDirection) -> TerminalFindMatchCount? {
        calls.append(.findAgain(query, direction))
        return matchCount
    }

    func endTextFind() {
        calls.append(.end)
    }
}
