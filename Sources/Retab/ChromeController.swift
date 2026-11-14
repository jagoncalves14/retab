import AppKit

/// A single tab in a Google Chrome window, addressed by its AppleScript indices.
struct ChromeTab {
    let window: Int
    let tab: Int
    let url: String
}

enum ChromeError: Error {
    /// The user has not allowed Retab to control Google Chrome (Automation).
    case automationDenied
    case scriptFailed(String)
}

/// Controls Google Chrome through its scripting dictionary.
/// Scripts run in-process via NSAppleScript so the Automation prompt names Retab.
enum ChromeController {
    static let bundleIdentifier = "com.google.Chrome"

    static var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty
    }

    static var applicationURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }

    /// Lists every tab URL across all Chrome windows. Reads only; never reloads pages.
    static func openTabs() throws -> [ChromeTab] {
        let source = """
        set output to ""
        tell application id "\(bundleIdentifier)"
            repeat with wi from 1 to (count of windows)
                set w to window wi
                repeat with ti from 1 to (count of tabs of w)
                    set output to output & wi & (ASCII character 9) & ti & (ASCII character 9) & (URL of tab ti of w) & linefeed
                end repeat
            end repeat
        end tell
        return output
        """
        let text = try run(source)
        return text.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false)
            guard parts.count == 3, let window = Int(parts[0]), let tab = Int(parts[1]) else { return nil }
            return ChromeTab(window: window, tab: tab, url: String(parts[2]))
        }
    }

    /// Brings an existing tab to the front: selects it, raises its window, activates Chrome.
    static func focus(_ target: ChromeTab) throws {
        let source = """
        tell application id "\(bundleIdentifier)"
            set w to window \(target.window)
            set active tab index of w to \(target.tab)
            set index of w to 1
            activate
        end tell
        """
        _ = try run(source)
    }

    /// Opens a URL as a new tab in Chrome (launches Chrome if needed).
    @discardableResult
    static func openNewTab(_ url: URL) -> Bool {
        guard let appURL = applicationURL else { return false }
        NSWorkspace.shared.open(
            [url],
            withApplicationAt: appURL,
            configuration: NSWorkspace.OpenConfiguration()
        )
        return true
    }

    private static func run(_ source: String) throws -> String {
        guard let script = NSAppleScript(source: source) else {
            throw ChromeError.scriptFailed("Could not compile AppleScript")
        }
        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let number = errorInfo[NSAppleScript.errorNumber] as? Int ?? 0
            if number == -1743 {
                throw ChromeError.automationDenied
            }
            let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "AppleScript failed"
            throw ChromeError.scriptFailed(message)
        }
        return result.stringValue ?? ""
    }
}
