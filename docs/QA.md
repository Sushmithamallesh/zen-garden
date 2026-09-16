# First-release QA

Run the automated suite before every release:

```sh
./scripts/test-core.sh
./scripts/build-app.sh
./scripts/verify-build.sh
```

The automated checks cover domain normalization and matching, exact schedule
boundaries, overnight schedules, Saturday and Sunday policy, daylight-saving
transitions, temporary-access validation and expiry, persistence repair,
packaged resources, bundle metadata, code sealing, DMG/ZIP creation, and
checksums.

The following checks require a signed build in a real macOS desktop session.
Complete them on both the oldest supported macOS release and the current
release before promoting a preview to a stable release.

## Menu bar and windows

- Open Zen Garden, then click another app's status item. Zen Garden closes.
- Open Zen Garden, then click Control Center and Notification Center. Zen Garden closes.
- Click outside, press Escape, and click the leaf again. Each closes the panel.
- Open the ellipsis menu and the website picker. The parent panel remains open.
- Click the leaf rapidly several times. At most one panel remains open.
- Close the dashboard window. Blocking and the menu-bar item remain active.
- Reopen the dashboard from the ellipsis menu and `zengarden://open` after it was closed.
- Test with an auto-hidden menu bar, a full-screen app, each display, and a notched display.

## Focus and temporary access

- Verify weekday activation at exactly the configured start and end times.
- Wake the Mac during an active window and confirm blocking resumes immediately.
- Confirm Saturday is free and Sunday is active from midnight to midnight.
- Confirm `x.com` and `twitter.com` cannot be disabled, removed, or temporarily unblocked on Sunday.
- Request access using whitespace, multiline text, emoji, and a 500-character reason.
- Disable or delete a site during its temporary exception. The exception ends.
- Sleep through an exception's expiry and confirm the site is blocked after wake.
- Relaunch during an exception and confirm its original expiry is preserved.

## Browsers

For Safari, Arc, Chrome, Brave, Edge, and Opera:

- Grant and deny Automation access on a fresh macOS user account.
- Test a normal window, private window/profile, multiple windows, and full screen.
- Test direct navigation, a new tab, reload, back/forward, redirects, and subdomains.
- Quit or force-quit the browser while Zen Garden is checking it, then reopen it.
- Confirm the local block page appears without a redirect loop.
- Confirm an unsupported browser is not described as protected.

## App lifecycle and distribution

- Confirm Command-Q leaves the background blocker running.
- Confirm **Quit Zen Garden** in the ellipsis menu ends the process.
- Confirm login-item status matches System Settings after enable, disable, restart, and update.
- Run each Raycast command before launch, after closing the dashboard, and repeatedly.
- Install from both the DMG and ZIP, from Downloads and Applications.
- Test Apple silicon and Intel builds. Verify an update preserves settings and permissions.
- For a stable release, verify Gatekeeper and the stapled notarization ticket.

Record the macOS version, hardware, browsers and versions, build tag, and result
for every manual release run. A failed item blocks a stable release unless it is
documented as an explicit product limitation.
