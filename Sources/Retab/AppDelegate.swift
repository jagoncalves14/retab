import AppKit
import OSLog
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let logger = Logger(subsystem: "app.retab.macos", category: "default-browser")

    private var statusItem: NSStatusItem?
    private let statusMenuItem = NSMenuItem(title: "Ready", action: nil, keyEquivalent: "")
    private let defaultBrowserItem = NSMenuItem(
        title: "Set as Default Browser",
        action: #selector(useAsDefaultBrowser),
        keyEquivalent: ""
    )
    private let launchAtLoginItem = NSMenuItem(
        title: "Launch at Login",
        action: #selector(toggleLaunchAtLogin),
        keyEquivalent: ""
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = menuBarImage()
            button.toolTip = "Retab"
        }
        item.menu = makeMenu()
        statusItem = item
        setStatus("Ready", symbol: "checkmark.circle")
        refreshLaunchAtLoginState()
    }

    /// macOS calls this for every http/https link once Retab is the default handler.
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            report(LinkRouter.route(url))
        }
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())

        defaultBrowserItem.target = self
        defaultBrowserItem.image = symbol("globe")
        menu.addItem(defaultBrowserItem)

        launchAtLoginItem.target = self
        launchAtLoginItem.image = symbol("sunrise")
        menu.addItem(launchAtLoginItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit Retab",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.image = symbol("power")
        menu.addItem(quitItem)
        return menu
    }

    @objc private func useAsDefaultBrowser() {
        let appURL = Bundle.main.bundleURL
        Task { @MainActor in
            // Already the handler: nothing to change, so don't report an error.
            if isDefaultBrowser() {
                setStatus("Retab handles web links", symbol: "checkmark.circle")
                return
            }

            do {
                for scheme in ["http", "https"] {
                    try await NSWorkspace.shared.setDefaultApplication(at: appURL, toOpenURLsWithScheme: scheme)
                }
            } catch {
                let nsError = error as NSError
                Self.logger.error(
                    "Setting default browser failed: domain=\(nsError.domain, privacy: .public) code=\(nsError.code) description=\(nsError.localizedDescription, privacy: .public)"
                )
            }

            // Judge the result by what macOS reports now, not by whether the call threw.
            if isDefaultBrowser() {
                setStatus("Retab handles web links", symbol: "checkmark.circle")
            } else {
                setStatus(
                    "Choose Retab in System Settings → Desktop & Dock → Default web browser",
                    symbol: "exclamationmark.triangle"
                )
            }
        }
    }

    /// True when macOS routes both http and https links to this app.
    private func isDefaultBrowser() -> Bool {
        let ownID = Bundle.main.bundleIdentifier
        return ["http", "https"].allSatisfy { scheme in
            guard let sample = URL(string: "\(scheme)://example.com"),
                  let handlerURL = NSWorkspace.shared.urlForApplication(toOpen: sample),
                  let handlerID = Bundle(url: handlerURL)?.bundleIdentifier else {
                return false
            }
            return handlerID == ownID
        }
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            Self.logger.error("Changing Launch at Login failed: \(error.localizedDescription, privacy: .public)")
            setStatus("Could not change Launch at Login", symbol: "exclamationmark.triangle")
        }
        refreshLaunchAtLoginState()
    }

    private func refreshLaunchAtLoginState() {
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    private func report(_ outcome: LinkOutcome) {
        switch outcome {
        case .focusedExistingTab:
            setStatus("Focused existing Chrome tab", symbol: "rectangle.on.rectangle")
        case .openedNewTab:
            setStatus("Opened in new Chrome tab", symbol: "plus.rectangle")
        case .openedWithoutAutomation:
            setStatus("Allow Retab to control Chrome in System Settings", symbol: "lock.shield")
        case .failed(let message):
            setStatus(message, symbol: "exclamationmark.triangle")
        }
    }

    private func setStatus(_ title: String, symbol name: String) {
        statusMenuItem.title = title
        statusMenuItem.image = symbol(name)
    }

    /// The brand mark for the menu bar: a vector PDF template loaded from the app bundle,
    /// so it stays sharp at every scale. Falls back to an SF Symbol if the asset is missing.
    private func menuBarImage() -> NSImage? {
        guard let url = Bundle.main.url(forResource: "MenuBarIcon", withExtension: "pdf"),
              let image = NSImage(contentsOf: url) else {
            return symbol("link")
        }
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }

    /// A template SF Symbol sized for menus. Template images adapt to light and dark menus.
    private func symbol(_ name: String) -> NSImage? {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        image?.isTemplate = true
        return image
    }
}
