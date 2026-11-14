# Changelog

All notable changes to Retab are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
