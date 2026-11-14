import AppKit

/// A single tab in a browser window, addressed by its AppleScript indices.
struct BrowserTab {
    let window: Int
    let tab: Int
    let url: String
}

enum BrowserError: Error {
    /// The user has not allowed Retab to control the browser (Automation).
    case automationDenied
    case scriptFailed(String)
}

/// Reads and switches tabs in a browser through its scripting dictionary.
/// Scripts run in-process via NSAppleScript so the Automation prompt names Retab.
enum BrowserController {
    /// Lists every tab URL across all of the browser's windows. Reads only; never reloads pages.
    static func openTabs(in browser: Browser) throws -> [BrowserTab] {
        // `try` skips windows that have no tabs, such as Safari's Settings window.
        let source = """
        set output to ""
        tell application id "\(browser.bundleIdentifier)"
            repeat with windowIndex from 1 to (count of windows)
                try
                    set browserWindow to window windowIndex
                    repeat with tabIndex from 1 to (count of tabs of browserWindow)
                        set output to output & windowIndex & (ASCII character 9) & tabIndex & (ASCII character 9) & (URL of tab tabIndex of browserWindow) & linefeed
                    end repeat
                end try
            end repeat
        end tell
        return output
        """
        let text = try run(source)
        return text.split(separator: "\n").compactMap { line in
            let parts = line.split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false)
            guard parts.count == 3, let window = Int(parts[0]), let tab = Int(parts[1]) else { return nil }
            return BrowserTab(window: window, tab: tab, url: String(parts[2]))
        }
    }

    /// Brings an existing tab to the front: selects it, raises its window, activates the browser.
    static func focus(_ target: BrowserTab, in browser: Browser) throws {
        let selectTab: String
        switch browser.scriptingFamily {
        case .chromium:
            selectTab = "set active tab index of browserWindow to \(target.tab)"
        case .safari:
            selectTab = "set current tab of browserWindow to tab \(target.tab) of browserWindow"
        }
        let source = """
        tell application id "\(browser.bundleIdentifier)"
            set browserWindow to window \(target.window)
            \(selectTab)
            set index of browserWindow to 1
            activate
        end tell
        """
        _ = try run(source)
    }

    /// Opens a URL as a new tab in the browser at `applicationURL` (launches it if needed).
    @discardableResult
    static func openNewTab(_ url: URL, withApplicationAt applicationURL: URL?) -> Bool {
        guard let applicationURL else { return false }
        NSWorkspace.shared.open(
            [url],
            withApplicationAt: applicationURL,
            configuration: NSWorkspace.OpenConfiguration()
        )
        return true
    }

    private static func run(_ source: String) throws -> String {
        guard let script = NSAppleScript(source: source) else {
            throw BrowserError.scriptFailed("Could not compile AppleScript")
        }
        var errorInfo: NSDictionary?
        let result = script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let number = errorInfo[NSAppleScript.errorNumber] as? Int ?? 0
            if number == -1743 {
                throw BrowserError.automationDenied
            }
            let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "AppleScript failed"
            throw BrowserError.scriptFailed(message)
        }
        return result.stringValue ?? ""
    }
}
