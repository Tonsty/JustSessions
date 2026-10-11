/// The places a workspace window showed, oldest first, kept as Chrome keeps a tab's history: showing a new place drops
/// the places Forward would have gone to, and Back and Forward move along the list without changing it.
///
/// A place can stop being one the window can show, such as a tab that closed or a session a filter hides. Back and
/// Forward pass over those, and over the place already shown. While the window shows no place, as with several
/// sessions selected, Back goes first to the place it showed last.
struct WorkspaceNavigationHistory: Equatable {
    static let maximumEntryCount = 50

    private(set) var entries: [WorkspaceLocation] = []
    /// The entry the window showed last; nil until it shows one.
    private(set) var currentIndex: Int?

    /// The window came to show `location` other than by Back or Forward.
    mutating func record(_ location: WorkspaceLocation) {
        if let currentIndex, entries[currentIndex] == location { return }
        entries.removeSubrange((currentIndex.map { $0 + 1 } ?? 0)...)
        entries.append(location)
        if entries.count > Self.maximumEntryCount {
            entries.removeFirst(entries.count - Self.maximumEntryCount)
        }
        currentIndex = entries.count - 1
    }

    /// The window moved to `location` while what it showed stays on screen, as between the two panes of a split. The
    /// current entry becomes `location`, so Back still goes to what showed before, and Forward keeps its entries.
    mutating func replaceCurrent(with location: WorkspaceLocation) {
        guard let currentIndex else { return record(location) }
        entries[currentIndex] = location
    }

    /// The entries Back goes to, nearest first: the current entry while another place shows, then the ones before it.
    func backEntryIndices(shown: WorkspaceLocation?, canShow: (WorkspaceLocation) -> Bool) -> [Int] {
        guard let currentIndex else { return [] }
        return stride(from: currentIndex, through: 0, by: -1).filter { isDestination(at: $0, shown: shown, canShow: canShow) }
    }

    /// The entries Forward goes to, nearest first.
    func forwardEntryIndices(shown: WorkspaceLocation?, canShow: (WorkspaceLocation) -> Bool) -> [Int] {
        guard let currentIndex else { return [] }
        return (currentIndex + 1..<entries.count).filter { isDestination(at: $0, shown: shown, canShow: canShow) }
    }

    /// Back or Forward goes to the entry at `index`. Call it before the window shows that entry's place, so recording
    /// the place then changes nothing.
    mutating func move(to index: Int) {
        guard entries.indices.contains(index) else { return }
        currentIndex = index
    }

    private func isDestination(at index: Int, shown: WorkspaceLocation?, canShow: (WorkspaceLocation) -> Bool) -> Bool {
        entries[index] != shown && canShow(entries[index])
    }
}
