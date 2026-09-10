# Releasing Zen Garden

Zen Garden ships directly through GitHub Releases. A release contains:

- `Zen-Garden.dmg` for normal drag-to-Applications installation
- `Zen-Garden.zip` as a compact alternative
- `SHA256SUMS.txt` for download verification

## Publish a version

1. Update `CFBundleShortVersionString` and `CFBundleVersion` in `Info.plist`.
2. Confirm `README.md` points to the version you are about to publish.
3. Run the complete local release checks:

   ```sh
   git diff --check
   ./scripts/test-core.sh
   ./scripts/build-app.sh --universal
   ./scripts/package-release.sh
   codesign --verify --deep --strict "dist/Zen Garden.app"
   (cd dist && shasum -a 256 -c SHA256SUMS.txt)
   ```

4. Test the packaged DMG on a separate macOS user account when permissions,
   login-item behavior, or first-launch behavior changed.
5. Commit and push the release changes. Wait for CI to pass.
6. Create a signed tag matching the app version and push it. For example:

   ```sh
   git tag -s v0.4.0 -m "Zen Garden v0.4.0"
   git push origin v0.4.0
   ```

The release workflow validates the tag against `Info.plist`, tests the app,
builds a universal macOS bundle, packages the downloads, and publishes them to
GitHub.

## Apple signing and notarization

The workflow works without credentials, but publishes the result as an ad-hoc-signed prerelease. Users must Control-click the app and choose **Open** on first launch.

For a normal public download, join the Apple Developer Program, create a **Developer ID Application** certificate, and add these repository secrets:

| Secret | Value |
| --- | --- |
| `APPLE_CERTIFICATE_P12` | Base64-encoded Developer ID `.p12` file |
| `APPLE_CERTIFICATE_PASSWORD` | Password used when exporting the `.p12` file |
| `APPLE_ID` | Apple ID used for notarization |
| `APPLE_TEAM_ID` | Apple Developer Team ID |
| `APPLE_APP_PASSWORD` | App-specific password for the Apple ID |

With all five values present, the workflow signs with hardened runtime, submits the app to Apple's notary service, staples the result, verifies it with Gatekeeper, and publishes a normal release. Until then, releases are clearly marked as previews because users must manually override Gatekeeper to open them.

Never place certificates, passwords, notarization credentials, or decoded
`.p12` files in the repository. GitHub Actions writes them only to the runner's
temporary directory and exposes each secret only to the step that needs it.
Protect the repository's release environment and `v*` tags before configuring
production credentials.

## Verify the published release

After the workflow completes:

1. Confirm the GitHub Actions run passed from the tagged commit.
2. Download the DMG, ZIP, and `SHA256SUMS.txt` from the release.
3. Run `shasum -a 256 -c SHA256SUMS.txt` in the download directory.
4. For a signed release, confirm `spctl --assess --type execute --verbose=4`
   accepts the installed application and `xcrun stapler validate` finds the
   notarization ticket.
5. Open the application, grant Automation, verify one block, request one
   temporary exception, and confirm Resume Blocking revokes it.

## Website download link

After the first signed release, use this URL for a permanent “Download for Mac” button:

```text
https://github.com/Sushmithamallesh/zen-garden/releases/latest/download/Zen-Garden.dmg
```

GitHub redirects that URL to the DMG attached to the newest non-prerelease version.
