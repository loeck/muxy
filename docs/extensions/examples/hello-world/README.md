# hello-world

A minimal Muxy extension you can copy as a starting point. It registers one
palette command, **Hello World: Open**, which opens a theme-aware tab with a
button that fires a toast notification.

## Files

- `manifest.json` — declares the tab type, the command, and the listing metadata.
- `tabs/index.html` — the tab UI, using the injected `window.muxy` bridge.
- `tabs/styles.css` — styling driven entirely by Muxy theme variables.
- `assets/icon.svg` — the required listing icon.
- `assets/screenshot-1.png` — the required listing screenshot (1600×1000).

## Use it

1. Copy this folder as your starting point.
2. Rename it and set `manifest.name` to the same name.
3. Edit the UI and iterate.

See the [contributing guide](../../contributing.md) for the full
create → validate → publish flow, and the [extension docs](../../README.md)
for the complete `window.muxy` API.
