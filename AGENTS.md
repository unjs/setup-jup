# setup-jup maintainer guide

This repository is one composite action. `action.yml` is the product; everything
else tests or documents it.

**MUST**, **MUST NOT** and **SHOULD** carry RFC 2119 meanings. They mark real
invariants, not house style.

## Relationship to jup

The action installs jup from the npm registry and never from a checkout, so this
repository holds no jup source and pins no jup version beyond the `jup-version`
input's `latest` default. Its floor is jup **0.5.2**, where `info --json` gained
the `inputs` array; the "Read the project" step fails with that message rather
than guessing a cache key.

`action.yml` MUST use only jup's public commands — the ones documented under
[commands](https://jup.unjs.io/commands) — plus `info --json` and
`info --store-path`. Comments cite jup's internal spec as `§NN.N`; those sections
live in `.agents/` in [unjs/jup](https://github.com/unjs/jup) and are the
authority for the behaviour being relied on.

## Rules for `action.yml`

- Inputs MUST reach `run:` scripts through `env:`, never through expression
  interpolation.
- The `JUP_HOME` cache MUST NOT carry `self/`. `self-install` writes a
  digest-checked copy of jup there on every run, and restoring cached bytes over
  it would replace what this run verified with whatever the newest key sharing
  the prefix held. `actions/cache` resolves `path` patterns with
  `implicitDescendants: false`, so the exclusion has to be written against the
  children — `<home>/*` with `!<home>/self` — because a bare directory matches
  one entry and a negation has nothing to subtract from it.
- Third-party actions MUST be pinned by commit digest with the version in a
  trailing comment.
- Keep the inputs, outputs and defaults in step with `README.md` and with
  jup's `docs/3.actions.md`.

## Tests

`.github/workflows/test.yml` runs the action against the projects in
`.github/fixtures` and against temporary unpinned projects in `RUNNER_TEMP`. It
uses the published jup release, so it also runs weekly: a jup release can change
what this action does without a commit here.

Its `cache-paths` job runs no jup at all. It saves and restores a
`JUP_HOME`-shaped fixture through the same pinned `actions/cache` release that
`action.yml` uses, holding the exclusion rule above down against a version bump.
Both pins MUST move together.

## Releases

Publish `vX.Y.Z` from the GitHub Releases page, creating the tag on publish.
Treat a change to an existing input, default or output as at least a minor
release.

Then move the short tags by hand, once the release's `test` run is green:

```sh
git fetch --tags
git tag -f v1 v1.2.0
git tag -f v1.2 v1.2.0
git push -f origin v1 v1.2
```

Move a short tag only when the release is the newest one under it. A patch
released behind an existing line -- `v1.4.5` cut after `v1.5.0` -- owns `v1.4`,
but moving `v1` to it would walk every `@v1` consumer backwards.

No workflow does this. The short tags are the ones that move under people who
already wrote `@v1`, and four commands a few times a year are cheaper to reason
about than a job with a token that can rewrite them. The `tags` ruleset keeps
`refs/tags/v*.*.*` immutable for the same reason; `v1` and `v1.2` sit outside it
because moving them is the point.
