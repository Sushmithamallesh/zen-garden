# Privacy

Zen Garden is designed to work without an account, analytics, advertising, or
a network service.

## What stays on your Mac

Zen Garden stores the following in your macOS user preferences:

- your blocked website list;
- focus schedules and daily blocking times;
- the current manual-session boundary; and
- temporary-access requests, including their domains, durations, and reasons.

Access-request records are automatically removed after 90 days. Zen Garden
does not send this information anywhere.

## Browser access

While focus is active, Zen Garden uses macOS Automation to read only the URL of
the active tab in the frontmost supported browser. It uses that URL to decide
whether the tab should be redirected to the local block page.

Zen Garden does not collect or retain browsing history. It does not inspect
background tabs, page contents, passwords, cookies, or form data.

The app does not request Screen Recording or Accessibility permission.

## Launch at login

Zen Garden registers a standard macOS login item so schedules can work after
you sign in. This can be disabled from Zen Garden Settings at any time.

## Removing your data

Quit Zen Garden, then run the following command in Terminal to remove its local
preferences:

```sh
defaults delete com.sushmithamallesh.zengarden
```

You can separately revoke browser access under **System Settings → Privacy &
Security → Automation** and remove the app from Applications.

Questions and corrections can be opened as a
[GitHub issue](https://github.com/Sushmithamallesh/zen-garden/issues).
