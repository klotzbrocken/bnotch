import AppKit
import SwiftUI

class FaviconFetcher {
    static let shared = FaviconFetcher()

    private var cache: [String: NSImage] = [:]

    func favicon(for urlString: String) -> NSImage? {
        if let cached = cache[urlString] { return cached }
        return nil
    }

    func fetchFavicon(for urlString: String) async -> Data? {
        guard let url = URL(string: urlString),
              let host = url.host else { return nil }

        // Try Google's favicon service
        let faviconURLString = "https://www.google.com/s2/favicons?domain=\(host)&sz=64"
        guard let faviconURL = URL(string: faviconURLString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: faviconURL)
            if let image = NSImage(data: data) {
                image.size = NSSize(width: 20, height: 20)
                cache[urlString] = image
                return data
            }
        } catch {
            print("Favicon fetch failed: \(error)")
        }
        return nil
    }

    func fetchPageTitle(for urlString: String) async -> String? {
        guard let url = URL(string: urlString) else { return nil }

        do {
            var request = URLRequest(url: url, timeoutInterval: 5)
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: request)
            if let html = String(data: data, encoding: .utf8) {
                return extractTitle(from: html)
            }
        } catch {
            print("Title fetch failed: \(error)")
        }
        return nil
    }

    private func extractTitle(from html: String) -> String? {
        guard let startRange = html.range(of: "<title", options: .caseInsensitive),
              let closeTag = html.range(of: ">", range: startRange.upperBound..<html.endIndex),
              let endRange = html.range(of: "</title>", options: .caseInsensitive, range: closeTag.upperBound..<html.endIndex) else {
            return nil
        }
        let title = String(html[closeTag.upperBound..<endRange.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? nil : title
    }

    func image(from data: Data?) -> NSImage? {
        guard let data = data, let img = NSImage(data: data) else { return nil }
        img.size = NSSize(width: 20, height: 20)
        return img
    }
}
