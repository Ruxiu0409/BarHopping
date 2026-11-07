import SwiftUI

struct FreeRunFeedbackOverlay: View {
    let store: FreeRunStore

    var body: some View {
        if let feedback = store.drinkFeedback, feedback.elapsed < FreeRunDemoScript.confettiSeconds {
            FreeRunCelebrationView(elapsed: feedback.elapsed)
                .id(feedback.id)
        }
    }
}
