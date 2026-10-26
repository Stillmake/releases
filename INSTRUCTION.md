# Stillmake release flow

You are working in a Stillmake macOS app's source repo. Move this app onto the shared release flow, or, if it is already on it, bring it level with `templates/`. The flow: notarized DMG on `Stillmake/releases`, history and in-app feed in `<slug>/` there, Homebrew cask in `Stillmake/homebrew-tap`, and, if the app has one, a homepage rebuilt from `Stillmake/releases`.

`../releases` (this repo) and `../homebrew-tap` are sibling checkouts of the source repo. Everything you need is in them; do not look for, or ask about, any other app's repo. Read first:

- `../releases/README.md`
- `../releases/templates/release.sh`, `RELEASE.md`, `cask.rb`
- `../releases/scripts/feed.mjs`
- `../homebrew-tap/scripts/bump.sh`

## Inputs

Read these from the project; ask the user only for what it cannot tell you, then confirm the whole set once before editing:

- **App name**: the `.app` and `.dmg` basename (the product name).
- **slug**: the app name lowercased. It names `../releases/<slug>/`, the tag prefix `<slug>-{version}-{build}`, and the cask `Casks/<slug>.rb`.
- **Bundle identifier** and **minimum macOS**, from the build settings.
- **Homepage repo**: optional; many apps have none. Look for an existing cask's `homepage` or a site link in the project before asking.
- **Legacy channel**: the feed URL and download URL pattern shipped builds use today, from the app's current update checker or existing cask; none if there is neither.

For an app already on the flow, do only the steps where it differs from `templates/`, and skip step 6.

## Steps

1. **History.** Create `../releases/<slug>/changelog.json`: every past release, newest first, each `{ "version", "build", "notes": [{ "title", "items" }] }`, copied from the legacy feed or GitHub releases. Do not invent versions. Do not write `version.json`; `scripts/feed.mjs` generates it at the first release. Add the app's row to the table in `../releases/README.md`.

2. **In-app updater.** Point the app's update check at `https://raw.githubusercontent.com/Stillmake/releases/main/<slug>/version.json`. Decode the `changelog.json` shape plus an optional `url`, and download that `url` as-is; never build a download path. An entry without `url` predates `Stillmake/releases` and is never offered for install. If the app has no updater, skip this and say so.

3. **Release script.** Copy `templates/release.sh` to `scripts/release.sh` (executable) and `templates/RELEASE.md` to `RELEASE.md`, filling `__SLUG__`, `__APP__` and `__SITE_REPO__` (empty without a homepage). Without a homepage, also drop the homepage lines from `RELEASE.md`.

4. **Cask.** Create or rewrite `../homebrew-tap/Casks/<slug>.rb` from `templates/cask.rb`. Fill version, build and sha256 with the build currently shipped; `bump.sh` maintains them from then on. Without a homepage, `homepage` is `https://github.com/Stillmake/releases`. Drop `auto_updates true` when the app has no updater.

5. **Homepage (optional).** In the homepage repo, read release data from `$RELEASES_DIR/<slug>/` (a sibling checkout locally, a second `actions/checkout` of `Stillmake/releases` into `.releases` in CI) instead of its own copy, and give its `deploy.yml` workflow `workflow_dispatch` so `release.sh` can trigger it. Remove the copy only once the site builds from `Stillmake/releases`.

6. **Bridge (only with a legacy channel).** Builds already shipped read the old feed and will never see `Stillmake/releases`. The first release whose updater reads `Stillmake/releases` must also be published on the legacy channel, once, by hand: the same DMG under the legacy download pattern, and its entry at the top of the legacy feed. Do not add this to `release.sh`. Keep the legacy feed and its releases afterwards; old installs still read them.

## Handover

Do not publish anything. Leave every repo with uncommitted or committed-but-unpushed changes, list them per repo, and tell the user the next release is `./scripts/release.sh` per the new `RELEASE.md`, plus step 6 if it applies.
