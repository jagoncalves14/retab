# Retab

[![Release](https://img.shields.io/github/v/release/jagoncalves14/retab?label=release)](https://github.com/jagoncalves14/retab/releases/latest)
[![CI](https://github.com/jagoncalves14/retab/actions/workflows/ci.yml/badge.svg)](https://github.com/jagoncalves14/retab/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)

**Retab stops duplicate Google Chrome tabs.** When a link opens from another app, such as T3 Code, Slack, or Mail, Retab checks your open Chrome tabs. If the page is already open, it switches to that tab. If not, it opens the link in a new tab.

Retab is a menu bar utility. It has no Dock icon, no windows, and no Cmd+Tab entry.

<!-- Add a screenshot or logo here, e.g. docs/screenshot.png -->

## Download

**[Download Retab.dmg](https://github.com/jagoncalves14/retab/releases/latest/download/Retab.dmg)**

Requires macOS 13 (Ventura) or later and Google Chrome. Every release lists a SHA-256 checksum you can use to verify the download.

## Install

1. Open `Retab.dmg`.
2. Drag **Retab** onto the **Applications** folder.
3. Open Retab from Applications. A tab icon appears in the menu bar.
4. Click the tab icon and choose **Set as Default Browser**. Approve the macOS prompt.
5. The first time a link arrives, approve the prompt that lets Retab control Google Chrome.

### First launch warning

Retab isn't notarized by Apple yet, so macOS may block it the first time. To allow it:

- Open **System Settings → Privacy & Security**, scroll to the message about Retab, and click **Open Anyway**.

Or, in Terminal:

```sh
xattr -dr com.apple.quarantine /Applications/Retab.app
```

## How it works

- macOS sends every http and https link to Retab once it is the default web browser.
- Retab reads the URL of each open Chrome tab and compares it with the incoming link.
- Tracking parameters (such as `utm_*` and `fbclid`) and `#fragments` are ignored during comparison.
- If a tab matches, Retab focuses that tab and its window. The page is not reloaded.
- If no tab matches, the link opens in a new Chrome tab, unchanged.

## Privacy and permissions

- **Chrome control (Automation):** lets Retab read tab URLs and switch tabs. Retab does not store, log, or transmit these URLs. It has no network code.
- **Default web browser:** Retab receives every web link from every app and forwards it only to Chrome.

To revoke access:

- **Chrome control:** System Settings → Privacy & Security → Automation → Retab.
- **Default browser:** System Settings → Desktop & Dock → Default web browser, then pick another browser.

## Menu bar options

- **Status line:** shows the result of the last link (for example, *Focused existing Chrome tab*).
- **Set as Default Browser:** makes Retab the default browser for http and https.
- **Launch at Login:** starts Retab when you log in.
- **Quit Retab:** closes the app.

## Troubleshooting

| Symptom | Likely cause and fix |
| --- | --- |
| A new tab opens instead of focusing the existing one | The URLs differ, for example by a session ID or a different query string. Retab only treats URLs as the same page when they match after removing tracking parameters and fragments. |
| Status says *Allow Retab to control Chrome* | Enable Retab under System Settings → Privacy & Security → Automation. |
| Links still open in another browser | Choose **Set as Default Browser** from the menu bar, or set Retab under Desktop & Dock → Default web browser. |
| macOS says Retab can't be opened | See [First launch warning](#first-launch-warning). |

## Limitations

- Works with Google Chrome only.
- Different query strings count as different pages.

## Build from source

Requirements: macOS 13 or later and Xcode 16.3 or later (the Command Line Tools include the Swift toolchain).

```sh
swift build -c release   # compile
swift test               # run unit tests
sh scripts/build-app.sh  # create build/Retab.app and build/Retab.dmg
```

## Releasing

1. Update `CFBundleShortVersionString` in `Resources/Info.plist` and the changelog.
2. Commit, then tag the commit with the same version and push the tag:

   ```sh
   git tag v1.0.0
   git push origin v1.0.0
   ```

The release workflow checks that the tag matches the app version, builds the disk image, and publishes it with a SHA-256 checksum.

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Retab is intentionally focused on one job, so discuss larger changes in an issue first.

## Security

To report a vulnerability, follow [SECURITY.md](SECURITY.md). Please don't open a public issue for security problems.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

Retab is released under the [MIT License](LICENSE).
