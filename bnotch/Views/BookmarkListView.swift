import SwiftUI

struct BookmarkListView: View {
    @ObservedObject var store: BookmarkStore
    @ObservedObject var viewModel: NotchViewModel

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 2) {
                ForEach(store.ungroupedBookmarks) { bookmark in
                    BookmarkRowView(
                        bookmark: bookmark,
                        onOpen: { BrowserDetector.shared.openURL(bookmark.url, withBrowser: bookmark.browserBundleID, mode: bookmark.openMode) },
                        onClose: { viewModel.close() },
                        onEdit: { withAnimation { viewModel.editingBookmark = bookmark } },
                        onDelete: { withAnimation { store.deleteBookmark(bookmark.id) } }
                    )
                }

                ForEach(store.sortedGroups) { group in
                    GroupSectionView(
                        group: group,
                        store: store,
                        viewModel: viewModel
                    )
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
                    .padding(.top, 40)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

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
            .padding(.horizontal, 20)
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
