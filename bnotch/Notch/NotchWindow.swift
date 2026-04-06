import AppKit

class NotchWindow: NSPanel {
    init(contentView: NSView) {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow],
            backing: .buffered,
            defer: false
        )

        self.isFloatingPanel = true
        self.isOpaque = false
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.backgroundColor = .clear
        self.isMovable = false
        self.isMovableByWindowBackground = false
        self.level = .mainMenu + 3  // Must be above menu bar for hover to work
        self.hasShadow = false
        self.isReleasedWhenClosed = false
        self.appearance = NSAppearance(named: .darkAqua)
        self.ignoresMouseEvents = false

        self.collectionBehavior = [
            .fullScreenAuxiliary,
            .stationary,
            .canJoinAllSpaces,
            .ignoresCycle,
        ]

        self.contentView = contentView
    }

    /// Resize and reposition centered at the top of the screen
    func updateSize(width: CGFloat, height: CGFloat, animated: Bool = true) {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        let x = screenFrame.origin.x + (screenFrame.width / 2) - width / 2
        let y = screenFrame.origin.y + screenFrame.height - height
        let newFrame = NSRect(x: x, y: y, width: width, height: height)

        if animated {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.3
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self.animator().setFrame(newFrame, display: true)
            }
        } else {
            setFrame(newFrame, display: true)
        }
    }

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return frameRect
    }

    var allowKey = false
    override var canBecomeKey: Bool { allowKey }
    override var canBecomeMain: Bool { false }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .leftMouseDown && allowKey {
            makeKey()
        }
        super.sendEvent(event)
    }
}
