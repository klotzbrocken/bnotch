import SwiftUI

struct BookmarkIconView: View {
    @ObservedObject var store: BookmarkStore
    @ObservedObject var viewModel: NotchViewModel
    @State private var selectedPile: UUID? = nil

    private let columns = [
        GridItem(.adaptive(minimum: 52, maximum: 64), spacing: 10)
    ]

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

            // Icon grid
            FadingScrollView {
                VStack(spacing: 12) {
                    if !displayedBookmarks.isEmpty {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(displayedBookmarks) { bookmark in
                                BookmarkIconItem(
                                    bookmark: bookmark,
                                    onOpen: {
                                        BrowserDetector.shared.openURL(bookmark.url, withBrowser: bookmark.browserBundleID, mode: bookmark.openMode)
                                        viewModel.close()
                                    },
                                    onEdit: { withAnimation { viewModel.editingBookmark = bookmark } },
                                    onDelete: { withAnimation { store.deleteBookmark(bookmark.id) } }
                                )
                            }
                        }
                    }

                    if displayedBookmarks.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: selectedPile != nil ? "folder" : "bookmark")
                                .font(.system(size: 28))
                                .foregroundColor(.white.opacity(0.4))
                            Text(L10n.noBookmarks)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                            if selectedPile == nil {
                                Text(L10n.clickToAdd)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }

    // MARK: - Pile Tab Bar

    private var pileTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
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

// MARK: - Single bookmark icon

struct BookmarkIconItem: View {
    let bookmark: Bookmark
    let onOpen: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    private var label: String {
        bookmark.name.isEmpty ? (URL(string: bookmark.url)?.host ?? bookmark.url) : bookmark.name
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(isHovered ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                .frame(width: 56, height: 56)

            if let data = bookmark.faviconData,
               let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 34, height: 34)
                    .cornerRadius(8)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 26))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .help(label)
        .onHover { isHovered = $0 }
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .onTapGesture { onOpen() }
        .contextMenu {
            Button(L10n.open) { onOpen() }
            Button(L10n.edit) { onEdit() }
            Divider()
            Button(L10n.delete, role: .destructive) { onDelete() }
        }
    }
}
