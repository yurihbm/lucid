---
name: release
description: Tags the Lucid repo, which triggers CI to test and build an ad-hoc signed Release archive, publish a GitHub Release, and update the Homebrew tap. Use when the user asks to release, ship, publish, tag, or cut a new version of Lucid — e.g. "make a release", "ship v0.2.0", "publish a new build", "bump the version and release it".
---

# Releasing Lucid

## How it works

CI lives in `.github/workflows/`:

- `test.yml` — runs `xcodebuild test` on every push/PR to `main`.
- `release.yml` — runs on push of a `v*` tag. In order, it:
  1. Runs the test suite; a failing test aborts the release.
  2. Archives with `xcodebuild archive -configuration Release CODE_SIGN_IDENTITY=-` — ad-hoc signed (no paid Apple Developer account yet), which still applies the sandbox/hardened-runtime entitlements. `MARKETING_VERSION` is set from the tag, so `vX.Y.Z` ships as version `X.Y.Z`.
  3. Zips the `.app` out of the `.xcarchive` with `ditto`.
  4. Publishes a GitHub Release with the zip attached and auto-generated release notes.
  5. Updates `Casks/lucid.rb` in the [`yurihbm/homebrew-apps`](https://github.com/yurihbm/homebrew-apps) tap (version + sha256) and pushes, so `brew update` picks up the new version.

Both jobs run on the `xcode-27` GitHub-hosted runner label (arm64 only, currently in public preview) — `macos-latest` doesn't have Xcode 27 yet, which this project's `project.pbxproj` format requires.

The Homebrew-cask-update step needs write access to a different repo (`homebrew-apps`), so it authenticates with `secrets.HOMEBREW_TAP_TOKEN` — a fine-grained PAT scoped only to that repo (`Contents: Read and write`) — via the `main` GitHub Environment. That environment's "Deployment branches and tags" rule is restricted to the `v*` tag pattern (not the `main` branch), since this job only ever runs on tag pushes.

## Steps to cut a release

1. **Check for work in progress before touching anything.** The release requires checking out `main`, so first inspect the current state (on whatever branch the user is on):
   ```sh
   git status --porcelain=v2 --branch
   git fetch origin
   ```
   Also check `.git/` for `MERGE_HEAD`, `rebase-merge/`, `rebase-apply/`, `CHERRY_PICK_HEAD`, `REVERT_HEAD`, or `BISECT_LOG`.

   If any of the scenarios below apply, **stop, tell the user exactly what you found (branch, files, commits), and ask how to proceed**. Never pick an option on your own, and never rely on `git checkout` silently carrying uncommitted changes over to `main`.

   | Scenario | Options to offer |
   |---|---|
   | Uncommitted changes (staged, unstaged, or untracked files), on `main` or any other branch | **Stash** (`git stash push -u -m "wip before release"`), **commit** on the current branch, **discard**, or **stop the release** |
   | A merge, rebase, cherry-pick, revert, or bisect is in progress | Let the user finish or abort it themselves, or **stop the release**. Don't finish or abort it for them. |
   | On another branch with commits not in `origin/main` | Remind the user that those commits **won't be in the release**. Options: **continue anyway** (the branch stays as-is), or **stop** so they can merge it first |
   | Local `main` has unpushed commits (ahead of `origin/main`) | Pushing the tag would ship commits that were never pushed to `main` or tested by `test.yml`. Options: **push `main` first** (wait for `test.yml` to pass), or **stop**. |
   | Local `main` diverged from `origin/main` | **Stop.** The user has to reconcile it. |

   Notes on each option:
   - **Commit:** a commit on a branch other than `main` still won't be in the release. A commit on `main` must be pushed (and pass `test.yml`) before tagging. Say this when offering the option.
   - **Discard:** destructive. List exactly what will be lost (`git status`, `git diff --stat`, untracked files), then get explicit confirmation before running `git restore --staged --worktree .` / `git clean -fd`.
   - **Stash:** after the release, remind the user to go back to their branch and run `git stash pop`. If they were on another branch, tell them its name.

   Once the working tree is clean and there are no blockers, sync to the latest `main`:
   ```sh
   git checkout main
   git pull --ff-only origin main
   ```

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
