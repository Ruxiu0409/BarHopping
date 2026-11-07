import CoreText
import SwiftUI
import UIKit

extension Font {
    @MainActor
    static func onboardingHello(size: CGFloat) -> Font {
        if let name = onboardingHandwritingName, UIFont(name: name, size: size) != nil {
            return .custom(name, fixedSize: size)
        }
        return .system(size: size, weight: .light, design: .rounded)
    }

    @MainActor
    private static let onboardingHandwritingName: String? = {
        guard let url = Bundle.main.url(forResource: "MacintoshSkeletalFilled", withExtension: "otf") else {
            return nil
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        let name = "MacintoshSkeletalFilled-Regular"
        return UIFont(name: name, size: 48) == nil ? nil : name
    }()
}
