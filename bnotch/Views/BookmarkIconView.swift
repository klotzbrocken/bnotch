import SwiftUI

struct BookmarkIconView: View {
    @ObservedObject var store: BookmarkStore
    @ObservedObject var viewModel: NotchViewModel
    @State private var openGroupID: UUID? = nil

    private let columns = [
        GridItem(.adaptive(minimum: 52, maximum: 64), spacing: 10)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Back button when inside a folder
            if let groupID = openGroupID,
               let group = store.groups.first(where: { $0.id == groupID }) {
                HStack(spacing: 6) {
                    Button(action: { withAnimation(.spring(response: 0.3)) { openGroupID = nil } }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .semibold))
                            Text(group.name)
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }

            // Content
            ScrollView(.vertical, showsIndicators: false) {
                if let groupID = openGroupID {
                    // Inside a folder — show folder bookmarks
                    folderContent(groupID: groupID)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    // Home — show ungrouped bookmarks + folders
                    homeContent
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Home (top level)

    private var homeContent: some View {
        VStack(spacing: 12) {
            if !store.ungroupedBookmarks.isEmpty || !store.sortedGroups.isEmpty {
                LazyVGrid(columns: columns, spacing: 12) {
                    // Folders as icons
                    ForEach(store.sortedGroups) { group in
                        FolderIconItem(
                            group: group,
                            store: store,
                            onOpen: { withAnimation(.spring(response: 0.3)) { openGroupID = group.id } },
                            onAddBookmark: {
                                viewModel.selectedGroupID = group.id
                                withAnimation { viewModel.showAddBookmark = true }
                            },
                            onDelete: { withAnimation { store.deleteGroup(group.id) } }
                        )
                    }

                    // Ungrouped bookmarks
                    ForEach(store.ungroupedBookmarks) { bookmark in
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

            if store.bookmarks.isEmpty && store.groups.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.3))
                    Text(L10n.noBookmarks)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    Text(L10n.clickToAdd)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Folder content (second level)

    private func folderContent(groupID: UUID) -> some View {
        let bookmarks = store.bookmarks(forGroup: groupID)

        return VStack(spacing: 12) {
            if bookmarks.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.3))
                    Text(L10n.noBookmarks)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(bookmarks) { bookmark in
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Folder icon (same size as bookmark icons)

struct FolderIconItem: View {
    let group: BookmarkGroup
    @ObservedObject var store: BookmarkStore
    let onOpen: () -> Void
    let onAddBookmark: () -> Void
    let onDelete: () -> Void
    @State private var isHovered = false

    var count: Int {
        store.bookmarks(forGroup: group.id).count
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(isHovered ? Color.blue.opacity(0.3) : Color.white.opacity(0.08))
                .frame(width: 56, height: 56)

            VStack(spacing: 2) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .help(group.name)
        .onHover { isHovered = $0 }
        .onTapGesture { onOpen() }
        .contextMenu {
            Button(L10n.addBookmarkHere) { onAddBookmark() }
            Divider()
            Button(L10n.deleteGroup, role: .destructive) { onDelete() }
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
                .fill(isHovered ? Color.blue.opacity(0.3) : Color.white.opacity(0.08))
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
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .help(label)
        .onHover { isHovered = $0 }
        .onTapGesture { onOpen() }
        .contextMenu {
            Button(L10n.open) { onOpen() }
            Button(L10n.edit) { onEdit() }
            Divider()
            Button(L10n.delete, role: .destructive) { onDelete() }
        }
    }
}
