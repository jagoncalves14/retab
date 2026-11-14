import Foundation

enum LinkOutcome: Equatable {
    case focusedExistingTab
    case openedNewTab
    /// Opened a new tab because Retab isn't allowed to read the browser's tabs.
    case openedWithoutAutomation(browserName: String)
    case failed(String)
}

/// Decides what to do with a URL that macOS routed to Retab.
/// Everything happens in the user's default browser: switch to its tab with the same page
/// if there is one, otherwise open the link there in a new tab.
@MainActor
enum LinkRouter {
    static func route(
        _ url: URL,
        browserApplicationURL: URL? = Preferences.defaultBrowserApplicationURL,
        scriptableBrowser: Browser? = Preferences.scriptableDefaultBrowser,
        isPaused: Bool = Preferences.isPaused
    ) -> LinkOutcome {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return .failed("Retab can't open this link")
        }

        // Paused, or a browser Retab can't read (such as Firefox): open a new tab without reading tabs.
        // A browser that isn't running has no tabs to check, and reading it would launch it.
        guard !isPaused, let browser = scriptableBrowser, browser.isRunning else {
            return openNewTab(url, withApplicationAt: browserApplicationURL)
        }

        let tabs: [BrowserTab]
        do {
            tabs = try BrowserController.openTabs(in: browser)
        } catch {
            let outcome = openNewTab(url, withApplicationAt: browserApplicationURL)
            return outcome == .openedNewTab ? .openedWithoutAutomation(browserName: browser.name) : outcome
        }

        if let match = URLMatcher.firstMatch(for: url, in: tabs) {
            do {
                try BrowserController.focus(match, in: browser)
                return .focusedExistingTab
            } catch {
                // Never open a duplicate when the existing tab could not be focused.
                return .failed("Couldn't switch to the open \(browser.name) tab")
            }
        }

        return openNewTab(url, withApplicationAt: browserApplicationURL)
    }

    private static func openNewTab(_ url: URL, withApplicationAt applicationURL: URL?) -> LinkOutcome {
        guard BrowserController.openNewTab(url, withApplicationAt: applicationURL) else {
            return .failed("Retab couldn't find a browser to open this link")
        }
        return .openedNewTab
    }
}

/// Compares URLs the way a user expects: case-insensitive host, trailing slash ignored,
/// fragment ignored, and common tracking parameters ignored. Scheme, path, and the
/// remaining query must match. Matching is only used to find tabs; links that open
/// a new tab are passed to the browser unchanged.
enum URLMatcher {
    /// Query parameters added by marketing and messaging tools. They don't change the page.
    static let trackingParameterNames: Set<String> = [
        "fbclid", "gclid", "dclid", "msclkid", "mc_cid", "mc_eid", "igshid", "yclid", "_hsenc", "_hsmi"
    ]

    static func firstMatch(for url: URL, in tabs: [BrowserTab]) -> BrowserTab? {
        guard let target = normalized(url.absoluteString) else { return nil }
        return tabs.first { normalized($0.url) == target }
    }

    static func normalized(_ string: String) -> String? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard var components = URLComponents(string: trimmed),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return nil
        }
        components.scheme = scheme
        components.host = components.host?.lowercased()
        components.fragment = nil

        if let items = components.queryItems {
            let kept = items.filter { item in
                let name = item.name.lowercased()
                return !name.hasPrefix("utm_") && !trackingParameterNames.contains(name)
            }
            components.queryItems = kept.isEmpty ? nil : kept
        }

        // "https://example.com" and "https://example.com/" are the same page; browsers report the latter.
        var path = components.percentEncodedPath.isEmpty ? "/" : components.percentEncodedPath
        while path.count > 1 && path.hasSuffix("/") {
            path.removeLast()
        }
        components.percentEncodedPath = path
        return components.url?.absoluteString
    }
}
