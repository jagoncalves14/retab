import AppKit

/// User-facing settings persisted in UserDefaults.
enum Preferences {
    private static let isPausedKey = "isPaused"
    private static let defaultBrowserKey = "defaultBrowserBundleIdentifier"
    private static let hasRequestedDefaultBrowserKey = "hasRequestedDefaultBrowser"

    /// True once Retab has asked macOS, unprompted, to become the default browser.
    /// Retab asks by itself only on first launch; after that the menu offers the fix.
    static var hasRequestedDefaultBrowser: Bool {
        get { UserDefaults.standard.bool(forKey: hasRequestedDefaultBrowserKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasRequestedDefaultBrowserKey) }
    }

    /// When paused, every link opens in a new tab and Retab doesn't read open tabs.
    static var isPaused: Bool {
        get { UserDefaults.standard.bool(forKey: isPausedKey) }
        set { UserDefaults.standard.set(newValue, forKey: isPausedKey) }
    }

    /// The user's default browser: the one that was the default before Retab took over.
    /// Retab remembers it whenever it isn't the default itself, including just before taking over.
    static var defaultBrowserBundleIdentifier: String? {
        get { UserDefaults.standard.string(forKey: defaultBrowserKey) }
        set { UserDefaults.standard.set(newValue, forKey: defaultBrowserKey) }
    }

    /// Where links open: the remembered default browser if it's still installed,
    /// otherwise the first installed supported browser (Chrome first). Never Retab itself,
    /// which would send the link straight back to Retab.
    static var defaultBrowserApplicationURL: URL? {
        if let identifier = defaultBrowserBundleIdentifier,
           identifier != Bundle.main.bundleIdentifier,
           let applicationURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) {
            return applicationURL
        }
        return Browser.installed.first?.applicationURL
    }

    /// The default browser, if Retab can read its tabs. Nil for browsers it can't script,
    /// such as Firefox: links still open there, always in a new tab.
    static var scriptableDefaultBrowser: Browser? {
        guard let applicationURL = defaultBrowserApplicationURL,
              let identifier = Bundle(url: applicationURL)?.bundleIdentifier else {
            return nil
        }
        return Browser.withBundleIdentifier(identifier)
    }
}
