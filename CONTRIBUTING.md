# Contributing

Thanks for helping improve Zen Garden.

## Before opening a pull request

1. Open an issue for substantial features or behavior changes.
2. Keep the app local-first and dependency-free unless a dependency has a clear,
   reviewed benefit.
3. Preserve the narrow browser-permission model and document any new permission.
4. Match the existing SwiftUI design system in `Theme.swift`.
5. Add or update tests for behavior changes.

Run the checks locally:

```sh
./scripts/test-core.sh
./scripts/build-app.sh
```

Pull requests should explain the user-facing change, notable tradeoffs, and how
the change was tested. Include a screenshot for visible interface changes.

For vulnerabilities, follow [SECURITY.md](SECURITY.md) instead of opening a
public issue.
