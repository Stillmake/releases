# Instruction

A prompt for an agent working in an app's source repo. It moves that app onto the shared release flow, or brings an app already on it back in line after the flow changes: notarized DMG on `Stillmake/releases`, history and in-app feed in `<app>/`, Homebrew cask in `Stillmake/homebrew-tap`, and, if the app has one, a homepage rebuilt from this repo.

Actor is the reference. Copy its shape and change only the names: `Stillmake/ActorTerm` `RELEASE.md` and `scripts/release.sh`, `ActorTerm/Models/UpdateChecker.swift`, `homebrew-tap/Casks/actor.rb`, and `Stillmake/ActorApp` `.github/workflows/deploy.yml` with `_data/release.js`.

---

## Prompt

Move this app onto the Stillmake release flow described in `../releases/README.md`, or, if it is already on it, bring it level with Actor's current files. For an app already on the flow, do only the steps where it differs from Actor, and skip step 6. `../releases`, `../homebrew-tap` and `../ActorTerm` are sibling checkouts; read Actor's files listed above before writing anything, and match them.

Ask the user for anything below you cannot read from the project, then confirm the whole set once before editing:

- **slug**: lowercase, e.g. `inline`. It names the folder `../releases/<slug>/`, the tag prefix `<slug>-{version}-{build}`, and the cask `Casks/<slug>.rb`.
- **App name**: the `.app` and `.dmg` basename, e.g. `Inline`.
- **Bundle identifier**, for the cask's `zap`.
- **Homepage repo**: optional. Many apps have none; then every homepage step below is skipped and the cask's `homepage` is `https://github.com/Stillmake/releases`.
- **Legacy channel**: where shipped builds look for updates today (a feed URL and a download URL pattern), or none.

Then, in order:

1. **History.** Create `../releases/<slug>/changelog.json`: every past release, newest first, each `{ "version", "build", "notes": [{ "title", "items" }] }`, copied from the legacy feed or GitHub releases. Do not invent versions. Do not write `version.json`; `scripts/feed.mjs` generates it at the first release. Add the app's row to the table in `README.md`.

2. **In-app updater.** Point the app's update check at `https://raw.githubusercontent.com/Stillmake/releases/main/<slug>/version.json`. Decode the same shape plus an optional `url`, and download that `url` as-is; never build a download path. An entry without `url` predates this repo and is never offered for install. If the app has no updater, skip this and say so.

3. **Release script.** Add `RELEASE.md` and `scripts/release.sh` from ActorTerm's, with `actor`, `Actor` and the repo names replaced. The order is fixed: DMG release on `Stillmake/releases`, then `feed.mjs <slug> <App>.dmg` and one commit `<slug>: {version} ({build})` with changelog and feed, then the homepage deploy dispatch, then `../homebrew-tap/scripts/bump.sh <slug> <App>.dmg`. Without a homepage repo, drop the `SITE_REPO` variable, the dispatch block and every homepage mention in `RELEASE.md`.

4. **Cask.** Create or rewrite `../homebrew-tap/Casks/<slug>.rb` from `actor.rb`: `version "x,build"`, `url` on `Stillmake/releases` via `version.csv`, `livecheck` on the feed, `auto_updates true` only when step 2 shipped an updater, `zap` from the bundle identifier. Keep `depends_on macos:` from the existing cask, or ask. `bump.sh` sets version and sha256 at release; leave both at the current shipped build.

5. **Homepage (optional).** In the homepage repo, read releases data from `$RELEASES_DIR/<slug>/` (a sibling checkout locally, a second `actions/checkout` of `Stillmake/releases` into `.releases` in CI) instead of its own copy, and give its deploy workflow `workflow_dispatch` so `release.sh` can trigger it. Remove the copy only once the site builds from this repo.

6. **Bridge (only with a legacy channel).** Builds already shipped read the old feed and will never see this repo. The first release whose updater reads `Stillmake/releases` must also be published on the legacy channel, once, by hand: the same DMG under the legacy download pattern, and its entry at the top of the legacy feed. Do not add this to `release.sh`. Keep the legacy feed file and its releases afterwards; old installs still read them.

Do not publish anything yourself. Leave every repo with uncommitted or committed-but-unpushed changes, list them per repo, and hand over with: the first release is `./scripts/release.sh` per the new `RELEASE.md`, plus step 6 if it applies.
