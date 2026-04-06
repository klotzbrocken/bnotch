import SwiftUI

struct NotchContentView: View {
    @ObservedObject var viewModel: NotchViewModel
    @ObservedObject var store: BookmarkStore
    @StateObject private var settings = AppSettings.shared
    @State private var hoverTask: Task<Void, Never>?
    @State private var openedAt: Date = .distantPast

    private var currentShape: NotchShape {
        NotchShape(
            topCornerRadius: viewModel.isOpen ? 19 : 6,
            bottomCornerRadius: viewModel.isOpen ? 24 : 14
        )
    }

    var body: some View {
        ZStack(alignment: .top) {
            currentShape
                .fill(.black)

            if viewModel.isOpen {
                expandedContent
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    .transition(.opacity.animation(.easeOut(duration: 0.2)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onHover { handleHover($0) }
        .onTapGesture {
            if !viewModel.isOpen { viewModel.open() }
        }
    }

    // MARK: - Expanded content

    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                Text("bnotch")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                if !viewModel.showSettings {
                    Button(action: { viewModel.showAddBookmark = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(store.canAddEntry ? .white.opacity(0.8) : .white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .disabled(!store.canAddEntry)

                    Button(action: { viewModel.showAddGroup = true }) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 16))
                            .foregroundColor(store.canAddEntry ? .white.opacity(0.8) : .white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .disabled(!store.canAddEntry)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .background(Color.white.opacity(0.15))

            // Content — fills remaining space between header and bottom bar
            Group {
                if viewModel.showSettings {
                    SettingsView(viewModel: viewModel, settings: settings)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else if viewModel.showAddBookmark {
                    AddBookmarkView(
                        store: store,
                        viewModel: viewModel,
                        groupID: viewModel.selectedGroupID
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else if let bookmark = viewModel.editingBookmark {
                    EditBookmarkView(
                        store: store,
                        viewModel: viewModel,
                        bookmark: bookmark
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                } else if viewModel.showAddGroup {
                    AddGroupView(store: store, viewModel: viewModel)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    switch settings.viewMode {
                    case .list:
                        BookmarkListView(store: store, viewModel: viewModel)
                            .transition(.opacity)
                    case .icon:
                        BookmarkIconView(store: store, viewModel: viewModel)
                            .transition(.opacity)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            // Bottom bar — always pinned at bottom
            bottomBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack {
            // Ko-fi always visible
            Button(action: {
                NSWorkspace.shared.open(URL(string: "https://ko-fi.com/klotzbrocken")!)
            }) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
            .help("Support on Ko-fi")

            Spacer()

            // Right side: context-dependent
            if viewModel.showSettings {
                Button(L10n.ok) {
                    withAnimation { viewModel.showSettings = false }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.blue)
            } else if viewModel.showAddBookmark || viewModel.showAddGroup {
                Button(L10n.cancel) {
                    viewModel.selectedGroupID = nil
                    withAnimation {
                        viewModel.showAddBookmark = false
                        viewModel.showAddGroup = false
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))

                Button(L10n.add) {
                    viewModel.saveRequested = true
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.blue)
                .disabled(!viewModel.canSave)
            } else if viewModel.editingBookmark != nil {
                Button(L10n.cancel) {
                    withAnimation { viewModel.editingBookmark = nil }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))

                Button(L10n.save) {
                    viewModel.saveRequested = true
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(.blue)
            } else {
                // Main view: settings gear
                Button(action: { withAnimation { viewModel.showSettings = true } }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }

    // MARK: - Hover

    private func handleHover(_ hovering: Bool) {
        hoverTask?.cancel()

        if hovering {
            guard viewModel.notchState == .closed else { return }
            hoverTask = Task {
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    viewModel.open()
                    openedAt = Date()
                }
            }
        } else {
            let timeSinceOpen = Date().timeIntervalSince(openedAt)
            if timeSinceOpen < 0.5 { return }

            // Longer delay when a form is open (user might move mouse briefly)
            let hasForm = viewModel.showAddBookmark || viewModel.editingBookmark != nil
                || viewModel.showAddGroup || viewModel.showSettings
            let delay: UInt64 = hasForm ? 800 : 300

            hoverTask = Task {
                try? await Task.sleep(for: .milliseconds(delay))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    if viewModel.notchState == .open {
                        viewModel.close()
                    }
                }
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var viewModel: NotchViewModel
    @ObservedObject var settings: AppSettings

    var body: some View {
        VStack(spacing: 16) {
            Text(L10n.settings)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 12)

            // Language
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.language)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                HStack {
                    Picker("", selection: $settings.language) {
                        ForEach(AppLanguage.allCases, id: \.self) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                    .fixedSize()
                    Spacer()
                }
            }
            .padding(.horizontal, 20)

            // View mode
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.viewMode)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                HStack {
                    Picker("", selection: $settings.viewMode) {
                        Text(L10n.listView).tag(ViewMode.list)
                        Text(L10n.iconView).tag(ViewMode.icon)
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                    .fixedSize()
                    Spacer()
                }
            }
            .padding(.horizontal, 20)

            // About
            VStack(spacing: 4) {
                Text("bnotch")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Text("v1.0")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }
}

// MARK: - Add Group inline view

struct AddGroupView: View {
    @ObservedObject var store: BookmarkStore
    @ObservedObject var viewModel: NotchViewModel
    @State private var name = ""

    var body: some View {
        VStack(spacing: 12) {
            Text(L10n.newGroup)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.top, 12)

            TextField(L10n.groupName, text: $name)
                .textFieldStyle(.plain)
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
        }
        .onChange(of: name) { viewModel.canSave = !$0.isEmpty }
        .onChange(of: viewModel.saveRequested) { requested in
            guard requested else { return }
            viewModel.saveRequested = false
            if !name.isEmpty {
                _ = store.addGroup(name)
                withAnimation { viewModel.showAddGroup = false }
            }
        }
        .onAppear { viewModel.canSave = false }
    }
}
