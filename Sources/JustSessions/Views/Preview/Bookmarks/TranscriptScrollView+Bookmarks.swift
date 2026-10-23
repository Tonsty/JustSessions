import AppKit
import SwiftUI

/// Bookmarks in one reader: what ⌘D, ⌘', ⇧⌘', the reading toolbar's bookmark menu, and a message's right-click menu do.
/// The bookmarks are the session's (`ConversationStore.messageBookmarks`); the reader keeps only where its last jump went
/// (`TranscriptScrollPositionController.seekTarget`) and a jump whose page is loading (`TranscriptBookmarkState`).
extension TranscriptScrollView {
    /// Every reader in the app pages its transcript, so a position ID is the paged entry ID a bookmark keeps.
    var bookmarksAreEnabled: Bool { store != nil && paging != nil }

    var bookmarks: [MessageBookmark] { store?.messageBookmarks.bookmarks(forConversationID: conversation.id) ?? [] }

    var bookmarkCommandTarget: TranscriptBookmarkCommandTarget? {
        guard bookmarksAreEnabled else { return nil }
        return TranscriptBookmarkCommandTarget(toggleBookmark: toggleBookmarkOnMessageBeingRead,
                                               goToAdjacentBookmark: goToAdjacentBookmark(forward:),
                                               contextMenuItems: bookmarkMenuItems(forEntryAt:))
    }

    var bookmarkMenu: TranscriptBookmarkMenu? {
        guard bookmarksAreEnabled else { return nil }
        return TranscriptBookmarkMenu(bookmarks: bookmarks, assistantName: conversation.provider.rawValue,
                                      onGoTo: goToBookmark, onGoToAdjacent: goToAdjacentBookmark(forward:),
                                      onToggle: toggleBookmarkOnMessageBeingRead, onRemoveAll: removeAllBookmarks)
    }

    var messageBeingRead: TranscriptEntry? {
        MessageBookmarkNavigation.messageBeingRead(
            in: transcript.entries,
            visibleEntryIDs: positionController.visibleEntryIDs(minimumVisibleHeight: MessageBookmarkNavigation.minimumVisibleHeight),
            seekTarget: positionController.seekTarget)
    }

    func toggleBookmarkOnMessageBeingRead() {
        // Until a jump's page arrives, the message on screen is one the reader is leaving.
        guard bookmarksAreEnabled, bookmarkState.loadingJump == nil, bookmarkState.loadingEntryJump == nil else { return }
        guard let entry = messageBeingRead else { bookmarkState.show(.nothingToBookmark); return }
        toggleBookmark(on: entry)
    }

    func toggleBookmark(on entry: TranscriptEntry) {
        switch store?.toggleMessageBookmark(on: entry, in: conversation) {
        case .allLettersInUse: bookmarkState.show(.allLettersInUse)
        case .added, .removed: bookmarkState.dismissNotice()
        case nil: break
        }
    }

    func goToAdjacentBookmark(forward: Bool) {
        guard bookmarksAreEnabled else { return }
        let bookmarks = bookmarks
        guard !bookmarks.isEmpty else { bookmarkState.show(.noBookmarks); return }
        let origin = bookmarkState.loadingJump?.entryID ?? bookmarkState.loadingEntryJump ?? positionController.seekTarget
            ?? messageBeingRead?.id
            ?? positionController.visibleEntryIDs(minimumVisibleHeight: MessageBookmarkNavigation.minimumVisibleHeight).first
        let target = forward ? MessageBookmarkNavigation.bookmark(after: origin, in: bookmarks)
                             : MessageBookmarkNavigation.bookmark(before: origin, in: bookmarks)
        if let target { goToBookmark(target) }
    }

    func goToBookmark(_ bookmark: MessageBookmark) {
        guard bookmarksAreEnabled, let paging else { return }
        bookmarkState.dismissNotice()
        // A page on its way restores the place it was asked for over this jump, so the jump asks for its own page.
        // `refresh` also re-reads the index, so a file-change refresh it replaces loses nothing.
        guard !paging.isLoading else { loadBookmarkJump(to: bookmark); return }
        switch MessageBookmarkNavigation.locate(bookmark, in: transcript.entries, hasEarlier: paging.hasEarlier, hasLater: paging.hasLater) {
        case .found(let entry):
            positionController.seek(toEntryAt: entry.id)
            refreshBookmark(bookmark, foundAt: entry)
            bookmarkState.announce(AppLocalization.string("Bookmark \(bookmark.letter)"))
        case .missing(let landingEntryID):
            // Pages read before the session grew can't hold a message written since, as one a tab just bookmarked: read the
            // file once more. settleBookmarkJump reports it missing after that read, so this never loops.
            if let last = transcript.entries.last,
               TranscriptPageIdentity.record(for: bookmark.entryID) > TranscriptPageIdentity.record(for: last.id) {
                loadBookmarkJump(to: bookmark)
                return
            }
            positionController.seek(toEntryAt: landingEntryID)
            positionController.setSeekTarget(bookmark.entryID)   // next and previous go on past it
            bookmarkState.show(.missing(bookmark))
        case .notLoaded:
            loadBookmarkJump(to: bookmark)
        }
    }

    /// No restoration is armed here: one waiting for an entry with no frame would outlive a failed load.
    private func loadBookmarkJump(to bookmark: MessageBookmark) {
        guard let paging else { return }
        if searchState.isPresented { searchState.close() }   // a new page would select Find's first match
        bookmarkState.startLoadingJump(bookmark)
        positionController.setSeekTarget(bookmark.entryID)
        paging.refresh(conversation, position: .entry(index: bookmark.entryID, offset: -6))
    }

    /// After `restorePagedPosition(using:)` put the first entry at or after the bookmark's at the top. The page is the jump's
    /// (see `TranscriptBookmarkState.loadingJump`); an empty one is `TranscriptView`'s to handle.
    func settleBookmarkJump() {
        guard let paging, !paging.isLoading, let transcript = paging.transcript, !transcript.entries.isEmpty,
              let bookmark = bookmarkState.finishLoadingJump() else { return }
        switch MessageBookmarkNavigation.locate(bookmark, in: transcript.entries, hasEarlier: paging.hasEarlier, hasLater: paging.hasLater) {
        case .found(let entry):
            // Recorded now, before any refresh can run, while the page's restoration keeps recordPosition from overwriting it.
            if entry.id == bookmark.entryID {
                positionController.setSeekTarget(entry.id, recordingPosition: true)
            } else {
                positionController.seek(toEntryAt: entry.id)
            }
            refreshBookmark(bookmark, foundAt: entry)
            bookmarkState.announce(AppLocalization.string("Bookmark \(bookmark.letter)"))
        case .missing, .notLoaded:   // .notLoaded: the page began after its record, which is hidden or gone
            positionController.setSeekTarget(bookmark.entryID, recordingPosition: true)
            bookmarkState.show(.missing(bookmark))
        }
    }

    func forgetBookmarkJump() {
        bookmarkState.cancelLoadingJump()
        positionController.clearSeekTarget()
    }

    func removeBookmark(_ bookmark: MessageBookmark) {
        store?.removeMessageBookmark(bookmark, in: conversation)
        bookmarkState.dismissNotice()
    }

    func removeAllBookmarks() {
        store?.removeAllMessageBookmarks(in: conversation)
        bookmarkState.dismissNotice()
    }

    /// Add bookmark or Remove bookmark for the right-clicked message; see `TranscriptTextView+Bookmarks`.
    func bookmarkMenuItems(forEntryAt entryID: Int) -> [NSMenuItem] {
        guard bookmarksAreEnabled, let entry = transcript.entries.first(where: { $0.id == entryID }),
              MessageBookmark.Kind(entry.content) != nil else { return [] }
        let bookmarks = bookmarks
        if let bookmark = bookmarks.first(where: { $0.entryID == entryID }) {
            return [ActionMenuItem(title: AppLocalization.string("Remove bookmark \(bookmark.letter)"), systemImage: "bookmark.slash") {
                toggleBookmark(on: entry)
            }]
        }
        guard bookmarks.count < MessageBookmarks.letters.count else {
            // The stock menu enables every item that has an action, whatever isEnabled says; these have none.
            let add = NSMenuItem(title: AppLocalization.string("Add bookmark"), action: nil, keyEquivalent: "")
            add.image = NSImage(systemSymbolName: "bookmark", accessibilityDescription: nil)
            return [add, NSMenuItem(title: AppLocalization.string("All 26 letters are in use. Remove a bookmark to add another."), action: nil, keyEquivalent: "")]
        }
        return [ActionMenuItem(title: AppLocalization.string("Add bookmark"), systemImage: "bookmark") { toggleBookmark(on: entry) }]
    }

    /// A moved part, or more of a streamed reply's text, is saved; nothing else writes.
    private func refreshBookmark(_ bookmark: MessageBookmark, foundAt entry: TranscriptEntry) {
        let snippet = MessageBookmarkNavigation.snippet(of: entry) ?? bookmark.snippet
        guard entry.id != bookmark.entryID || snippet.count > bookmark.snippet.count else { return }
        store?.updateMessageBookmark(bookmark, entryID: entry.id, snippet: snippet, in: conversation)
    }
}
