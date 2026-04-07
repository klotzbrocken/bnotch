import SwiftUI

struct BookmarkListView: View {
    @ObservedObject var store: BookmarkStore
    @ObservedObject var viewModel: NotchViewModel
    @State private var selectedPile: UUID? = nil

    /// Bookmarks to display based on selected pile
    private var displayedBookmarks: [Bookmark] {
        if let pileID = selectedPile {
            return store.bookmarks(forGroup: pileID)
        } else {
            return store.ungroupedBookmarks
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Pile tabs (only if groups exist)
            if !store.sortedGroups.isEmpty {
                pileTabBar
            }

            // Bookmark list
            FadingScrollView {
                VStack(spacing: 2) {
                    ForEach(displayedBookmarks) { bookmark in
                        BookmarkRowView(
                            bookmark: bookmark,
                            onOpen: { BrowserDetector.shared.openURL(bookmark.url, withBrowser: bookmark.browserBundleID, mode: bookmark.openMode) },
                            onClose: { viewModel.close() },
                            onEdit: { withAnimation { viewModel.editingBookmark = bookmark } },
                            onDelete: { withAnimation { store.deleteBookmark(bookmark.id) } }
                        )
                    }

                    if displayedBookmarks.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: selectedPile != nil ? "folder" : "bookmark")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.3))
                            Text(L10n.noBookmarks)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                            if selectedPile == nil {
                                Text(L10n.clickToAdd)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Pile Tab Bar

    private var pileTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // "All" tab for ungrouped bookmarks
                PileTab(
                    title: L10n.bookmarks,
                    count: store.ungroupedBookmarks.count,
                    isSelected: selectedPile == nil,
                    onTap: { withAnimation(.easeInOut(duration: 0.15)) { selectedPile = nil } }
                )

                ForEach(store.sortedGroups) { group in
                    PileTab(
                        title: group.name,
                        count: store.bookmarks(forGroup: group.id).count,
                        isSelected: selectedPile == group.id,
                        onTap: { withAnimation(.easeInOut(duration: 0.15)) { selectedPile = group.id } }
                    )
                    .contextMenu {
                        Button(L10n.addBookmarkHere) {
                            viewModel.selectedGroupID = group.id
                            withAnimation { viewModel.showAddBookmark = true }
                        }
                        Divider()
                        Button(L10n.deleteGroup, role: .destructive) {
                            if selectedPile == group.id { selectedPile = nil }
                            withAnimation { store.deleteGroup(group.id) }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 6)
        }
    }
}

// MARK: - Pile Tab

struct PileTab: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .lineLimit(1)
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .white.opacity(0.4))
                }
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.4) : (isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.05)))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - Group Section View (kept for compatibility but no longer used in list)

struct GroupSectionView: View {
    let group: BookmarkGroup
    @ObservedObject var store: BookmarkStore
    @ObservedObject var viewModel: NotchViewModel
    @State private var isHovered = false

    var groupBookmarks: [Bookmark] {
        store.bookmarks(forGroup: group.id)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: group.isExpanded ? "folder.fill" : "folder")
                    .font(.system(size: 16))
                    .foregroundColor(group.isExpanded ? .blue : .white.opacity(0.7))

                Text(group.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(group.isExpanded ? .white : .white.opacity(0.7))
                    .lineLimit(1)

                Text("\(groupBookmarks.count)")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.white.opacity(0.1)))

                Spacer()

                Image(systemName: group.isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.blue.opacity(0.25) : Color.clear)
            )
            .onHover { isHovered = $0 }
            .onTapGesture { withAnimation(.spring(response: 0.3)) { store.toggleGroupExpanded(group.id) } }
            .contextMenu {
                Button(L10n.addBookmarkHere) {
                    viewModel.selectedGroupID = group.id
                    withAnimation { viewModel.showAddBookmark = true }
                }
                Divider()
                Button(L10n.deleteGroup, role: .destructive) {
                    withAnimation { store.deleteGroup(group.id) }
                }
            }

            if group.isExpanded {
                ForEach(groupBookmarks) { bookmark in
                    BookmarkRowView(
                        bookmark: bookmark,
                        onOpen: { BrowserDetector.shared.openURL(bookmark.url, withBrowser: bookmark.browserBundleID, mode: bookmark.openMode) },
                        onClose: { viewModel.close() },
                        onEdit: { withAnimation { viewModel.editingBookmark = bookmark } },
                        onDelete: { withAnimation { store.deleteBookmark(bookmark.id) } }
                    )
                }
            }
        }
    }
}

// MARK: - Fading Scroll View (reusable)

struct FadingScrollView<Content: View>: View {
    @ViewBuilder let content: Content
    @State private var canScrollUp = false
    @State private var canScrollDown = false

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                content
                    .background(
                        GeometryReader { inner in
                            Color.clear.preference(
                                key: ScrollOffsetKey.self,
                                value: inner.frame(in: .named("fadingScroll"))
                            )
                        }
                    )
            }
            .coordinateSpace(name: "fadingScroll")
            .onPreferenceChange(ScrollOffsetKey.self) { frame in
                canScrollUp = frame.minY < -1
                canScrollDown = frame.maxY > frame.height + 1
            }

            VStack {
                if canScrollUp {
                    LinearGradient(
                        colors: [.black, .black.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 16)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
                Spacer()
                if canScrollDown {
                    LinearGradient(
                        colors: [.black.opacity(0), .black],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 16)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: canScrollUp)
            .animation(.easeInOut(duration: 0.2), value: canScrollDown)
        }
    }
}

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
