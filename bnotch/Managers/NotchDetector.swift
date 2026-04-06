import AppKit

struct NotchInfo {
    let width: CGFloat
    let height: CGFloat
    let topY: CGFloat    // top of the notch area (screen.frame.maxY)
    let hasNotch: Bool

    static func fallback(for screen: NSScreen) -> NotchInfo {
        NotchInfo(width: 180, height: 32, topY: screen.frame.maxY, hasNotch: false)
    }
}

class NotchDetector {
    static func detect(for screen: NSScreen? = NSScreen.main) -> NotchInfo {
        guard let screen = screen else {
            return NotchInfo(width: 180, height: 32, topY: 956, hasNotch: false)
        }

        guard let topLeft = screen.auxiliaryTopLeftArea,
              let topRight = screen.auxiliaryTopRightArea else {
            return .fallback(for: screen)
        }

        let notchWidth = topRight.minX - topLeft.maxX
        let notchHeight = topLeft.height
        let topY = screen.frame.maxY

        return NotchInfo(
            width: max(notchWidth, 100),
            height: max(notchHeight, 24),
            topY: topY,
            hasNotch: true
        )
    }
}
