# Zen Garden

<p align="center">
  <img src="Sources/ZenGarden/Resources/ZenGardenHero.png" alt="Zen Garden landscape" width="820">
</p>

<p align="center">
  A free, open-source, local-first website blocker for macOS.
</p>

<p align="center">
  <a href="https://github.com/Sushmithamallesh/zen-garden/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/Sushmithamallesh/zen-garden/actions/workflows/ci.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-6e8033"></a>
  <img alt="macOS 13 or newer" src="https://img.shields.io/badge/macOS-13%2B-6e8033">
</p>

Zen Garden helps you stay away from distracting websites while you work. It
lives in the menu bar, redirects selected domains to a local focus page, and
requires a written reason before briefly unblocking one.

Everything runs on your Mac. There is no account, subscription, analytics
service, or remote server.

## Quick start

1. Install and open Zen Garden.
2. Allow browser Automation when macOS asks.
3. Add or remove websites from the blocklist.
4. Leave Zen Garden running in the menu bar.

The default schedule starts automatically. You can also start a 25, 50, or
90-minute session from the menu bar at any time.

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

- Menu-bar controls for starting focus, unblocking one website, and resuming blocking
- Reason-required, time-limited website access
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

## Default week

| Day | Automatic behavior |
| --- | --- |
| Monday–Friday | Block enabled websites from 7:00 AM to 5:00 PM |
| Saturday | No automatic blocking |
| Sunday | Block enabled websites all day; `x.com` and `twitter.com` cannot be temporarily unblocked |

The weekday start and end times are editable. Manual sessions and custom
schedules can add focus time outside these defaults.

## How it works

During an active focus session, Zen Garden reads the URL of the active tab in
the frontmost supported browser. If its domain matches the enabled blocklist,
the app redirects that tab to a self-contained focus page bundled with the app.
Subdomains are included: blocking `reddit.com` also blocks
`www.reddit.com` and `old.reddit.com`, without matching lookalike domains.

Zen Garden uses macOS Automation for this browser interaction. The first time
it needs access to a browser, macOS asks you to allow it. You can inspect or
revoke that permission at **System Settings → Privacy & Security → Automation**.

| Capability | Used? | Why |
| --- | --- | --- |
| Browser Automation | Yes | Read the active tab URL and redirect a blocked tab |
| Launch at login | Yes, by default | Keep automatic schedules running after sign-in |
| Screen Recording | No | Zen Garden does not inspect the screen |
| Accessibility | No | Zen Garden does not simulate input or inspect other interfaces |
| Network service | No | Blocking, settings, artwork, and fonts are local |

See [Privacy](PRIVACY.md) for exactly what is stored and why.

## Why trust it?

- The complete source, build scripts, and release workflow are public.
- The app has no third-party runtime code dependencies.
- CI builds and tests every change on `main`.
- Release downloads are built by GitHub Actions and include SHA-256 checksums.
- The preview requests one entitlement: permission to send Apple Events to
  supported browsers. It is not currently App Sandbox-enabled.
- Website lists, schedules, and access reasons remain on your Mac.
- The bundled Inter typeface retains its upstream open-source font license.

To verify the DMG, download both `Zen-Garden.dmg` and `SHA256SUMS.txt` from the
same release into one directory, then run:

```sh
grep 'Zen-Garden.dmg' SHA256SUMS.txt | shasum -a 256 -c -
```

This detects a damaged or mismatched download. Because the checksum is hosted
beside the binary, it does not independently prove publisher identity. The
current preview's source is the strongest verification path; Developer ID
signing and notarization are planned for the normal public release.

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

The [`raycast`](raycast) folder contains **Unblock a Website**, **Resume
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

## Repository map

| Path | Contents |
| --- | --- |
| `Sources/ZenGarden` | SwiftUI app, browser integration, settings, and bundled resources |
| `scripts` | Core tests, app build, icon rendering, and release packaging |
| `raycast` | Three ready-to-import Raycast Script Commands |
| `.github/workflows` | CI and GitHub Release automation |
| `docs/RELEASING.md` | Maintainer release checklist |

## Limits

Zen Garden is a behavioral focus tool, not tamper-proof parental-control or
security software. Blocking stops if you quit the app, revoke Automation
permission, use a private browser profile that does not expose its active tab,
or use an unsupported browser. It monitors only the active tab in the frontmost
supported browser; it is not a network filter, browser extension, VPN, or app
blocker. Blocklist and schedule settings also remain editable during focus, and
browser wrapper pages can fall outside URL matching. It does not currently
update itself; download new versions from GitHub Releases.

Read the latest [security review](docs/SECURITY-REVIEW.md) for the tested scope,
known limitations, and remaining hardening work.

## Contributing

Bug reports and focused improvements are welcome. Read
[CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request. Please report
security issues privately according to [SECURITY.md](SECURITY.md).

## License

Zen Garden source code is available under the [MIT License](LICENSE). The
bundled [Inter typeface](Sources/ZenGarden/Resources/Inter-OFL.txt) is provided
under the SIL Open Font License 1.1.
