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

Tag a release `vX.Y.Z` and publish it to the Marketplace from its GitHub
release page. Treat a change to an existing input, default or output as at least
a minor release.

Moving the short `vX` and `vX.Y` tags is a separate, deliberate step: dispatch
`.github/workflows/release-tags.yml` with the release tag once its `test` run is
green. Nothing moves them automatically, and the job MUST stay behind the
`release-tags` environment's reviewers -- these are the tags that move under
people who already wrote `@vX`. It refuses prereleases and missing tags, and it
skips a release that is not the newest under its prefix unless `force` is set.
