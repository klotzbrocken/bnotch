import SwiftUI

struct EditBookmarkView: View {
    @ObservedObject var store: BookmarkStore
    @ObservedObject var viewModel: NotchViewModel
    var bookmark: Bookmark

    @State private var urlString: String
    @State private var name: String
    @State private var selectedBrowserID: String?
    @State private var selectedGroupID: UUID?
    @State private var selectedOpenMode: OpenMode

    private let browsers = BrowserDetector.shared.browsers

    init(store: BookmarkStore, viewModel: NotchViewModel, bookmark: Bookmark) {
        self.store = store
        self.viewModel = viewModel
        self.bookmark = bookmark
        _urlString = State(initialValue: bookmark.url)
        _name = State(initialValue: bookmark.name)
        _selectedBrowserID = State(initialValue: bookmark.browserBundleID)
        _selectedGroupID = State(initialValue: bookmark.groupID)
        _selectedOpenMode = State(initialValue: bookmark.openMode)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                Text(L10n.editBookmark)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.top, 12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.url)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    TextField("https://...", text: $urlString)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.bookmarkName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    TextField(L10n.bookmarkName, text: $name)
                        .textFieldStyle(.plain)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)

                if !store.groups.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.group)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        HStack {
                            Picker("", selection: $selectedGroupID) {
                                Text(L10n.noGroup).tag(UUID?.none)
                                ForEach(store.sortedGroups) { group in
                                    Text(group.name).tag(UUID?.some(group.id))
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                            .fixedSize()
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.browser)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    HStack {
                        Picker("", selection: $selectedBrowserID) {
                            Text(L10n.defaultBrowser).tag(String?.none)
                            ForEach(browsers) { browser in
                                HStack {
                                    if let icon = browser.icon {
                                        Image(nsImage: icon)
                                    }
                                    Text(browser.name)
                                }
                                .tag(String?.some(browser.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                        .fixedSize()
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)

                // Open mode
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.openModeLabel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                    HStack {
                        Picker("", selection: $selectedOpenMode) {
                            Text(L10n.openInTab).tag(OpenMode.tab)
                            Text(L10n.openInNewWindow).tag(OpenMode.newWindow)
                            Text(L10n.openInIncognito).tag(OpenMode.incognito)
                        }
                        .pickerStyle(.menu)
                        .tint(.white)
                        .fixedSize()
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)

            }
        }
        .onChange(of: viewModel.saveRequested) { requested in
            guard requested else { return }
            viewModel.saveRequested = false
            saveBookmark()
        }
        .onAppear { viewModel.canSave = true }
    }

    private func saveBookmark() {
        var updated = bookmark
        updated.url = urlString
        updated.name = name
        updated.browserBundleID = selectedBrowserID
        updated.groupID = selectedGroupID
        updated.openMode = selectedOpenMode
        store.updateBookmark(updated)

        if updated.url != bookmark.url {
            Task {
                if let data = await FaviconFetcher.shared.fetchFavicon(for: updated.url) {
                    updated.faviconData = data
                    await MainActor.run { store.updateBookmark(updated) }
                }
            }
        }

        withAnimation { viewModel.editingBookmark = nil }
    }
}
