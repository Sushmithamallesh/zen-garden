# Zen Garden

<p align="center">
  <img src="Sources/ZenGarden/Resources/ZenGardenHero.png" alt="Zen Garden landscape" width="820">
</p>

<p align="center">
  A calm, local-first website blocker for macOS.
</p>

<p align="center">
  <a href="https://github.com/Sushmithamallesh/zen-garden/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/Sushmithamallesh/zen-garden/actions/workflows/ci.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-6e8033"></a>
  <img alt="macOS 13 or newer" src="https://img.shields.io/badge/macOS-13%2B-6e8033">
</p>

Zen Garden helps you stay away from distracting websites while you work. It
lives in the menu bar, blocks selected domains in your browser, and requires a
written reason before granting temporary access.

Everything runs on your Mac. There is no account, subscription, analytics
service, or remote server.

## Download

**[Download Zen Garden v0.3.1 for macOS (.dmg)](https://github.com/Sushmithamallesh/zen-garden/releases/download/v0.3.1/Zen-Garden.dmg)**

The release is universal and works on Apple silicon and Intel Macs running
macOS 13 or newer. Open the DMG, then drag **Zen Garden** into **Applications**.

> [!IMPORTANT]
> v0.3.1 is a public preview. It is ad-hoc signed, not yet signed with an Apple
> Developer ID or notarized by Apple. macOS will therefore show a security
> warning. If you prefer not to override Gatekeeper, build from source or wait
> for the notarized v1 release.

To open this preview:

1. Try to open **Zen Garden** from Applications once.
2. Open **System Settings → Privacy & Security**.
3. Scroll to Security and choose **Open Anyway**, then confirm.

Apple explains this override and its risks in
[Open an app by overriding security settings](https://support.apple.com/guide/mac-help/open-an-app-by-overriding-security-settings-mh40617/mac).

See the [release page](https://github.com/Sushmithamallesh/zen-garden/releases/tag/v0.3.1)
for the ZIP alternative, checksums, and release notes.

## Features

- Menu-bar controls for starting focus, requesting a break, and resuming blocking
- Reason-required, site-specific temporary access
- Adjustable weekday blocking, initially set to 7:00 AM–5:00 PM
- Saturday off and all-day Sunday focus by default
- A Sunday rule that refuses temporary access to `x.com` and `twitter.com`
- 25, 50, and 90-minute manual sessions
- Custom weekly and overnight schedules
- Editable website blocklist with subdomain matching
- Safari, Arc, Chrome, Brave, Edge, and Opera support
- Raycast commands for the primary actions
- Launch at login, enabled by default and removable in Settings
- A local block page matching the app’s garden design

## How it works

During an active focus session, Zen Garden reads the URL of the active tab in
the frontmost supported browser. If the domain matches the enabled blocklist,
the app redirects that tab to its bundled local block page.

Zen Garden uses macOS Automation for this browser interaction. The first time
it needs access to a browser, macOS asks you to allow it. You can inspect or
revoke that permission at **System Settings → Privacy & Security → Automation**.

It does not request Screen Recording or Accessibility access. See
[Privacy](PRIVACY.md) for exactly what is stored and why.

## Why trust it?

- The complete source and release workflow are public.
- The app has no third-party code dependencies.
- CI builds and tests every change on `main`.
- Release downloads are built by GitHub Actions and include SHA-256 checksums.
- The only app entitlement is permission to send Apple Events to supported browsers.
- Website lists, schedules, and break reasons remain on your Mac.

To verify the DMG after downloading `SHA256SUMS.txt` from the release:

```sh
grep 'Zen-Garden.dmg' SHA256SUMS.txt | shasum -a 256 -c -
```

Developer ID signing and Apple notarization are the remaining requirements for
a normal one-click public installation. Apple recommends both for apps
distributed outside the Mac App Store; the release workflow already supports
them once the credentials are configured.

## Browser support

| Browser | Status |
| --- | --- |
| Safari | Supported |
| Arc | Supported |
| Google Chrome | Supported |
| Brave | Supported |
| Microsoft Edge | Supported |
| Opera | Supported |
| Firefox | Not supported yet |

Firefox does not expose the Apple Events tab interface used by this release.

## Raycast

The [`raycast`](raycast) folder contains **Request a Break**, **Resume
Blocking**, and **Open Zen Garden** Script Commands. Add that directory under
**Raycast Settings → Extensions → Add Directories** after installing and
launching Zen Garden once.

## Build from source

Install Xcode 16 or a Swift 6 toolchain, then run:

```sh
git clone https://github.com/Sushmithamallesh/zen-garden.git
cd zen-garden
./scripts/test-core.sh
./scripts/build-app.sh
open "dist/Zen Garden.app"
```

You can also open `Package.swift` in Xcode and run the `ZenGarden` scheme.

## Limits

Zen Garden is a behavioral focus tool, not tamper-proof parental-control or
security software. Blocking stops if you quit the app, revoke Automation
permission, or use an unsupported browser. It does not currently update itself;
download new versions from GitHub Releases.

## Contributing

Bug reports and focused improvements are welcome. Read
[CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Please report
security issues privately according to [SECURITY.md](SECURITY.md).

## License

Zen Garden is available under the [MIT License](LICENSE).
