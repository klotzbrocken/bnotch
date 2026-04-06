import SwiftUI

/// Notch shape with inward-curving top corners (like the real MacBook notch)
/// and rounded bottom corners. Uses quadratic Bézier curves like boring.notch.
struct NotchShape: Shape {
    var topCornerRadius: CGFloat = 6
    var bottomCornerRadius: CGFloat = 14

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topCornerRadius, bottomCornerRadius) }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let top = rect.minY
        let bottom = rect.maxY
        let left = rect.minX
        let right = rect.maxX
        let tr = topCornerRadius
        let br = bottomCornerRadius

        // Start top-left
        path.move(to: CGPoint(x: left, y: top))

        // Top-left inward curve (quad bézier)
        path.addQuadCurve(
            to: CGPoint(x: left + tr, y: top + tr),
            control: CGPoint(x: left + tr, y: top)
        )

        // Left edge down
        path.addLine(to: CGPoint(x: left + tr, y: bottom - br))

        // Bottom-left corner (quad bézier)
        path.addQuadCurve(
            to: CGPoint(x: left + tr + br, y: bottom),
            control: CGPoint(x: left + tr, y: bottom)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: right - tr - br, y: bottom))

        // Bottom-right corner (quad bézier)
        path.addQuadCurve(
            to: CGPoint(x: right - tr, y: bottom - br),
            control: CGPoint(x: right - tr, y: bottom)
        )

        // Right edge up
        path.addLine(to: CGPoint(x: right - tr, y: top + tr))

        // Top-right inward curve (quad bézier)
        path.addQuadCurve(
            to: CGPoint(x: right, y: top),
            control: CGPoint(x: right - tr, y: top)
        )

        path.closeSubpath()
        return path
    }
}
