import AppKit

struct DetectedBrowser: Identifiable, Hashable {
    let id: String // bundle identifier
    let name: String
    let icon: NSImage?
}

class BrowserDetector {
    static let shared = BrowserDetector()

    private(set) var browsers: [DetectedBrowser] = []

    // Known incognito/private CLI arguments per browser
    private let incognitoArgs: [String: [String]] = [
        "com.google.Chrome": ["--incognito"],
        "com.google.Chrome.canary": ["--incognito"],
        "com.brave.Browser": ["--incognito"],
        "com.microsoft.edgemac": ["--inprivate"],
        "org.mozilla.firefox": ["-private-window"],
        "com.operasoftware.Opera": ["--private"],
        "com.vivaldi.Vivaldi": ["--incognito"],
        "company.thebrowser.Browser": ["--incognito"], // Arc
    ]

    private let newWindowArgs: [String: [String]] = [
        "com.google.Chrome": ["--new-window"],
        "com.google.Chrome.canary": ["--new-window"],
        "com.brave.Browser": ["--new-window"],
        "com.microsoft.edgemac": ["--new-window"],
        "com.operasoftware.Opera": ["--new-window"],
        "com.vivaldi.Vivaldi": ["--new-window"],
    ]

    private init() {
        detectBrowsers()
    }

    func detectBrowsers() {
        let httpURL = URL(string: "https://example.com")!
        let bundleIDs = NSWorkspace.shared.urlsForApplications(toOpen: httpURL).compactMap { url -> String? in
            Bundle(url: url)?.bundleIdentifier
        }

        var seen = Set<String>()
        browsers = bundleIDs.compactMap { bundleID in
            guard !seen.contains(bundleID) else { return nil }
            seen.insert(bundleID)
            guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return nil }
            var name = FileManager.default.displayName(atPath: appURL.path)
            if name.hasSuffix(".app") { name = String(name.dropLast(4)) }
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            icon.size = NSSize(width: 16, height: 16)
            return DetectedBrowser(id: bundleID, name: name, icon: icon)
        }.sorted { $0.name < $1.name }
    }

    var defaultBrowser: DetectedBrowser? {
        guard let defaultURL = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://example.com")!),
              let bundleID = Bundle(url: defaultURL)?.bundleIdentifier else { return nil }
        return browsers.first { $0.id == bundleID }
    }

    func browser(for bundleID: String) -> DetectedBrowser? {
        browsers.first { $0.id == bundleID }
    }

    func effectiveBrowser(for bundleID: String?) -> DetectedBrowser? {
        if let bundleID = bundleID {
            return browser(for: bundleID)
        }
        return defaultBrowser
    }

    func openURL(_ urlString: String, withBrowser bundleID: String? = nil, mode: OpenMode = .tab) {
        guard let url = URL(string: urlString) else { return }

        let effectiveBundleID = bundleID ?? defaultBrowser?.id

        switch mode {
        case .tab:
            if let bid = effectiveBundleID,
               let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
                NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration())
            } else {
                NSWorkspace.shared.open(url)
            }

        case .newWindow:
            if let bid = effectiveBundleID,
               let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid),
               let args = newWindowArgs[bid] {
                launchBrowser(appURL: appURL, args: args + [urlString])
            } else {
                // Fallback: just open normally
                openURL(urlString, withBrowser: bundleID, mode: .tab)
            }

        case .incognito:
            if let bid = effectiveBundleID,
               let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid),
               let args = incognitoArgs[bid] {
                launchBrowser(appURL: appURL, args: args + [urlString])
            } else {
                // Fallback: just open normally
                openURL(urlString, withBrowser: bundleID, mode: .tab)
            }
        }
    }

    private func launchBrowser(appURL: URL, args: [String]) {
        let config = NSWorkspace.OpenConfiguration()
        config.arguments = args
        NSWorkspace.shared.openApplication(at: appURL, configuration: config)
    }
}
