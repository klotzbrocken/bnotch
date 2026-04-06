import Foundation
import Combine

enum ViewMode: String, Codable, CaseIterable {
    case list, icon
}

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var language: AppLanguage {
        didSet { save() }
    }
    @Published var viewMode: ViewMode {
        didSet { save() }
    }

    private let fileURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("bnotch", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        self.fileURL = appDir.appendingPathComponent("settings.json")

        // Defaults
        self.language = .system
        self.viewMode = .list

        load()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode(SettingsData.self, from: data)
            self.language = decoded.language
            self.viewMode = decoded.viewMode
        } catch {
            print("Failed to load settings: \(error)")
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(SettingsData(language: language, viewMode: viewMode))
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
}

private struct SettingsData: Codable {
    let language: AppLanguage
    let viewMode: ViewMode
}
