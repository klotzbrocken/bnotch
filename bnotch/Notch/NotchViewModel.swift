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

    /// Dynamic height based on content count
    func openHeight(for store: BookmarkStore) -> CGFloat {
        let headerHeight: CGFloat = 50   // header + divider
        let rowHeight: CGFloat = 32      // per entry row
        let padding: CGFloat = 30        // top/bottom padding
        let entryCount = store.totalEntryCount
        let minHeight: CGFloat = 140     // empty state
        let maxHeight: CGFloat = 320

        if entryCount == 0 { return minHeight }
        let contentHeight = headerHeight + CGFloat(entryCount) * rowHeight + padding
        return min(max(contentHeight, minHeight), maxHeight)
    }

    var openNotchSize: CGSize {
        CGSize(width: openWidth, height: 300) // fallback, overridden by dynamic calc
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
