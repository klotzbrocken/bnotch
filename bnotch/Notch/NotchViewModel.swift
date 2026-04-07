import SwiftUI

enum NotchState {
    case open, closed
}

class NotchViewModel: ObservableObject {
    @Published var notchState: NotchState = .closed
    @Published var notchSize: CGSize
    @Published var showAddBookmark = false
    @Published var editingBookmark: Bookmark? = nil
    @Published var selectedGroupID: UUID? = nil
    @Published var showAddGroup = false
    @Published var showSettings = false
    @Published var saveRequested = false
    @Published var canSave = true

    let closedNotchSize: CGSize
    let openWidth: CGFloat = 380
    let shadowPadding: CGFloat = 20

    var isOpen: Bool { notchState == .open }

    init() {
        let notch = NotchDetector.detect()
        self.closedNotchSize = CGSize(width: notch.width + 4, height: notch.height)
        self.notchSize = CGSize(width: notch.width + 4, height: notch.height)
    }

    let defaultOpenHeight: CGFloat = 288
    let minOpenHeight: CGFloat = 180
    let maxOpenHeight: CGFloat = 600

    var openHeight: CGFloat {
        AppSettings.shared.notchHeight
    }

    var openNotchSize: CGSize {
        CGSize(width: openWidth, height: openHeight)
    }

    func open() {
        notchState = .open
    }

    func close() {
        showAddBookmark = false
        editingBookmark = nil
        showAddGroup = false
        showSettings = false
        saveRequested = false
        canSave = true
        notchState = .closed
    }
}
