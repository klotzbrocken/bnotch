import SwiftUI
import AppKit
import Combine
import Sparkle

@main
struct bnotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var notchWindow: NotchWindow?
    var statusBarController: StatusBarController?
    let store = BookmarkStore()
    let viewModel = NotchViewModel()
    let updaterManager = UpdaterManager()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupNotchWindow()
        statusBarController = StatusBarController(store: store, viewModel: viewModel, updaterManager: updaterManager)

        // Resize window when notch opens/closes
        viewModel.$notchState.sink { [weak self] state in
            guard let self, let window = self.notchWindow else { return }
            if state == .open {
                let h = AppSettings.shared.notchHeight
                window.updateSize(width: self.viewModel.openWidth, height: h)
                window.allowKey = true
                window.makeKey()
            } else {
                let size = self.viewModel.closedNotchSize
                window.updateSize(width: size.width, height: size.height)
                window.allowKey = false
                window.resignKey()
            }
        }.store(in: &cancellables)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func setupNotchWindow() {
        let content = NotchContentView(viewModel: viewModel, store: store)
        let hostingView = NSHostingView(rootView: content)

        let size = viewModel.closedNotchSize
        hostingView.frame = NSRect(x: 0, y: 0, width: size.width, height: size.height)

        notchWindow = NotchWindow(contentView: hostingView)
        notchWindow?.updateSize(width: size.width, height: size.height, animated: false)
        notchWindow?.orderFrontRegardless()
    }

    @objc private func screenChanged() {
        guard let window = notchWindow else { return }
        if viewModel.isOpen {
            let h = AppSettings.shared.notchHeight
            window.updateSize(width: viewModel.openWidth, height: h, animated: false)
        } else {
            let size = viewModel.closedNotchSize
            window.updateSize(width: size.width, height: size.height, animated: false)
        }
    }
}
