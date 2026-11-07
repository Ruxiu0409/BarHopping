import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

struct PassQRCodeView: View {
    let payload: String

    private var qrImage: UIImage? {
        PassQRCodeRenderer.image(for: payload)
    }

    var body: some View {
        VStack(spacing: 10) {
            if let qrImage {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 154, height: 154)
                    .accessibilityLabel("核銷碼 QR Code，內容為 \(payload)")
            } else {
                Text("無法產生 QR Code")
                    .font(.caption)
                    .foregroundStyle(.black)
                    .frame(width: 154, height: 154)
            }

            Text(payload)
                .font(.system(.title3, design: .monospaced, weight: .bold))
                .foregroundStyle(.black)
        }
        .padding(18)
        .background(Color.white, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shadow(color: .black.opacity(0.1), radius: 8)
    }
}

private enum PassQRCodeRenderer {
    private static let context = CIContext()

    static func image(for payload: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "H"

        guard let output = filter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
