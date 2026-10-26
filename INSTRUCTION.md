# Stillmake release flow: adopting it

Reference for moving a Stillmake macOS app onto the shared release flow. The pieces below are independent: adopt any subset, in any order, and adapt what doesn't fit. When something here doesn't match the project, prefer what the project actually does, note the difference, and keep going.

The flow: notarized DMGs as GitHub releases on `Stillmake/releases`, history and in-app feed in `<slug>/` there, a Homebrew cask in `Stillmake/homebrew-tap`, and optionally a homepage built from `Stillmake/releases`. `../releases` and `../homebrew-tap` are checked out next to the source repo.

Code to read: `templates/release.sh` (the stages), `templates/RELEASE.md` (the per-app page), `templates/cask.rb`, `scripts/feed.mjs`, `../homebrew-tap/scripts/bump.sh`.

## The only hard rule

Nothing points at a DMG until it is published: not the feed, the cask, or the site. `release.sh` enforces this. Everything else, including names, paths and stages, is a default.

## Inputs, with defaults

| Input | Default | Where to look |
|---|---|---|
| App name | product name | `PRODUCT_NAME`, the DMG's `.app` |
| slug | app name, lowercased | names `<slug>/`, tags `<slug>-{version}-{build}`, the cask |
| Bundle ID, min macOS | — | Release build settings, or the DMG's Info.plist |
| Homepage repo | none | a site link in the project; a cask `homepage` that is a GitHub repo is not a site |
| History | none | a legacy feed or existing GitHub releases with notes; source tags and casks carry no notes |
| Legacy updater feed | none | the app's current update checker |

Make a reasonable choice for anything missing and say what you chose. Ask only when the choice would publish something the user can't take back.

## Pieces

**History.** Copy any existing history into `<slug>/changelog.json`, newest first: `{ "version", "build", "notes": [{ "title", "items" }] }`. Don't invent entries. With no history, the first release's entry starts the file. Add a row to `README.md`. `version.json` is generated, never hand-written.

**Release script.** Copy `templates/release.sh` to `scripts/release.sh` (executable) and `templates/RELEASE.md` to `RELEASE.md`. Fill in `__SLUG__`, `__APP__` and `__SITE_REPO__` (empty if there is no site); `CASK` and the DMG path have defaults to override. Trim `RELEASE.md` to what applies.

**Cask.** Write `../homebrew-tap/Casks/<slug>.rb` from `templates/cask.rb`. Its URL only resolves for builds on `Stillmake/releases`, so don't push it before the first release is up. Leave the version and sha256 as they are or as placeholders; the `cask` stage fills them in from the DMG, then commits and pushes. Remove `auto_updates true` if the app has no updater. Homebrew then owns the version, and `brew upgrade` is how users get updates; the cask is the update channel. Without a homepage, use `https://github.com/Stillmake/releases`.

**In-app updater** (if the app has one). Read `https://raw.githubusercontent.com/Stillmake/releases/main/<slug>/version.json`. Decode the changelog shape plus an optional `url`, and download that `url` as-is. Entries without `url` predate this repo and can't be installed.

**Homepage** (if any). Build from `$RELEASES_DIR/<slug>/`: a sibling checkout locally, or a second `actions/checkout` of `Stillmake/releases` in CI. Give `deploy.yml` a `workflow_dispatch` trigger.

**Bridge** (only when shipped builds read a legacy update feed). Shipped builds never see `Stillmake/releases`. Once, by hand, publish the first build whose updater reads the new feed on the legacy channel too. Keep the legacy feed afterwards.

## Releasing

Follow `RELEASE.md` and run `./scripts/release.sh`. Stages are idempotent, so after a failure, fix the cause and re-run the `--only` command the script prints.
