# Contributing an extension

This guide walks you through creating, validating, and publishing a Muxy extension.

The reference material for authors lives here in this docs set; the example and the
manifest schema live alongside it in this repository:

- Example extension: [`examples/hello-world`](examples/hello-world)
- Manifest schema: [`schema/manifest.schema.json`](schema/manifest.schema.json)

Published community extensions are hosted in the separate
[`muxy-app/extensions`](https://github.com/muxy-app/extensions) repository, which carries
the validation, packaging, and publishing tooling. You open a pull request there to
ship an extension to everyone.

## Prerequisites

- [Node.js](https://nodejs.org) 18 or newer.
- A Muxy installation to test against.

## 1. Start from the example

Copy the example as your starting point:

```bash
cp -r examples/hello-world my-extension
```

## 2. Edit the manifest

Open `my-extension/manifest.json` and update the fields. See the
[manifest reference](manifest.md) for every option, and the
[schema](schema/manifest.schema.json) for the authoritative contract.

## 3. Build your UI

Extensions are HTML/CSS/JS. The example includes a tab; adapt it or add panels,
popovers, palette commands, and more. See the rest of this docs set for each surface:

- [Overview](overview.md) — architecture, lifecycle, security model
- [Permissions](permissions.md) — request the minimum you need
- [Events](events.md), [Tabs](tabs.md), [Panels](panels.md), [Popovers](popovers.md)
- [Palette commands](palette-commands.md), [Topbar](topbar.md), [Status bar](statusbar.md)
- [Settings](settings.md), [Scripts](scripts.md), [Logs](logs.md)

## 4. Test in Muxy

Load your unpacked extension from Muxy's developer settings and iterate.

## 5. Validate and publish

To publish, fork the
[`muxy-app/extensions`](https://github.com/muxy-app/extensions) repository, drop your
extension into `extensions/<your-extension>/`, and run its tooling:

```bash
npm install
npm run validate
npm run pack -- my-extension
```

Then open a pull request against that repository. CI validates every submission; once
a maintainer approves and merges, the publish workflow signs and releases your
extension.

## Style and quality

- Keep bundles small. Avoid heavy frameworks where vanilla JS will do.
- Respect the user. Request the minimum permissions you need.
- Test on the latest Muxy release.

## Questions?

Open a discussion or issue. We're happy to help.
