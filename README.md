# Zen Garden

Zen Garden is a local-first macOS website blocker with a quiet Japandi-inspired interface. It blocks selected domains in supported browsers during manual focus sessions or recurring schedules.

## Download

Download the newest macOS build from [GitHub Releases](https://github.com/Sushmithamallesh/zen-garden/releases). The DMG is the simplest option: open it and drag Zen Garden to Applications.

Preview releases are ad-hoc signed while Apple Developer signing is being set up. On the first launch of a preview, Control-click **Zen Garden**, choose **Open**, then confirm **Open**. Signed and notarized releases will open normally.

Release builds are universal and support both Apple Silicon and Intel Macs.

## What is included

- Automatic blocking from 7:00 AM to 5:00 PM Monday–Friday, off Saturday, and all day Sunday
- A non-bypassable Sunday lock for `x.com` and `twitter.com`
- Launch at login enabled by default, with an opt-out in Settings
- Reason-required, site-specific breaks that close again automatically
- First-class menu-bar controls and Raycast script commands
- 25, 50, and 90-minute focus sessions
- Weekly schedules, including overnight schedules
- Editable website blocklist with subdomain matching
- Safari, Chrome, Brave, Edge, Arc, and Opera support
- A local zen-style block page
- No account, server, analytics, or browsing-history storage

## Requirements

- macOS 13 or newer
- Swift 6 toolchain or Xcode 16+

## Build a local `.app`

From this folder:

```sh
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open "dist/Zen Garden.app"
```

The build script also handles the split Command Line Tools SDK configuration
currently present on this Mac. Installing full Xcode later is still recommended
for editing, previews, debugging, and release signing.

The script creates an ad-hoc-signed local build at `dist/Zen Garden.app`. No Apple Developer membership or App Store publication is required to run it on your own Mac.

For the most dependable launch-at-login behavior, copy the app to `/Applications` before enabling that option.

### Launch troubleshooting

Launch the `.app` with Finder or the `open` command from your normal Terminal session. Do not run `Contents/MacOS/ZenGarden` directly: GUI apps need to be started through macOS Launch Services.

If a crash report stops in `_RegisterApplication` and names `codex` as the parent process, the app was started inside Codex's restricted execution environment. Leave the built app in `dist`, then open it yourself from Finder or run the `open` command above in Terminal. This is a launch-environment error; the app has not reached Zen Garden's code yet.

## Browser permission

When focus is active and you first open a blocked site, macOS asks whether Zen Garden may control the active browser. Choose **Allow**. You can review or change this later at:

**System Settings → Privacy & Security → Automation**

## Raycast

The `raycast` folder contains three Script Commands: **Request a Break**,
**Resume Blocking**, and **Open Zen Garden**.

In Raycast, open **Settings → Extensions → Add Directories** and select the
repository's `raycast` folder. The commands then appear in Raycast search. The
break command opens Zen Garden's small reason form directly; it does not open
the full settings window.

If you rebuild the app and macOS no longer presents the permission correctly, remove the old Automation permission and launch the new build again.

Use **Settings → Browser permission → Check browsers** to see which installed
browsers are connected and which still need Automation permission.

## Develop in Xcode

Install Xcode, then open `Package.swift`. Xcode recognizes the Swift package as a macOS executable project. Select the `ZenGarden` scheme and press **Run**.

The repository intentionally avoids external packages so the project can be built from the command line or Xcode without dependency setup.

Run the core domain and scheduling tests with:

```sh
chmod +x scripts/test-core.sh
./scripts/test-core.sh
```

## How blocking works

While focus is active, Zen Garden checks only the active tab of the frontmost
supported browser. If its host matches an enabled blocked domain, Zen Garden
asks the browser through Apple Events to replace the page with the local focus
page. Every redirect is read back and verified. Chromium-family browsers use a
self-contained page, with a safe blank-page fallback if a browser refuses the
styled destination.

The current adapters cover Safari, Arc, Google Chrome, Brave, Microsoft Edge,
and Opera. Firefox does not expose the tab automation interface used by this
version and is therefore not currently supported.

This is a behavioral boundary, not a security product. A user can still disable Automation permission, quit Zen Garden, or use an unsupported browser. A later version can replace this layer with browser extensions or a Network Extension for stronger enforcement.

## Distribution

GitHub Actions creates a universal DMG, ZIP, and SHA-256 checksum file whenever a version tag such as `v0.3.0` is pushed. Without Apple credentials it publishes an ad-hoc-signed prerelease. With a Developer ID certificate and notarization credentials configured, it publishes a normal signed release.

See [Releasing](docs/RELEASING.md) for the versioning, signing, and publishing steps. A website can link to the Releases page now; after the first signed release it can use this stable direct-download URL:

```text
https://github.com/Sushmithamallesh/zen-garden/releases/latest/download/Zen-Garden.dmg
```

## License

MIT. You may use, modify, and redistribute the project freely while preserving the license notice.
