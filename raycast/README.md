# Zen Garden for Raycast

These dependency-free Script Commands invoke Zen Garden through its local
`zengarden://` URL scheme. They do not read or modify Zen Garden preferences
directly.

## Install

1. Install and launch Zen Garden once so macOS registers the URL scheme.
2. In Raycast, open **Settings → Extensions → Add Directories**.
3. Choose this `raycast` folder.

Raycast will discover:

- **Unblock a Website** — opens the required reason form
- **Resume Blocking** — ends active exceptions immediately
- **Open Zen Garden** — opens the full app

## Troubleshooting

If a command does nothing, open Zen Garden normally once and try again. You can
also test the URL scheme from Terminal:

```sh
open "zengarden://open"
open "zengarden://request-break"
open "zengarden://resume"
```

`Unblock a Website` opens the app's form; it cannot bypass the required reason
or the Sunday Twitter lock. `Resume Blocking` only ends active temporary
exceptions—it does not stop the daily schedule or a manual focus session.
