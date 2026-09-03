# setup-jup

Set up Node.js, a package manager, and dependencies in one step, from your
project's own pins, with [jup](https://jup.unjs.io).

```yaml
- uses: actions/checkout@v6
- uses: unjs/setup-jup@v1
- run: pnpm test
```

That replaces `actions/setup-node` and `corepack enable`. The action reads your
project pins, installs the matching Node.js and package manager, verifies and
caches both, and installs dependencies.

The action needs `node` on `PATH` to start; GitHub-hosted runners already have
it. jup then installs the Node.js version your project asks for.

## Versioning

`unjs/setup-jup@v1` tracks the latest v1 of **this action**. `@v1.2` stays on a
minor line, and a full tag such as `@v1.2.0` is fixed.

The action's version is not jup's. Pin the tool with `jup-version`:

```yaml
- uses: unjs/setup-jup@v1
  with:
    jup-version: 0.5.4
```

The default, `latest`, tracks jup's newest release. Use an exact version for
repeatable jobs. `setup-jup` requires jup 0.5.2 or newer.

## Examples

Choose a Node.js version and install dependencies yourself:

```yaml
- uses: unjs/setup-jup@v1
  with:
    node-version: 22
    install: false
- run: pnpm install --frozen-lockfile
```

Or pass the arguments through:

```yaml
- uses: unjs/setup-jup@v1
  with:
    install: --frozen-lockfile
```

Test more than one Node.js version:

```yaml
strategy:
  matrix:
    node-version: [22, 24]
steps:
  - uses: actions/checkout@v6
  - uses: unjs/setup-jup@v1
    with:
      node-version: ${{ matrix.node-version }}
  - run: pnpm test
```

Set up one package in a monorepo. jup searches parent directories, so the
package can use a pin from the root:

```yaml
- uses: unjs/setup-jup@v1
  with:
    working-directory: packages/app
```

## Inputs

| Name | Default | Meaning |
| --- | --- | --- |
| `node-version` | `lts` | A Node.js version, range, or tag. Project pins still win. An empty value uses jup's default. `lts/*` becomes `lts`; `node` and `current` become `latest`; a leading `v` is removed. |
| `jup-version` | `latest` | The jup npm version to install. Use an exact version for repeatable jobs. |
| `package-managers` | `auto` | Space-separated tools to shim. `auto` shims the full table, including bun and Deno. `none` shims no package manager. Node.js is always shimmed. |
| `cache` | `true` | Cache jup's store in `JUP_HOME`. |
| `cache-dependencies` | `true` | Cache the package manager's store. |
| `install` | `true` | Install dependencies. `false` skips this. Any other value is passed to the pinned manager. A project with no manager pin is not installed. |
| `working-directory` | `.` | The directory where jup starts project discovery. |

## Outputs

| Name | Meaning |
| --- | --- |
| `node-version` | The exact Node.js version selected by the project and jup. |
| `node-path` | The absolute path to the `node` shim. |
| `package-manager` | The pinned manager name, or an empty value. |
| `bin-directory` | The shim directory added to `PATH`. |
| `jup-home` | The `JUP_HOME` value used by later steps. |

## Job environment

Later steps receive a new first entry in `PATH` holding the jup shims, plus
`JUP_HOME` and `JUP_SHIM_DIRECTORY`. Values set by the caller are kept, and no
other variables are exported. Cache keys start with `setup-jup-`.

## Differences from `actions/setup-node`

| | `actions/setup-node` | `setup-jup` |
| --- | --- | --- |
| Version source | Action inputs | Action input, project pin, or jup default |
| `lts/*` | Uses an LTS name | Uses jup's `lts` tag |
| Package managers | Needs another setup step | jup verifies and shims the pinned manager |
| Dependencies | Needs another run step | Can run the pinned manager's install command |
| Integrity | Checks downloads | Also checks host signatures |
| `npm` | Uses the copy bundled with Node.js | Uses the project pin |
| `node` | Runs an extracted binary | Runs a shim that follows project pins |

`registry-url`, `scope`, `always-auth`, `mirror`, and problem matchers are not
supported. jup reads `.npmrc` for its own requests; see
[registries](https://jup.unjs.io/registry).

## Cache safety

Tools and dependencies are cached separately. `<JUP_HOME>/self` is never cached,
because the copy of jup there embeds a runner-specific Node.js path and is
re-verified on every run.

The jup cache key covers the host, the requested versions, and the contents of
every project file jup would consult. The dependency cache key covers lockfiles.

> [!WARNING]
> A restored `JUP_HOME` contains executable code. Do not share a release cache
> with untrusted fork jobs.

## Links

- [jup documentation](https://jup.unjs.io)
- [Project pins](https://jup.unjs.io/projects)
- [CI and offline use](https://jup.unjs.io/ci)

## License

[MIT](./LICENSE)
