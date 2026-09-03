# `setup-jup` fixtures

These test projects each pin one package manager and one dependency. The
[test workflow](../workflows/test.yml) installs them from a relative working
directory, like packages in a monorepo.

Unpinned projects are created in `RUNNER_TEMP` instead, so that nothing landing
at this repository's root can start answering for them.

Two fixtures carry a marker a real repository would not need. A nested directory
is not a separate project to pnpm or to Yarn: pnpm installs at the nearest
`pnpm-workspace.yaml` at or above it, and Yarn refuses a package that is not
listed in an outer project's workspaces. The empty `pnpm-workspace.yaml` and the
empty `yarn.lock` keep each fixture the root of its own install regardless of
what sits above it. The `.yarnrc.yml` beside the lockfile turns off the
immutable install Yarn performs whenever `CI` is set, which an empty lockfile
cannot satisfy. Everything else a manager writes here is gitignored.
