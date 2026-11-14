# Retab

[![Release](https://img.shields.io/github/v/release/jagoncalves14/retab?label=release)](https://github.com/jagoncalves14/retab/releases/latest)
[![CI](https://github.com/jagoncalves14/retab/actions/workflows/ci.yml/badge.svg)](https://github.com/jagoncalves14/retab/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)

**Retab stops duplicate browser tabs.** When a link opens from another app, such as T3 Code, Slack, or Mail, Retab checks the tabs open in your default browser. If the page is already open, it switches to that tab. If not, it opens the link in a new tab.

Retab works with any default browser. It switches to open tabs in Google Chrome, Brave, Microsoft Edge, Vivaldi, Chromium, and Safari. Other browsers, such as Firefox, get every link in a new tab, as they would without Retab.

Retab is a menu bar utility. It has no Dock icon, no windows, and no Cmd+Tab entry.

<!-- Add a screenshot or logo here, e.g. docs/screenshot.png -->

## Download

**[Download Retab.dmg](https://github.com/jagoncalves14/retab/releases/latest/download/Retab.dmg)**

Requires macOS 13 (Ventura) or later and one of the supported browsers. Every release lists a SHA-256 checksum you can use to verify the download.

## Install

1. Open `Retab.dmg`.
2. Drag **Retab** onto the **Applications** folder.
3. Open Retab from Applications. A tab icon appears in the menu bar, and macOS asks whether to use Retab as your default browser. Choose **Use "Retab"**. Retab remembers the browser that was your default and opens every link there.
4. The first time a link arrives, approve the prompt that lets Retab control your browser.

### First launch warning

Retab isn't notarized by Apple yet, so macOS may block it the first time. To allow it:

- Open **System Settings → Privacy & Security**, scroll to the message about Retab, and click **Open Anyway**.

Or, in Terminal:

```sh
xattr -dr com.apple.quarantine /Applications/Retab.app
```

## How it works

- macOS sends every link to the default web browser and no other app sees it. So Retab registers as the default browser, receives each http and https link, and passes it on.
- When Retab becomes the default, it remembers the browser it replaces. That stays your browser, and every link opens there.
- Retab reads the URL of each open tab in your default browser and compares it with the incoming link. It only reads tabs while the browser is running.
- Tracking parameters (such as `utm_*` and `fbclid`) and `#fragments` are ignored during comparison.
- If a tab matches, Retab focuses that tab and its window. The page is not reloaded.
- If no tab matches, the link opens in a new tab, unchanged.

## Privacy and permissions

- **Browser control (Automation):** lets Retab read tab URLs and switch tabs. Retab does not store, log, or transmit these URLs. It has no network code.
- **Default web browser:** Retab receives every web link from every app and forwards it only to your default browser.

To revoke access:

- **Browser control:** System Settings → Privacy & Security → Automation → Retab.
- **Default browser:** System Settings → Desktop & Dock → Default web browser, then pick another browser.

## Menu bar options

- **Pause Retab / Resume Retab:** while paused, every link opens in a new tab and Retab doesn't read your tabs. The menu bar icon dims so you can tell it's paused.
- **Launch at Login:** starts Retab when you log in.
- **Quit Retab:** closes the app.

If Retab stops being the default browser, for example after you change it in System Settings, the menu shows **Retab Isn't Handling Links** at the top. Click it to set Retab up again.

Retab stays silent when a link works. It shows an alert only when you need to act, for example to allow it to control your browser.

## Troubleshooting

| Symptom | Likely cause and fix |
| --- | --- |
| A new tab opens instead of focusing the existing one | The URLs differ, for example by a session ID or a different query string. Retab only treats URLs as the same page when they match after removing tracking parameters and fragments. Also check that Retab isn't paused. |
| An alert asks you to allow Retab to control your browser | Turn on your browser under System Settings → Privacy & Security → Automation → Retab. Until then, links open in a new tab. |
| The menu says **Retab Isn't Handling Links** | Another app or System Settings changed the default browser. Click the item and choose **Use "Retab"**. |
| Links open in the wrong browser | Set the browser you want as the default in Desktop & Dock → Default web browser. Then click **Retab Isn't Handling Links** in the Retab menu. Retab switches to that browser. |
| macOS says Retab can't be opened | See [First launch warning](#first-launch-warning). |

## Limitations

- Switching to an open tab works in Google Chrome, Brave, Microsoft Edge, Vivaldi, Chromium, and Safari. Firefox and browsers built on it don't let other apps read or switch their tabs, so links open there in a new tab every time.
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
