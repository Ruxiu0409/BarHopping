import SwiftUI

struct ForumPhotoGallery: View {
    let photos: [ForumPhoto]
    @State private var selection = 0
    @State private var expandedPhoto: ForumPhoto?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TabView(selection: $selection) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    Button {
                        expandedPhoto = photo
                    } label: {
                        Image(photo.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(photo.description)
                    .accessibilityHint("全螢幕檢視照片")
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 280)
            .background(AppTheme.elevated, in: .rect(cornerRadius: 12))
            .clipShape(.rect(cornerRadius: 12))

            HStack {
                Text("情境參考照片")
                Spacer()
                Text("\(selection + 1) / \(photos.count)")
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)

            if photos.indices.contains(selection) {
                Text(photos[selection].credit)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Link("照片來源與授權", destination: photos[selection].sourceURL)
                    .font(.caption)
                    .foregroundStyle(AppTheme.accentOnDark)
            }
        }
        .fullScreenCover(item: $expandedPhoto) { photo in
            ForumPhotoViewer(photos: photos, initialPhoto: photo)
        }
    }
}
