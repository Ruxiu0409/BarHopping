import SwiftUI

struct ForumPhotoViewer: View {
    let photos: [ForumPhoto]
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Int

    init(photos: [ForumPhoto], initialPhoto: ForumPhoto) {
        self.photos = photos
        _selection = State(initialValue: photos.firstIndex(of: initialPhoto) ?? 0)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("照片 \(selection + 1) / \(photos.count)")
                    .font(.headline)
                    .monospacedDigit()
                Spacer()
                Button("關閉", systemImage: "xmark") { dismiss() }
                    .labelStyle(.iconOnly)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .padding(.horizontal)

            TabView(selection: $selection) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    Image(photo.imageName)
                        .resizable()
                        .scaledToFit()
                        .accessibilityLabel(photo.description)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            if photos.indices.contains(selection) {
                VStack(spacing: 8) {
                    Text(photos[selection].description)
                        .font(.subheadline)
                    Text(photos[selection].credit)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(.black)
        .foregroundStyle(.white)
        .tint(AppTheme.accentOnDark)
        .preferredColorScheme(.dark)
    }
}
