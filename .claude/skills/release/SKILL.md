---
name: release
description: Tags the Lucid repo, which triggers CI to build an unsigned Release archive, publish a GitHub Release, and update the Homebrew tap. Use when the user asks to release, ship, publish, tag, or cut a new version of Lucid — e.g. "make a release", "ship v0.2.0", "publish a new build", "bump the version and release it".
---

# Releasing Lucid

## How it works

CI lives in `.github/workflows/`:

- `test.yml` — runs `xcodebuild test` on every push/PR to `main`.
- `release.yml` — runs on push of a `v*` tag. In order, it:
  1. Archives with `xcodebuild archive -configuration Release CODE_SIGNING_ALLOWED=NO` — the same Release-optimized build that would ship to any store, just unsigned (no paid Apple Developer account yet).
  2. Zips the `.app` out of the `.xcarchive` with `ditto`.
  3. Publishes a GitHub Release with the zip attached and auto-generated release notes.
  4. Updates `Casks/lucid.rb` in the [`yurihbm/homebrew-apps`](https://github.com/yurihbm/homebrew-apps) tap (version + sha256) and pushes, so `brew update` picks up the new version.

Both jobs run on the `xcode-27` GitHub-hosted runner label (arm64 only, currently in public preview) — `macos-latest` doesn't have Xcode 27 yet, which this project's `project.pbxproj` format requires.

The Homebrew-cask-update step needs write access to a different repo (`homebrew-apps`), so it authenticates with `secrets.HOMEBREW_TAP_TOKEN` — a fine-grained PAT scoped only to that repo (`Contents: Read and write`) — via the `main` GitHub Environment. That environment's "Deployment branches and tags" rule is restricted to the `v*` tag pattern (not the `main` branch), since this job only ever runs on tag pushes.

## Steps to cut a release

1. **Sync to the latest `main`.** Releases must always be cut from the newest shared state, not a stale local branch:
   ```sh
   git checkout main
   git fetch origin
   git pull origin main
   ```
   If there's uncommitted work that isn't yours to discard, or local commits that diverge from `origin/main`, stop and ask before proceeding.

2. **Check whether the current commit already has a release.** Don't create a duplicate tag/release for a commit that's already shipped:
   ```sh
   git tag --points-at HEAD
   ```
   If this prints a tag, a release for `HEAD` already exists — confirm with `gh release view <tag> -R yurihbm/lucid`. If it does, tell the user there's nothing new to release (no commits since the last tag) and stop, unless they explicitly want to redo that exact release (see "Redoing a release" below).

3. Find the latest tag (`git tag -l --sort=-v:refname | head -1`) to figure out the next version. If the user gave an explicit version (e.g. `/release 0.2.0`) or a bump type (`patch`/`minor`/`major`), use that; otherwise default to a patch bump and confirm with the user before tagging — tagging triggers a public release and isn't easily undone.
4. Create and push the tag:
   ```sh
   git tag -m "Lucid vX.Y.Z" vX.Y.Z
   git push origin vX.Y.Z
   ```
5. Watch the workflow run: `gh run watch -R yurihbm/lucid` (or `gh run list -R yurihbm/lucid --limit 1` to find the run ID first).
6. On success, confirm the GitHub Release exists (`gh release view vX.Y.Z -R yurihbm/lucid`) and that the tap repo got the update commit (`gh api repos/yurihbm/homebrew-apps/commits --jq '.[0].commit.message'` should show `lucid X.Y.Z`).
7. Report the release URL back to the user.

## Redoing a release

If a release needs to be deleted and recreated (e.g. after fixing the workflow):

```sh
gh release delete vX.Y.Z --cleanup-tag --yes
git tag -m "Lucid vX.Y.Z" vX.Y.Z
git push origin vX.Y.Z
```
