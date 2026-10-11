import SwiftUI

/// Asks `ssh`'s questions during Connect… in a sheet of the view that owns it, one at a time; see
/// `SSHLoginQuestionSheet`. `ssh` waits for each answer before it asks the next question.
@MainActor
final class SSHLoginPrompter: ObservableObject {
    @Published private(set) var question: SSHAskpassQuestion?
    private var continuation: CheckedContinuation<String?, Never>?

    /// The answer, or nil when it was cancelled. A question whose task is cancelled, as when `ssh` ends a notice,
    /// leaves the sheet.
    nonisolated func ask(_ question: SSHAskpassQuestion) async -> String? {
        await withTaskCancellationHandler {
            await show(question)
        } onCancel: {
            Task { @MainActor in self.withdraw(question.id) }
        }
    }

    /// Nil cancels the question shown.
    func answer(_ answer: String?) {
        let continuation = continuation
        self.continuation = nil
        question = nil
        continuation?.resume(returning: answer)
    }

    private func show(_ question: SSHAskpassQuestion) async -> String? {
        guard !Task.isCancelled else { return nil }
        answer(nil)
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.question = question
        }
    }

    private func withdraw(_ questionID: UUID) {
        guard question?.id == questionID else { return }
        answer(nil)
    }
}

extension View {
    /// Shows the questions `prompter` asks; closing the sheet cancels the question.
    func sshLoginQuestions(from prompter: SSHLoginPrompter) -> some View {
        modifier(SSHLoginQuestionPresenter(prompter: prompter))
    }
}

private struct SSHLoginQuestionPresenter: ViewModifier {
    @ObservedObject var prompter: SSHLoginPrompter

    func body(content: Content) -> some View {
        let question = Binding(
            get: { prompter.question },
            set: { if $0 == nil { prompter.answer(nil) } }
        )
        content
            .sheet(item: question) { question in
                SSHLoginQuestionSheet(question: question, onAnswer: prompter.answer)
                    .appLanguage(from: .shared)
            }
            .dismissesOnClickOutside(item: question)
    }
}
