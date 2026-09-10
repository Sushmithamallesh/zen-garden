# Security review

Last reviewed: 2026-09-10  
Reviewed revision: `ec029b051e7e520320f036fff519b4d5e1d33d3e`

This is a source and build review of the public preview. It is not a penetration
test or a claim that Zen Garden is tamper-proof.

## Scope

- Swift application sources and bundled block page
- domain matching, schedules, temporary access, and URL-scheme commands
- browser AppleScript construction and browser-provided input handling
- local persistence and launch-at-login behavior
- app entitlements, build scripts, packaging, CI, and release automation
- executable dependencies, embedded credentials, and source-level network use

## Verified

- 21 core assertions and 19 store assertions pass.
- Production and warnings-as-errors debug builds succeed.
- Property lists validate and the built app passes strict code-seal verification.
- SwiftPM has no third-party dependencies; the binary links only Apple/system
  frameworks.
- No embedded credentials, analytics endpoint, backend, or application-initiated
  network endpoint was found.
- Browser bundle identifiers and script expressions are constants; domains are
  normalized before matching; the block page inserts the domain with
  `textContent`.
- URL-scheme commands open app UI or resume blocking; they do not grant an
  exception directly.

## Fixed during review

- Apple signing and notarization secrets are now scoped only to their required
  release steps.
- GitHub checkout is pinned to a reviewed full commit SHA and does not persist
  repository credentials.

## Known limitations

1. **Focus settings remain editable.** During active focus, a website can be
   disabled or removed and weekday/custom schedules can be weakened without
   entering a reason. The reason gate therefore covers temporary-access requests,
   not every way a user can change policy.
2. **URL polling has bypasses.** The blocker exempts local `file:` and HTML
   `data:` pages and does not unwrap every nested browser URL form. Wrapper pages,
   proxies, downloaded content, private profiles, and unsupported browsers may
   evade matching. Strong enforcement would require a browser extension or
   network-level component.
3. **Preview distribution is not publisher-authenticated.** v0.3.1 is ad-hoc
   signed and Gatekeeper rejects it until the user explicitly overrides the
   warning. A checksum hosted with the release detects corruption but is not an
   independent authenticity proof. Developer ID signing and notarization should
   be required before describing a release as trusted for one-click install.
4. **The app is not sandboxed.** The reviewed source is deliberately narrow, but
   macOS does not constrain the preview to those behaviors through App Sandbox.
5. **Reasons are local plain text.** Temporary-access reasons live in UserDefaults
   for up to 90 days, and input length is not currently capped.

These are tracked product and hardening gaps, not evidence of remote code
execution, privilege escalation, credential theft, or data exfiltration in the
reviewed source.

## Not verified

- live macOS Automation/TCC behavior across all six supported browsers
- Developer ID signing and notarization with production credentials
- execution on Intel hardware
- runtime network-traffic capture
- hostile or malformed responses from browser scripting interfaces

Please report a newly discovered vulnerability privately as described in
[SECURITY.md](../SECURITY.md).
