#!/bin/zsh

# Publishes the notarized DMG to Stillmake/releases, then makes it live:
# the release history and in-app feed (../releases/$SLUG), the homepage
# (SITE_REPO, redeployed; skipped when empty), and the Homebrew cask
# (../homebrew-tap). Version/build come from the DMG Info.plist; release
# notes come from the newest ../releases/$SLUG/changelog.json entry, which
# must describe this DMG and be the only uncommitted change there.
# Full flow: RELEASE.md.
#
# Usage:
#   ./scripts/release.sh
#
# The DMG (APP_NAME.dmg in the project root) is the single source of truth:
# it is mounted to read the .app's Info.plist for version info, then
# uploaded as-is.

SLUG="__SLUG__"
APP_NAME="__APP__"
SITE_REPO="__SITE_REPO__"
RELEASE_REPO="Stillmake/releases"
ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
RELEASES_DIR="$ROOT_DIR/../releases"
TAP_DIR="$ROOT_DIR/../homebrew-tap"

DMG_NAME="$ROOT_DIR/$APP_NAME.dmg"
if [ ! -f "$DMG_NAME" ]; then
  echo "Error: $APP_NAME.dmg not found in project root."
  exit 1
fi

MOUNT_POINT="$ROOT_DIR/DebugArtifacts/release-dmg"
NOTES_FILE="$ROOT_DIR/DebugArtifacts/release-notes.md"
mkdir -p "$MOUNT_POINT"
ATTACH_OUTPUT=$(hdiutil attach "$DMG_NAME" -mountpoint "$MOUNT_POINT" -nobrowse -quiet 2>&1)
if [ $? -ne 0 ]; then
  echo "Error: Failed to mount $DMG_NAME"
  echo "$ATTACH_OUTPUT"
  rmdir "$MOUNT_POINT" 2>/dev/null
  exit 1
fi

cleanup() {
  hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null
  rmdir "$MOUNT_POINT" 2>/dev/null
  rm -f "$NOTES_FILE" 2>/dev/null
}
trap cleanup EXIT

PLIST_PATH="$MOUNT_POINT/$APP_NAME.app/Contents/Info.plist"
if [ ! -f "$PLIST_PATH" ]; then
  echo "Error: Info.plist not found inside mounted DMG at $PLIST_PATH"
  exit 1
fi

SHORT_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$PLIST_PATH")
BUILD_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$PLIST_PATH")

if [ -z "$SHORT_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
  echo "Error: Could not read version info from $PLIST_PATH"
  exit 1
fi

TAG="$SLUG-$SHORT_VERSION-$BUILD_VERSION"

if gh release view "$TAG" --repo "$RELEASE_REPO" >/dev/null 2>&1; then
  echo "Error: Release '$TAG' already exists in $RELEASE_REPO."
  echo "Bump CFBundleVersion/CFBundleShortVersionString or delete the existing release first."
  exit 1
fi

# ../releases is pushed below, so it must hold exactly what this release
# adds: level with origin, the new changelog entry its only change.
if ! git -C "$RELEASES_DIR" fetch -q origin main; then
  echo "Error: Failed to fetch origin/main in $RELEASES_DIR"
  exit 1
fi
if [ "$(git -C "$RELEASES_DIR" rev-parse HEAD)" != "$(git -C "$RELEASES_DIR" rev-parse origin/main)" ]; then
  echo "Error: ../releases must be level with origin/main."
  exit 1
fi
if [ "$(git -C "$RELEASES_DIR" status --porcelain)" != " M $SLUG/changelog.json" ]; then
  echo "Error: ../releases must have exactly one change: the new entry in $SLUG/changelog.json."
  exit 1
fi

COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# The newest changelog entry is both the check and the release body.
if ! node -e '
  const [entry] = require(process.argv[1]);
  if (`${entry.version} (${entry.build})` !== process.argv[2]) {
    console.error(`Error: changelog.json leads with ${entry.version} (${entry.build}), not ${process.argv[2]}.`);
    process.exit(1);
  }
  const sections = entry.notes.map((n) => `### ${n.title}\n\n${n.items.map((i) => `- ${i}`).join("\n")}`);
  console.log([`Release ${entry.version} (${entry.build})`, `Commit: ${process.argv[3]}`, ...sections].join("\n\n"));
' "$RELEASES_DIR/$SLUG/changelog.json" "$SHORT_VERSION ($BUILD_VERSION)" "$COMMIT_HASH" > "$NOTES_FILE"; then
  exit 1
fi

echo "App: $APP_NAME"
echo "Tag: $TAG"
echo "DMG: $DMG_NAME"
echo "Commit: $COMMIT_HASH"

# DMG first, feed second: a running app must never be offered a build whose
# download is not up yet.
if ! gh release create "$TAG" \
  "$DMG_NAME" \
  --repo "$RELEASE_REPO" \
  --title "$APP_NAME $SHORT_VERSION ($BUILD_VERSION)" \
  --notes-file "$NOTES_FILE" \
  --target main; then
  echo "Failed to create release."
  exit 1
fi
echo "Release $TAG created in $RELEASE_REPO."

node "$RELEASES_DIR/scripts/feed.mjs" "$SLUG" "$APP_NAME.dmg" || exit 1
git -C "$RELEASES_DIR" add "$SLUG/changelog.json" "$SLUG/version.json" || exit 1
git -C "$RELEASES_DIR" commit -q -m "$SLUG: $SHORT_VERSION ($BUILD_VERSION)" || exit 1
if ! git -C "$RELEASES_DIR" push -q origin main; then
  echo "Error: Failed to push the feed to $RELEASE_REPO."
  exit 1
fi
echo "Feed is live."

if [ -n "$SITE_REPO" ]; then
  if gh workflow run deploy.yml --repo "$SITE_REPO" --ref main; then
    echo "Site deploy dispatched in $SITE_REPO."
  else
    echo "Error: Failed to dispatch the site deploy in $SITE_REPO."
    exit 1
  fi
fi

# bump.sh mounts the DMG itself, and a second attach of a mounted image fails.
hdiutil detach "$MOUNT_POINT" -quiet
"$TAP_DIR/scripts/bump.sh" "$SLUG" "$DMG_NAME" || exit 1
