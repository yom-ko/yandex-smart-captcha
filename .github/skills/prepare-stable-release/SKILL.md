---
name: prepare-stable-release
description: >-
  Prepare a stable release of this Flutter package: review changes, choose a version, update release
  files, verify, and stage them. Use when asked to prepare a release or bump the package version.
---

# Preparing a stable release

## Main rules

- Run commands from the repository root unless noted. Prepare stable releases only.
- Require a clean working tree and index. If dirty, stop and ask; never discard or include unrelated
  work.
- Change only release metadata and docs. Ask before code fixes, dependency upgrades, or CI or
  publishing changes.
- Stage verified release changes and stop. Commit, tag, push, publish, or create a remote release
  only with explicit authorization.
- Annotate new tags on the release commit and never rewrite tags. Pushing a tag can trigger publishing to pub.dev.
  Never bypass checks or use `--skip-validation`.

## 1. Find the previous release

```bash
git status --short --branch
git fetch --tags
git describe --tags --abbrev=0 --match 'v[0-9]*.[0-9]*.[0-9]*'
```

- `--tags` includes lightweight tags; the glob is not SemVer validation. Confirm a stable
  `vMAJOR.MINOR.PATCH` tag matching the latest stable version on
  [pub.dev](https://pub.dev/packages/yandex_smart_captcha), `pubspec.yaml`, and the top
  `CHANGELOG.md` entry. If unverified or inconsistent, stop and ask.
- Check the tag trigger and gate in `.github/workflows/publish.yml`. A matching tag starts the
  workflow but does not guarantee publication. Report unverified pub.dev publishing settings.

## 2. Review the changes

```bash
git --no-pager log --reverse --format='%h %s' <last-tag>..HEAD
git --no-pager diff --name-status <last-tag>..HEAD
```

Inspect every commit and relevant diffs, not just messages: use `git --no-pager show <commit> -- <path>`
or `git --no-pager diff <last-tag>..HEAD -- <path>`. Include code, metadata, docs, platform behavior,
and examples. Tests and CI are supporting evidence. Examples may ship but are not public API. Never
print secrets.

## 3. Choose the next version

For `X.Y.Z`, use the highest-impact change:

| Change | Examples | Bump |
| --- | --- | --- |
| Breaking | Incompatible API or behavior; removal of deprecated API or a supported platform | Major: increment `X`, reset `Y` and `Z` |
| Feature | Backward-compatible API additions, platform support, or deprecations | Minor: increment `Y`, reset `Z` |
| Fix | Backward-compatible bug or documentation fixes | Patch: increment `Z` |

- For internal or example-only changes, prepare a patch maintenance release only if the user
  explicitly confirms it.
- Treat SDK minimum increases as breaking, as this project does. Ask if the impact is unclear.

## 4. Update the release files

1. Update the version in `pubspec.yaml`; check SDK constraints, dependencies, and platforms.
2. Add a top `CHANGELOG.md` entry in the existing style. List user-facing changes first; mark
   breaking changes with `**BREAKING CHANGE:**` and explain details and migration if they are not obvious.
3. Update `README.md` and Dartdoc as needed. Briefly note significant example or internal changes.
   Omit agent-context changes.

## 5. Verify

1. Read `.github/workflows/main.yml`. Run its applicable latest-SDK checks locally with the current
   flags, including `./build-agent-context.sh --check`; record SDK versions. Find the run for `HEAD`
   with `gh run list --commit <HEAD-sha> --workflow main.yml` and confirm that all its jobs passed
   with `gh run view <run-id> --verbose --exit-status`.
2. If the minimum-SDK CI job for `HEAD` is unavailable, or the release edits change SDK constraints
   or dependencies, run that job's steps from `main.yml` locally in an isolated lane with the exact
   minimum Flutter version. See the `audit-sdk-constraints` skill for lane setup.
3. Run `dart format --output=none --set-exit-if-changed` on existing Dart files changed since the
   last tag or in the release edits. If example code changed, run relevant example tests (see
   `example/README.md`). Browser tests must execute.
4. Run `flutter pub publish --dry-run` in the release working tree. Inspect the complete list for
   required `lib/` files, assets, `LICENSE`, `README.md`, `CHANGELOG.md`, and `pubspec.yaml`; exclude
   secrets, local configuration, build outputs, and other unintended files. A `.pubignore`
   overrides `.gitignore` only in the same directory.
5. Investigate every warning. Only a modified checked-in files warning listing exclusively intended
   release changes is acceptable: Pub runs this Git check in dry runs too. Check `git status` if
   the list is truncated.
6. If local checks fail or cannot run, or CI failed, report and stop. If CI is unavailable but
   equivalent local checks pass, report CI as unverified. Run `git --no-pager diff --check` and
   confirm that only intended release files changed.

## 6. Stage and report

Find the branch and upstream with `git branch --show-current` and
`git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'`. Before staging, confirm that
`git tag -l vX.Y.Z` prints nothing, `git ls-remote --exit-code --tags <remote> refs/tags/vX.Y.Z`
exits with `2` (no match; any other status means the tag exists or the check failed), and the
version is unused on pub.dev. If the destination or availability is unverified, stop and ask.

```bash
git add -- pubspec.yaml CHANGELOG.md  # plus any other intended release files
git --no-pager diff --cached --check
git --no-pager diff --cached --name-only
git --no-pager diff --cached
git --no-pager diff --exit-code --stat
git ls-files --others --exclude-standard
git status --short
```

Confirm that only release files are staged and no other changes remain. Report the versions and
bump rationale, change summary, staged files, and each check (`PASS`, `FAIL`, or `NOT RUN` with a
reason), including warnings and unverified settings. CI results for `HEAD` do not cover uncommitted
release edits.

Provide the finishing commands with the actual version, current branch, and upstream remote and
branch:

```bash
git commit -m "Bump version to X.Y.Z"
git tag -a vX.Y.Z -m "vX.Y.Z"
git push <remote> <local-branch>:<upstream-branch>
git push <remote> refs/tags/vX.Y.Z  # May publish to pub.dev.
```

## References

- [Flutter: Developing packages and plugins](https://docs.flutter.dev/packages-and-plugins/developing-packages)
- [Dart: Publishing packages](https://dart.dev/tools/pub/publishing)
- [Dart: `dart pub publish`](https://dart.dev/tools/pub/cmd/pub-lish)
- [Dart: Package versioning](https://dart.dev/tools/pub/versioning)
- [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html)
- [Dart: Automated publishing](https://dart.dev/tools/pub/automated-publishing)
- [Dart: Package layout conventions](https://dart.dev/tools/pub/package-layout)
- [Git: `git describe`](https://git-scm.com/docs/git-describe)
- [Git: `git ls-remote`](https://git-scm.com/docs/git-ls-remote)
- [GitHub CLI: `gh run`](https://cli.github.com/manual/gh_run)
