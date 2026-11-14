# Changelog

All notable changes to Retab are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Works with any default browser. Retab remembers the browser it replaces as the default and opens every link there.
- Switching to open tabs in Brave, Microsoft Edge, Vivaldi, Chromium, and Safari, alongside Google Chrome.
- **Pause Retab / Resume Retab** menu item. While paused, links open in a new tab and the menu bar icon dims.

### Changed

- On first launch, Retab asks macOS to make it the default browser, so setup is one click on the macOS prompt.
- Replaced the **Set as Default Browser** menu item with a **Retab Isn't Handling Links** warning that appears only when Retab isn't the default browser.
- Problems that need action, such as a missing Automation permission, show an alert.

### Removed

- The status line at the top of the menu. Retab stays silent when a link works.

## [1.0.0] - 2026-11-14

### Added

- Menu bar app that focuses an already-open Google Chrome tab instead of opening a duplicate.
- Opens links in a new Chrome tab when no matching tab is open.
- Matching ignores tracking parameters (`utm_*`, `fbclid`, and others) and `#fragments`.
- **Set as Default Browser** menu item to set Retab as the default browser for http and https.
- **Launch at Login** option.
- Status line that reports the result of the last link.
- `scripts/build-app.sh` to build the app bundle and a drag-to-Applications disk image.
- Unit tests for URL matching.

[Unreleased]: https://github.com/jagoncalves14/retab/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/jagoncalves14/retab/releases/tag/v1.0.0
