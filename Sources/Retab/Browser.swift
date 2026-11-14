import AppKit

/// A browser Retab can read and switch tabs in through AppleScript.
struct Browser: Equatable {
    /// How the browser exposes its tabs to AppleScript.
    enum ScriptingFamily {
        /// Chrome and browsers built on Chromium: `active tab index` selects a tab.
        case chromium
        /// Safari: `current tab` selects a tab.
        case safari
    }

    let name: String
    let bundleIdentifier: String
    let scriptingFamily: ScriptingFamily

    static let chrome = Browser(name: "Google Chrome", bundleIdentifier: "com.google.Chrome", scriptingFamily: .chromium)
    static let brave = Browser(name: "Brave", bundleIdentifier: "com.brave.Browser", scriptingFamily: .chromium)
    static let edge = Browser(name: "Microsoft Edge", bundleIdentifier: "com.microsoft.edgemac", scriptingFamily: .chromium)
    static let vivaldi = Browser(name: "Vivaldi", bundleIdentifier: "com.vivaldi.Vivaldi", scriptingFamily: .chromium)
    static let chromium = Browser(name: "Chromium", bundleIdentifier: "org.chromium.Chromium", scriptingFamily: .chromium)
    static let safari = Browser(name: "Safari", bundleIdentifier: "com.apple.Safari", scriptingFamily: .safari)

    /// Every supported browser. Order sets the fallback for new tabs, so Chrome comes first.
    static let supported: [Browser] = [.chrome, .brave, .edge, .vivaldi, .chromium, .safari]

    /// Supported browsers that are installed on this Mac.
    static var installed: [Browser] {
        supported.filter(\.isInstalled)
    }

    static func withBundleIdentifier(_ identifier: String) -> Browser? {
        supported.first { $0.bundleIdentifier == identifier }
    }

    var applicationURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }

    var isInstalled: Bool {
        applicationURL != nil
    }

    var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
    }
}
