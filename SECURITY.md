# Security Policy

## Supported versions

Only the latest release receives security fixes.

| Version | Supported |
| ------- | --------- |
| 1.x     | Yes       |
| < 1.0   | No        |

## Reporting a vulnerability

**Please don't report security vulnerabilities in public issues or pull requests.**

Report them privately using GitHub's private vulnerability reporting:

<https://github.com/jagoncalves14/retab/security/advisories/new>

Include as much of the following as you can:

- A description of the issue and its impact
- Steps to reproduce, or a proof of concept
- The affected Retab version and macOS version
- Any suggested fix

We aim to acknowledge reports within 3 business days and to share a status update within 10 business days. We'll keep you informed as we investigate and coordinate a fix and disclosure timeline with you.

## Scope

Retab receives every web link on the system and controls Google Chrome through macOS Automation, so reports about the following are especially welcome:

- Incorrect or unintended handling of URLs, including leaking URLs or sending them anywhere
- Abuse of the Automation permission or of AppleScript execution
- Ways for a malicious link or web page to trigger unintended actions in Retab or Chrome

Vulnerabilities in macOS or Google Chrome should be reported to Apple or Google.

## Verifying downloads

Each release publishes a SHA-256 checksum next to the disk image. To verify a download, run:

```sh
shasum -a 256 Retab.dmg
```

Compare the output with the checksum on the release page. Retab is not notarized yet, so verifying the checksum is the best way to confirm you have the official build.
