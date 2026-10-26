// Writes <app>/version.json, an app's in-app update feed, as the newest
// entries of its changelog (an array, newest first). Edit only the
// changelog. With --check, fails when the committed feed is not what the
// changelog produces.
//
// Usage: node scripts/feed.mjs <app> <path/to/changelog.json> [--check]
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const [app, changelogPath] = process.argv.slice(2).filter((arg) => !arg.startsWith("--"));
if (!app || !changelogPath) {
  console.error("Usage: node scripts/feed.mjs <app> <path/to/changelog.json> [--check]");
  process.exit(1);
}
const feedPath = join(dirname(fileURLToPath(import.meta.url)), "..", app, "version.json");

const changelog = JSON.parse(readFileSync(changelogPath, "utf8"));
if (!Array.isArray(changelog) || changelog.length === 0) {
  console.error(`${changelogPath} must be a non-empty array, newest first.`);
  process.exit(1);
}
// Same shape as the full history, so any app reads it; one behind more
// releases than this sees notes for the newest only.
const releases = changelog.slice(0, 6);
const feed = JSON.stringify(releases, null, 2);

if (process.argv.includes("--check")) {
  let committed = "";
  try {
    committed = readFileSync(feedPath, "utf8");
  } catch {}
  if (committed !== feed) {
    console.error(`${app}/version.json is out of date with ${changelogPath}.`);
    process.exit(1);
  }
} else {
  mkdirSync(dirname(feedPath), { recursive: true });
  writeFileSync(feedPath, feed);
  console.log(`Wrote the ${releases.length} newest releases to ${app}/version.json`);
}
