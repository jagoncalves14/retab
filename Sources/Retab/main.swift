import AppKit

// Retab is a menu bar-only app: no Dock icon, no Cmd+Tab entry, no windows.
MainActor.assumeIsolated {
    let application = NSApplication.shared
    application.setActivationPolicy(.accessory)

    let delegate = AppDelegate()
    application.delegate = delegate
    application.run()
}
