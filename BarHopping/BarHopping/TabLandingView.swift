import SwiftUI

struct TabLandingView: View {
    let tab: AppTab

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label(tab.emptyStateTitle, systemImage: tab.systemImage)
            } description: {
                Text(tab.emptyStateDescription)
            }
            .navigationTitle(tab.title)
        }
    }
}
