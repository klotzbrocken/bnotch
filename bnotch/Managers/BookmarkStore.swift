import Foundation
import Combine

class BookmarkStore: ObservableObject {
    @Published var bookmarks: [Bookmark] = []
    @Published var groups: [BookmarkGroup] = []

    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("bnotch", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.fileURL = appDir.appendingPathComponent("bookmarks.json")
        load()
    }

    /// Total number of top-level entries (ungrouped bookmarks + groups)
    var totalEntryCount: Int {
        ungroupedBookmarks.count + groups.count
    }

    func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(BookmarkData.self, from: data)
            self.bookmarks = decoded.bookmarks
            self.groups = decoded.groups
        } catch {
            print("Failed to load bookmarks: \(error)")
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(BookmarkData(bookmarks: bookmarks, groups: groups))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save bookmarks: \(error)")
        }
    }

    // MARK: - Bookmark CRUD

    func addBookmark(_ bookmark: Bookmark) {
        let groupBookmarks = bookmarks.filter { $0.groupID == bookmark.groupID }
        var bm = bookmark
        bm.sortOrder = (groupBookmarks.map(\.sortOrder).max() ?? -1) + 1
        bookmarks.append(bm)
        save()
    }

    func updateBookmark(_ bookmark: Bookmark) {
        if let idx = bookmarks.firstIndex(where: { $0.id == bookmark.id }) {
            bookmarks[idx] = bookmark
            save()
        }
    }

    func deleteBookmark(_ id: UUID) {
        bookmarks.removeAll { $0.id == id }
        save()
    }

    func bookmarks(forGroup groupID: UUID?) -> [Bookmark] {
        bookmarks.filter { $0.groupID == groupID }.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Group CRUD

    func addGroup(_ name: String) {
        let order = (groups.map(\.sortOrder).max() ?? -1) + 1
        groups.append(BookmarkGroup(name: name, sortOrder: order))
        save()
    }

    func updateGroup(_ group: BookmarkGroup) {
        if let idx = groups.firstIndex(where: { $0.id == group.id }) {
            groups[idx] = group
            save()
        }
    }

    func deleteGroup(_ id: UUID) {
        bookmarks.removeAll { $0.groupID == id }
        groups.removeAll { $0.id == id }
        save()
    }

    func toggleGroupExpanded(_ id: UUID) {
        if let idx = groups.firstIndex(where: { $0.id == id }) {
            groups[idx].isExpanded.toggle()
            save()
        }
    }

    var sortedGroups: [BookmarkGroup] {
        groups.sorted { $0.sortOrder < $1.sortOrder }
    }

    var ungroupedBookmarks: [Bookmark] {
        bookmarks(forGroup: nil)
    }
}
