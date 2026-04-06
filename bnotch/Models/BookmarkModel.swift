import Foundation

enum OpenMode: String, Codable, CaseIterable {
    case tab, newWindow, incognito
}

struct Bookmark: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var url: String
    var browserBundleID: String?
    var faviconData: Data?
    var groupID: UUID?
    var sortOrder: Int
    var openMode: OpenMode

    init(id: UUID = UUID(), name: String = "", url: String, browserBundleID: String? = nil, faviconData: Data? = nil, groupID: UUID? = nil, sortOrder: Int = 0, openMode: OpenMode = .tab) {
        self.id = id
        self.name = name
        self.url = url
        self.browserBundleID = browserBundleID
        self.faviconData = faviconData
        self.groupID = groupID
        self.sortOrder = sortOrder
        self.openMode = openMode
    }
}

struct BookmarkGroup: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var sortOrder: Int
    var isExpanded: Bool

    init(id: UUID = UUID(), name: String, sortOrder: Int = 0, isExpanded: Bool = true) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.isExpanded = isExpanded
    }
}

struct BookmarkData: Codable {
    var bookmarks: [Bookmark]
    var groups: [BookmarkGroup]

    init(bookmarks: [Bookmark] = [], groups: [BookmarkGroup] = []) {
        self.bookmarks = bookmarks
        self.groups = groups
    }
}
