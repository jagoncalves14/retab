import AppKit
import OSLog
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static let logger = Logger(subsystem: "app.retab.macos", category: "default-browser")

    private var statusItem: NSStatusItem?
    /// The Automation alert shows once per launch, so a denied permission doesn't nag on every link.
    private var hasShownAutomationAlert = false

    private let pauseItem = NSMenuItem(title: "Pause Retab", action: #selector(togglePause), keyEquivalent: "")
    /// Shown only while Retab isn't the default browser, which means no links reach it.
    private let notHandlingLinksItem = NSMenuItem(
        title: "Retab Isn't Handling Links",
        action: #selector(fixLinkHandling),
        keyEquivalent: ""
    )
    private let notHandlingLinksSeparator = NSMenuItem.separator()
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
        rememberCurrentDefaultBrowser()
        refreshMenuState()

        // First launch: ask macOS straight away, so setup is a single click on its prompt.
        // Only once: if the user keeps their browser, the menu offers the fix instead of asking again.
        if !isDefaultBrowser() && !Preferences.hasRequestedDefaultBrowser {
            Preferences.hasRequestedDefaultBrowser = true
            requestDefaultBrowser(alertsOnFailure: false)
        }
    }

    /// macOS calls this for every http/https link once Retab is the default handler.
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            report(LinkRouter.route(url))
        }
    }

    // MARK: - Menu

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self

        notHandlingLinksItem.target = self
        notHandlingLinksItem.image = symbol("exclamationmark.triangle")
        notHandlingLinksItem.toolTip = "Make Retab your default browser so links reach it"
        if #available(macOS 14.4, *) {
            notHandlingLinksItem.subtitle = "Click to fix"
        }
        menu.addItem(notHandlingLinksItem)
        menu.addItem(notHandlingLinksSeparator)

        pauseItem.target = self
        menu.addItem(pauseItem)
        menu.addItem(.separator())

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

    /// Refreshes the menu each time it opens, so changes made in System Settings show up.
    func menuWillOpen(_ menu: NSMenu) {
        rememberCurrentDefaultBrowser()
        refreshMenuState()
    }

    private func refreshMenuState() {
        refreshPauseState()
        refreshLinkHandlingState()
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    // MARK: - Pause

    @objc private func togglePause() {
        Preferences.isPaused.toggle()
        refreshPauseState()
    }

    /// Paused: the menu offers Resume and the menu bar icon dims.
    private func refreshPauseState() {
        let isPaused = Preferences.isPaused
        pauseItem.title = isPaused ? "Resume Retab" : "Pause Retab"
        pauseItem.image = symbol(isPaused ? "play.circle" : "pause.circle")
        statusItem?.button?.appearsDisabled = isPaused
        statusItem?.button?.toolTip = isPaused ? "Retab is paused" : "Retab"
    }

    // MARK: - Default browser

    private func refreshLinkHandlingState() {
        let isHandlingLinks = isDefaultBrowser()
        notHandlingLinksItem.isHidden = isHandlingLinks
        notHandlingLinksSeparator.isHidden = isHandlingLinks
    }

    @objc private func fixLinkHandling() {
        requestDefaultBrowser(alertsOnFailure: true)
    }

    /// Asks macOS to make Retab the default browser. macOS shows its own confirmation prompt.
    private func requestDefaultBrowser(alertsOnFailure: Bool) {
        let appURL = Bundle.main.bundleURL
        Task { @MainActor in
            // Already the handler: nothing to change.
            if isDefaultBrowser() {
                refreshLinkHandlingState()
                return
            }

            // Note the browser Retab is replacing: links keep opening there.
            rememberCurrentDefaultBrowser()

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
            refreshLinkHandlingState()
            if !isDefaultBrowser() && alertsOnFailure {
                showAlert(
                    "Retab isn't handling links yet",
                    detail: "Choose Retab in System Settings → Desktop & Dock → Default web browser. Your links will still open in your browser."
                )
            }
        }
    }

    /// While Retab isn't the default browser, the system's default is the user's real browser.
    /// Remember it, so links open there once Retab takes over. Following it on every menu
    /// open means a browser change made in System Settings carries over.
    private func rememberCurrentDefaultBrowser() {
        guard let sample = URL(string: "https://example.com"),
              let handlerURL = NSWorkspace.shared.urlForApplication(toOpen: sample),
              let handlerID = Bundle(url: handlerURL)?.bundleIdentifier,
              handlerID != Bundle.main.bundleIdentifier else {
            return
        }
        Preferences.defaultBrowserBundleIdentifier = handlerID
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

    // MARK: - Launch at login

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            Self.logger.error("Changing Launch at Login failed: \(error.localizedDescription, privacy: .public)")
            showAlert("Couldn't change Launch at Login", detail: error.localizedDescription)
        }
        launchAtLoginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
    }

    // MARK: - Feedback

    /// Successful links need no feedback: the browser coming forward is the feedback.
    /// Only problems the user has to act on show an alert.
    private func report(_ outcome: LinkOutcome) {
        switch outcome {
        case .focusedExistingTab, .openedNewTab:
            break
        case .openedWithoutAutomation(let browserName):
            guard !hasShownAutomationAlert else { return }
            hasShownAutomationAlert = true
            showAlert(
                "Allow Retab to control \(browserName)",
                detail: "Until you do, links open in a new tab. Turn on \(browserName) in System Settings → Privacy & Security → Automation → Retab."
            )
        case .failed(let message):
            showAlert(message, detail: nil)
        }
    }

    private func showAlert(_ title: String, detail: String?) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = detail ?? ""
        alert.alertStyle = .warning
        // A menu bar app has no window in front, so bring the alert forward.
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    // MARK: - Images

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
