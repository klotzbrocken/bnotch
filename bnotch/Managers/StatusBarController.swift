import AppKit
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem
    private var store: BookmarkStore
    private var viewModel: NotchViewModel
    private var updaterManager: UpdaterManager

    init(store: BookmarkStore, viewModel: NotchViewModel, updaterManager: UpdaterManager) {
        self.store = store
        self.viewModel = viewModel
        self.updaterManager = updaterManager

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bookmark.fill", accessibilityDescription: "bnotch")
            button.image?.size = NSSize(width: 16, height: 16)
            button.image?.isTemplate = true
        }

        setupMenu()
    }

    private func setupMenu() {
        let menu = NSMenu()

        let addItem = NSMenuItem(title: L10n.addBookmark, action: #selector(addBookmark), keyEquivalent: "n")
        addItem.target = self
        menu.addItem(addItem)

        let addGroupItem = NSMenuItem(title: L10n.addGroup, action: #selector(addGroup), keyEquivalent: "g")
        addGroupItem.target = self
        menu.addItem(addGroupItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: L10n.settings, action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let updateItem = NSMenuItem(title: L10n.checkForUpdates, action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: L10n.quit, action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func addBookmark() {
        viewModel.open()
        viewModel.showAddBookmark = true
    }

    @objc private func addGroup() {
        viewModel.open()
        viewModel.showAddGroup = true
    }

    @objc private func openSettings() {
        viewModel.open()
        viewModel.showSettings = true
    }

    @objc private func checkForUpdates() {
        updaterManager.checkForUpdates()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
