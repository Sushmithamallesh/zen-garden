# Releasing Zen Garden

Zen Garden ships directly through GitHub Releases. A release contains:

- `Zen-Garden.dmg` for normal drag-to-Applications installation
- `Zen-Garden.zip` as a compact alternative
- `SHA256SUMS.txt` for download verification

## Publish a version

1. Update `CFBundleShortVersionString` and `CFBundleVersion` in `Info.plist`.
2. Run `./scripts/test-core.sh` and `./scripts/build-app.sh`.
3. Commit and push the release changes.
4. Create a tag matching the app version and push it:

   ```sh
   git tag v0.3.0
   git push origin v0.3.0
   ```

The release workflow tests the app, builds a universal macOS bundle, packages the downloads, and publishes them to GitHub.

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

With all five values present, the workflow signs with hardened runtime, submits the app to Apple's notary service, staples the result, verifies it with Gatekeeper, and publishes a normal release.

## Website download link

After the first signed release, use this URL for a permanent “Download for Mac” button:

```text
https://github.com/Sushmithamallesh/zen-garden/releases/latest/download/Zen-Garden.dmg
```

GitHub redirects that URL to the DMG attached to the newest non-prerelease version.
