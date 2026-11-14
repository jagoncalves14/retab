import Foundation

enum LinkOutcome: Equatable {
    case focusedExistingTab
    case openedNewTab
    case openedWithoutAutomation
    case failed(String)
}

/// Decides what to do with a URL that macOS routed to Retab.
/// Focus an existing identical Chrome tab if one exists; otherwise open a new tab.
@MainActor
enum LinkRouter {
    static func route(_ url: URL) -> LinkOutcome {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return .failed("Unsupported link")
        }

        var tabs: [ChromeTab] = []
        var automationAllowed = true

        if ChromeController.isRunning {
            do {
                tabs = try ChromeController.openTabs()
            } catch {
                automationAllowed = false
            }
        }

        if let match = URLMatcher.firstMatch(for: url, in: tabs) {
            do {
                try ChromeController.focus(match)
                return .focusedExistingTab
            } catch {
                // Never open a duplicate when the existing tab could not be focused.
                return .failed("Could not focus the open Chrome tab")
            }
        }

        guard ChromeController.openNewTab(url) else {
            return .failed("Google Chrome is not installed")
        }
        return automationAllowed ? .openedNewTab : .openedWithoutAutomation
    }
}

/// Compares URLs the way a user expects: case-insensitive host, trailing slash ignored,
/// fragment ignored, and common tracking parameters ignored. Scheme, path, and the
/// remaining query must match. Matching is only used to find tabs; links that open
/// a new tab are passed to Chrome unchanged.
enum URLMatcher {
    /// Query parameters added by marketing and messaging tools. They don't change the page.
    static let trackingParameterNames: Set<String> = [
        "fbclid", "gclid", "dclid", "msclkid", "mc_cid", "mc_eid", "igshid", "yclid", "_hsenc", "_hsmi"
    ]

    static func firstMatch(for url: URL, in tabs: [ChromeTab]) -> ChromeTab? {
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

        // "https://example.com" and "https://example.com/" are the same page; Chrome reports the latter.
        var path = components.percentEncodedPath.isEmpty ? "/" : components.percentEncodedPath
        while path.count > 1 && path.hasSuffix("/") {
            path.removeLast()
        }
        components.percentEncodedPath = path
        return components.url?.absoluteString
    }
}
