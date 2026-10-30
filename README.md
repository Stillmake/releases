# Stillmake Releases

Notarized builds of Stillmake's macOS apps, and each app's release history.

| App | Releases | Homebrew |
|---|---|---|
| [Actor](https://stillmake.com/actor) | tags `actor-{version}-{build}` | `brew install --cask stillmake/tap/actor` |
| [Inline](inline/) | tags `inline-{version}-{build}` | `brew install --cask stillmake/tap/inline` |
| [LocalDictation](localdictation/) | tags `localdictation-{version}-{build}` | `brew install --cask stillmake/tap/localdictation` |
| [Moof](moof/) | tags `moof-{version}-{build}` | `brew install --cask stillmake/tap/moof` |
| [OwoX](owox/) | tags `owox-{version}-{build}` | `brew install --cask stillmake/tap/owox` |

Each release holds the app's DMG. Per app:

- `<app>/changelog.json` — the full release history, newest first. The only file edited by hand; the app's site renders it.
- `<app>/version.json` — the in-app update feed: the newest six changelog entries, written by `scripts/feed.mjs` and never edited by hand. Every entry released here carries the `url` of its DMG, which the app downloads as-is.

A release is published before its feed entry lands on `main`, so a running app is never offered a build whose DMG is not up yet.
