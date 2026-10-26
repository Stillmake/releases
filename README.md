# Stillmake Releases

Notarized builds of Stillmake's macOS apps.

| App | Releases | Homebrew |
|---|---|---|
| [Actor](https://stillmake.com/actor) | tags `actor-{version}-{build}` | `brew install --cask stillmake/tap/actor` |

Each release holds the app's DMG. `<app>/version.json` is that app's in-app update feed: the newest six entries of its changelog, written by `scripts/feed.mjs` and never edited by hand.

A release is published before its feed entry lands on `main`, so a running app is never offered a build whose DMG is not up yet.
