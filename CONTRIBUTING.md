# Contributing

Thanks for helping improve Zen Garden.

## Development setup

Zen Garden is a Swift Package targeting macOS 13 or newer. Use Xcode 16 or a
Swift 6 toolchain:

```sh
git clone https://github.com/Sushmithamallesh/zen-garden.git
cd zen-garden
./scripts/test-core.sh
./scripts/build-app.sh
open "dist/Zen Garden.app"
```

## Before opening a pull request

1. Open an issue for substantial features or behavior changes.
2. Keep the app local-first and dependency-free unless a dependency has a clear,
   reviewed benefit.
3. Preserve the narrow browser-permission model and document any new permission.
4. Match the existing SwiftUI design system in `Theme.swift`.
5. Add or update tests for behavior changes.
6. Do not add analytics, remote fonts, or network services without prior discussion.

Run the checks locally:

```sh
./scripts/test-core.sh
./scripts/build-app.sh
```

Pull requests should explain the user-facing change, notable tradeoffs, and how
the change was tested. Include a screenshot for visible interface changes.

## Project conventions

- Domain, schedule, and exception rules live in testable model/store code.
- Browser-specific AppleScript stays inside `BrowserScriptClient`.
- Browser-provided strings must be treated as untrusted input and normalized
  before matching or interpolation.
- User-facing type, color, and surface tokens belong in `Theme.swift`.
- Bundled third-party assets must include their original license.

For browser changes, test at least Safari and one Chromium browser. Arc uses a
separate scripting style and should be checked whenever tab automation changes.

## Pull request checklist

- [ ] `git diff --check`
- [ ] `./scripts/test-core.sh`
- [ ] `./scripts/build-app.sh`
- [ ] New behavior has test coverage
- [ ] New permissions, stored data, limitations, and third-party assets are documented
- [ ] UI changes include light/dark-mode screenshots

For vulnerabilities, follow [SECURITY.md](SECURITY.md) instead of opening a
public issue.
