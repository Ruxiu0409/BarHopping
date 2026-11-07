import SwiftUI

struct FreeRunMapContainer: View {
    let store: FreeRunStore

    var body: some View {
        FreeRunMapView(session: store.session, friends: store.friends,
                       heatmap: store.heatmap, heading: store.heading,
                       attributions: store.mapAttributions)
    }
}
