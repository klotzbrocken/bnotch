import Foundation

enum AppLanguage: String, Codable, CaseIterable {
    case en, de

    var displayName: String {
        switch self {
        case .en: return "English"
        case .de: return "Deutsch"
        }
    }

    static var system: AppLanguage {
        let lang = Locale.preferredLanguages.first ?? "en"
        return lang.hasPrefix("de") ? .de : .en
    }
}

enum L10n {
    // MARK: - General
    static var cancel: String { s("Cancel", "Abbrechen") }
    static var save: String { s("Save", "Speichern") }
    static var add: String { s("Add", "Hinzufügen") }
    static var delete: String { s("Delete", "Löschen") }
    static var edit: String { s("Edit", "Bearbeiten") }
    static var open: String { s("Open", "Öffnen") }

    // MARK: - Bookmarks
    static var addBookmark: String { s("Add Bookmark", "Lesezeichen hinzufügen") }
    static var editBookmark: String { s("Edit Bookmark", "Lesezeichen bearbeiten") }
    static var noBookmarks: String { s("No bookmarks yet", "Noch keine Lesezeichen") }
    static var clickToAdd: String { s("Click + to add one", "Klicke + zum Hinzufügen") }
    static var limitReached: String { s("Limit reached (max 8)", "Limit erreicht (max 8)") }
    static var url: String { "URL" }
    static var nameOptional: String { s("Name (optional)", "Name (optional)") }
    static var autoDetected: String { s("Auto-detected if empty", "Wird automatisch erkannt") }
    static var bookmarkName: String { s("Bookmark name", "Lesezeichen-Name") }

    // MARK: - Groups
    static var addGroup: String { s("Add Group", "Ordner hinzufügen") }
    static var newGroup: String { s("New Group", "Neuer Ordner") }
    static var groupName: String { s("Group name", "Ordnername") }
    static var addBookmarkHere: String { s("Add Bookmark Here", "Lesezeichen hier hinzufügen") }
    static var deleteGroup: String { s("Delete Group", "Ordner löschen") }
    static var noGroup: String { s("No Group", "Kein Ordner") }

    // MARK: - Browser
    static var browser: String { "Browser" }
    static var browserOptional: String { s("Browser (optional)", "Browser (optional)") }
    static var defaultBrowser: String { s("Default Browser", "Standardbrowser") }
    static var group: String { s("Group", "Ordner") }

    // MARK: - Open Mode
    static var openInTab: String { s("Open in Tab", "Im Tab öffnen") }
    static var openInNewWindow: String { s("Open in New Window", "In neuem Fenster öffnen") }
    static var openInIncognito: String { s("Open in Incognito", "Im Inkognito-Modus öffnen") }
    static var openModeLabel: String { s("Open Mode", "Öffnungsmodus") }

    // MARK: - Settings
    static var settings: String { s("Settings", "Einstellungen") }
    static var language: String { s("Language", "Sprache") }
    static var viewMode: String { s("View", "Ansicht") }
    static var listView: String { s("List", "Liste") }
    static var iconView: String { s("Icons", "Icons") }
    static var ok: String { "OK" }
    static var about: String { s("About", "Über") }
    static var checkForUpdates: String { s("Check for Updates", "Nach Updates suchen") }
    static var quit: String { s("Quit bnotch", "bnotch beenden") }
    static var bookmarks: String { s("Bookmarks", "Lesezeichen") }

    // MARK: - Helper
    private static func s(_ en: String, _ de: String) -> String {
        AppSettings.shared.language == .de ? de : en
    }
}
