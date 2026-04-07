import SwiftUI

struct AddBookmarkView: View {
    @ObservedObject var store: BookmarkStore
    @ObservedObject var viewModel: NotchViewModel
    var groupID: UUID?

    @State private var urlString = ""
    @State private var name = ""
    @State private var selectedBrowserID: String? = nil
    @State private var selectedOpenMode: OpenMode = .tab
    @State private var isFetching = false
    @State private var errorMessage: String? = nil

    private let browsers = BrowserDetector.shared.browsers

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
        VStack(spacing: 10) {
            Text(L10n.addBookmark)
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
                    .onSubmit { fetchMetadata() }
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.nameOptional)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                TextField(L10n.autoDetected, text: $name)
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
                        Picker("", selection: Binding(
                            get: { viewModel.selectedGroupID },
                            set: { viewModel.selectedGroupID = $0 }
                        )) {
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
                Text(L10n.browserOptional)
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

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 11))
                    .foregroundColor(.red.opacity(0.8))
                    .padding(.horizontal, 20)
            }

            if isFetching {
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                    Spacer()
                }
            }

        }
        }
        .onChange(of: urlString) { viewModel.canSave = !$0.isEmpty }
        .onChange(of: viewModel.saveRequested) { requested in
            guard requested else { return }
            viewModel.saveRequested = false
            addBookmark()
        }
        .onAppear { viewModel.canSave = false }
    }

    private func fetchMetadata() {
        guard !urlString.isEmpty else { return }
        let normalized = normalizeURL(urlString)
        urlString = normalized
        isFetching = true
        Task {
            if name.isEmpty {
                if let title = await FaviconFetcher.shared.fetchPageTitle(for: normalized) {
                    await MainActor.run { name = title }
                }
            }
            isFetching = false
        }
    }

    private func addBookmark() {
        let normalized = normalizeURL(urlString)
        errorMessage = nil

        let bookmark = Bookmark(
            name: name,
            url: normalized,
            browserBundleID: selectedBrowserID,
            groupID: viewModel.selectedGroupID,
            openMode: selectedOpenMode
        )

        store.addBookmark(bookmark)

        Task {
            if let faviconData = await FaviconFetcher.shared.fetchFavicon(for: normalized) {
                var updated = bookmark
                updated.faviconData = faviconData
                if updated.name.isEmpty {
                    if let title = await FaviconFetcher.shared.fetchPageTitle(for: normalized) {
                        updated.name = title
                    }
                }
                await MainActor.run { store.updateBookmark(updated) }
            }
        }

        viewModel.selectedGroupID = nil
        withAnimation { viewModel.showAddBookmark = false }
    }

    private func normalizeURL(_ input: String) -> String {
        var s = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.hasPrefix("http://") && !s.hasPrefix("https://") {
            s = "https://" + s
        }
        return s
    }
}
