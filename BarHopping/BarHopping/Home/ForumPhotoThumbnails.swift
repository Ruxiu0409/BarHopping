import SwiftUI

struct ForumPhotoThumbnails: View {
    let photos: [ForumPhoto]

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 6) {
                ForEach(Array(photos.prefix(2).enumerated()), id: \.element.id) { index, photo in
                    Image(photo.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: photos.count == 1 ? geometry.size.width : (geometry.size.width - 6) / 2,
                               height: 184)
                        .clipped()
                        .overlay(alignment: .bottomTrailing) {
                            if index == 1 && photos.count > 2 {
                                Text("+\(photos.count - 2)")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.black.opacity(0.7), in: .capsule)
                                    .padding(8)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityLabel(photo.description)
                }
            }
        }
        .frame(height: 184)
        .clipShape(.rect(cornerRadius: 12))
    }
}
