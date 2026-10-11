import SwiftUI

/// Confirms End session from a session's row. It always asks: Don't ask again in the tab's close dialog is about
/// closing tabs, and this stops the CLI wherever it runs.
///
/// Return ends the session, and Escape cancels, as in the dialog for closing a tab whose CLI cannot keep running.
struct SessionEndConfirmation: ViewModifier {
    @ObservedObject var store: ConversationStore
    @Binding var endingConversation: Conversation?

    func body(content: Content) -> some View {
        content
            .alert("End this CLI session?", isPresented: Binding(isPresenting: $endingConversation), presenting: endingConversation) { conversation in
                Button("End session", role: .destructive) {
                    store.endSession(conversation)
                    endingConversation = nil
                }
                .keyboardShortcut(.defaultAction)
                Button("Cancel", role: .cancel) { endingConversation = nil }
            } message: { conversation in
                if store.endingSessionClosesTab(conversation) {
                    Text("The CLI stops on \(conversation.host.nameInSentence) and its tab closes. You can resume the session later.")
                } else {
                    Text("The CLI stops on \(conversation.host.nameInSentence). You can resume the session later.")
                }
            }
            .dismissesOnClickOutside(item: $endingConversation)
    }
}
