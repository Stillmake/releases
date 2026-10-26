// Writes <app>/version.json, an app's in-app update feed, as the newest
// entries of <app>/changelog.json, its full history (an array, newest
// first). Edit only the changelog. Each entry published here as <app>-{version}-{build} gets the
// `url` of its <asset>, which the app downloads as-is; entries released
// before this repo existed get none. With --check, fails when the
// committed feed is not what the changelog produces.
//
// Usage: bun scripts/feed.mjs <app> <asset> [--check]
import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const repo = "Stillmake/releases";
const [app, asset] = process.argv.slice(2).filter((arg) => !arg.startsWith("--"));
if (!app || !asset) {
  console.error("Usage: bun scripts/feed.mjs <app> <asset> [--check]");
  process.exit(1);
}
const appDir = join(dirname(fileURLToPath(import.meta.url)), "..", app);
const feedPath = join(appDir, "version.json");

const changelog = JSON.parse(readFileSync(join(appDir, "changelog.json"), "utf8"));
if (!Array.isArray(changelog) || changelog.length === 0) {
  console.error(`${app}/changelog.json must be a non-empty array, newest first.`);
  process.exit(1);
}
const published = new Set(
  JSON.parse(
    execFileSync("gh", ["release", "list", "--repo", repo, "--limit", "1000", "--json", "tagName"], { encoding: "utf8" })
  ).map((release) => release.tagName)
);
// Same shape as the full history, so any app reads it; one behind more
// releases than this sees notes for the newest only.
const releases = changelog.slice(0, 6).map((entry) => {
  const tag = `${app}-${entry.version}-${entry.build}`;
  return published.has(tag)
    ? { ...entry, url: `https://github.com/${repo}/releases/download/${tag}/${asset}` }
    : entry;
});
if (!releases[0].url) {
  console.error(`${app}-${releases[0].version}-${releases[0].build} is not published in ${repo}; publish it before its feed entry.`);
  process.exit(1);
}
const feed = JSON.stringify(releases, null, 2);

if (process.argv.includes("--check")) {
  let committed = "";
  try {
    committed = readFileSync(feedPath, "utf8");
  } catch {}
  if (committed !== feed) {
    console.error(`${app}/version.json is out of date with ${app}/changelog.json.`);
    process.exit(1);
  }
} else {
  mkdirSync(dirname(feedPath), { recursive: true });
  writeFileSync(feedPath, feed);
  console.log(`Wrote the ${releases.length} newest releases to ${app}/version.json`);
}
