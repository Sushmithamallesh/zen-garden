# Security policy

## Supported version

Security fixes are made against the latest release and the `main` branch.

## Security model

Zen Garden is a behavioral website blocker, not a security boundary. It polls
the active tab of the frontmost supported browser through macOS Automation and
redirects matching URLs. It is not a browser extension, network filter, VPN,
parental-control system, or anti-tampering tool.

The current public preview is ad-hoc signed, not notarized, and not App
Sandbox-enabled. Its reviewed source has no third-party executable dependencies,
analytics, backend, or application-initiated network requests. Those are source
properties, not restrictions enforced by an operating-system sandbox.

Expected bypasses include quitting the app, revoking Automation permission,
using an unsupported or private browser context, editing blocking settings, and
loading content through a URL form the active-tab matcher cannot identify.
These are product limitations unless they enable a materially different impact.

Temporary-access reasons are retained as plain text in the current macOS user's
preferences for up to 90 days. Do not put credentials or other secrets in them.

## Reporting a vulnerability

Please do not disclose a suspected vulnerability in a public issue. Use
[GitHub private vulnerability reporting](https://github.com/Sushmithamallesh/zen-garden/security/advisories/new)
and include:

- the affected version;
- steps to reproduce the problem;
- the impact you observed; and
- any suggested mitigation.

You should receive an initial response within seven days. A fix and disclosure
timeline will depend on the severity and complexity of the report.

The latest review scope, checks, known limitations, and unverified areas are in
[docs/SECURITY-REVIEW.md](docs/SECURITY-REVIEW.md).
