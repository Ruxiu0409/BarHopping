import SwiftUI
import UIKit

extension View {
    /// 點擊輸入框以外的任何地方就收起鍵盤。在根畫面掛一次即可，sheet 也適用。
    func dismissesKeyboardOnOutsideTap() -> some View {
        background(KeyboardDismissInstaller())
    }
}

/// 隱形的 UIView，進入視窗後在整個 window 上裝一個點擊手勢。
private struct KeyboardDismissInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> InstallerView {
        let view = InstallerView()
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: InstallerView, context: Context) {}

    final class InstallerView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window,
                  !(window.gestureRecognizers ?? []).contains(where: { $0 is KeyboardDismissTapRecognizer })
            else { return }
            window.addGestureRecognizer(KeyboardDismissTapRecognizer())
        }
    }
}

/// 不攔截點擊：按鈕、捲動、地圖手勢照常運作，只是順便收起鍵盤。
private final class KeyboardDismissTapRecognizer: UITapGestureRecognizer, UIGestureRecognizerDelegate {
    init() {
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(handleTap))
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        delegate = self
    }

    @objc private func handleTap() {
        view?.endEditing(true)
    }

    /// 點在輸入框裡（移動游標、選字）時不收起鍵盤。
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var current = touch.view
        while let view = current {
            if view is UITextInput { return false }
            current = view.superview
        }
        return true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
