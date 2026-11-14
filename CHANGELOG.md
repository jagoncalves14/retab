# Changelog

All notable changes to Retab are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-11-14

### Added

- Menu bar app that switches to an already-open browser tab instead of opening a duplicate.
- Works with any default browser. Retab remembers the browser it replaces as the default and opens every link there.
- Switches to open tabs in Google Chrome, Brave, Microsoft Edge, Vivaldi, Chromium, and Safari. Other browsers, such as Firefox, get a new tab.
- Opens links in a new tab when no matching tab is open.
- Matching ignores tracking parameters (`utm_*`, `fbclid`, and others) and `#fragments`.
- On first launch, asks macOS to make Retab the default browser, so setup is one click on the macOS prompt.
- **Retab Isn't Handling Links** menu item that appears only when Retab isn't the default browser.
- **Pause Retab / Resume Retab** menu item. While paused, links open in a new tab and the menu bar icon dims.
- **Launch at Login** option.
- Alerts only for problems that need action, such as a missing Automation permission.
- `scripts/build-app.sh` to build the app bundle and a drag-to-Applications disk image.
- Unit tests for URL matching and the supported browser list.

[Unreleased]: https://github.com/jagoncalves14/retab/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/jagoncalves14/retab/releases/tag/v1.0.0
