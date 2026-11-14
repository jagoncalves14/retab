# Contributing to Retab

Thanks for your interest in improving Retab. This guide explains how to set up the project, what we expect in a change, and how to get it merged.

By participating, you agree to abide by the [Code of Conduct](CODE_OF_CONDUCT.md).

## Scope

Retab does one thing: it prevents duplicate Google Chrome tabs when links arrive from other apps. Changes that broaden the app into a general-purpose tool are unlikely to be accepted. If you have an idea, open an issue first so we can agree on scope before you invest time in code.

## Getting started

### Requirements

- macOS 13 or later
- Xcode 16.3 or later (or the Command Line Tools with a matching Swift toolchain)
- Google Chrome, for manual testing

### Build and test

```sh
swift build            # debug build
swift test             # unit tests
sh scripts/build-app.sh  # release app bundle and disk image in build/
```

Run `swift test` and `swift build -c release` before opening a pull request. The CI workflow runs the same commands.

### Manual testing

Some behavior depends on macOS and Chrome and cannot be fully automated. If your change touches link routing, Automation, or the menu, test these flows manually:

1. Set Retab as the default browser, then click an http link in another app while Chrome already has that page open. The existing tab should be focused, with no new tab.
2. Click a link that is not open in Chrome. It should open in a new tab.
3. Deny the Automation permission and confirm the status line explains what to do.
4. Toggle **Launch at Login** and confirm the checkmark matches the system state.

Mention which of these you tested in your pull request.

## Code guidelines

- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- Use four-space indentation and keep lines readable (roughly 120 characters).
- Keep AppKit and UI code on the main actor.
- Prefer small, pure functions for logic that can be unit-tested, like `URLMatcher`.
- Retab has no third-party dependencies. Please don't add one without discussing it first.
- Don't log, persist, or transmit URLs. Retab handles every web link on the system, so privacy is a hard requirement.

## Tests

- Add or update unit tests in `Tests/RetabTests/` for any change to URL matching or normalization.
- A bug fix should include a test that fails without the fix.

## Commits and pull requests

- Use [Conventional Commits](https://www.conventionalcommits.org/) for commit messages, for example `feat: ...`, `fix: ...`, `docs: ...`, or `chore: ...`.
- Keep each pull request to a single concern.
- Fill in the pull request template.
- Add a line under `## [Unreleased]` in `CHANGELOG.md` for user-visible changes.
- All CI checks must pass before review.

## Reporting bugs and requesting features

Use the issue templates. For bugs, include your macOS version, Chrome version, and clear steps to reproduce. Remove any private information from URLs before sharing them.

For security issues, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.
