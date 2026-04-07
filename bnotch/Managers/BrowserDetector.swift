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

    /// Find an installed browser that supports the requested open mode
    private func fallbackBrowser(for mode: OpenMode) -> (bundleID: String, appURL: URL)? {
        let dict: [String: [String]]
        switch mode {
        case .incognito: dict = incognitoArgs
        case .newWindow: dict = newWindowArgs
        case .tab: return nil
        }
        for browser in browsers {
            if dict[browser.id] != nil || isSafari(browser.id) {
                if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.id) {
                    return (browser.id, appURL)
                }
            }
        }
        return nil
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
            if let bid = effectiveBundleID, let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
                if let args = newWindowArgs[bid] {
                    shellOpen(appPath: appURL.path, args: args, url: urlString)
                } else if isSafari(bid) {
                    appleScriptOpenSafari(url: urlString, mode: .newWindow)
                } else if let fb = fallbackBrowser(for: .newWindow) {
                    // Default browser doesn't support new window — use a browser that does
                    print("[bnotch] \(bid) doesn't support new window, falling back to \(fb.bundleID)")
                    if let args = newWindowArgs[fb.bundleID] {
                        shellOpen(appPath: fb.appURL.path, args: args, url: urlString)
                    } else if isSafari(fb.bundleID) {
                        appleScriptOpenSafari(url: urlString, mode: .newWindow)
                    }
                } else {
                    openURL(urlString, withBrowser: bundleID, mode: .tab)
                }
            } else {
                openURL(urlString, withBrowser: bundleID, mode: .tab)
            }

        case .incognito:
            if let bid = effectiveBundleID, let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
                if let args = incognitoArgs[bid] {
                    shellOpen(appPath: appURL.path, args: args, url: urlString)
                } else if isSafari(bid) {
                    appleScriptOpenSafari(url: urlString, mode: .incognito)
                } else if let fb = fallbackBrowser(for: .incognito) {
                    // Default browser doesn't support incognito — use a browser that does
                    print("[bnotch] \(bid) doesn't support incognito, falling back to \(fb.bundleID)")
                    if let args = incognitoArgs[fb.bundleID] {
                        shellOpen(appPath: fb.appURL.path, args: args, url: urlString)
                    } else if isSafari(fb.bundleID) {
                        appleScriptOpenSafari(url: urlString, mode: .incognito)
                    }
                } else {
                    openURL(urlString, withBrowser: bundleID, mode: .tab)
                }
            } else {
                openURL(urlString, withBrowser: bundleID, mode: .tab)
            }
        }
    }

    private func isSafari(_ bundleID: String) -> Bool {
        bundleID == "com.apple.Safari" || bundleID == "com.apple.SafariTechnologyPreview"
    }

    /// Launch browser executable directly with args — works on running browsers
    private func shellOpen(appPath: String, args: [String], url: String) {
        guard let bundle = Bundle(path: appPath),
              let execURL = bundle.executableURL else {
            print("[bnotch] shellOpen: no executable in \(appPath)")
            return
        }
        let process = Process()
        process.executableURL = execURL
        process.arguments = args + [url]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        process.qualityOfService = .userInitiated
        do {
            try process.run()
            print("[bnotch] shellOpen: launched \(execURL.lastPathComponent) \(args + [url])")
        } catch {
            print("[bnotch] shellOpen failed: \(error)")
        }
    }

    /// AppleScript for Safari (no CLI support for private/new window)
    private func appleScriptOpenSafari(url: String, mode: OpenMode) {
        let escapedURL = url.replacingOccurrences(of: "\"", with: "\\\"")
        let script: String
        switch mode {
        case .newWindow:
            script = """
            tell application "Safari"
                make new document with properties {URL:"\(escapedURL)"}
                activate
            end tell
            """
        case .incognito:
            // Safari doesn't support programmatic private windows easily
            // Open in a new window as fallback
            script = """
            tell application "Safari"
                make new document with properties {URL:"\(escapedURL)"}
                activate
            end tell
            """
        default:
            return
        }
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
        }
    }
}
