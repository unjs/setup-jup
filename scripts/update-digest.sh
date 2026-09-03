#!/bin/sh
# Repin the readme's examples to the newest release.
#
# `uses: unjs/setup-jup@<sha> # vX.Y.Z` is the pin this action asks of its own
# dependencies in `action.yml`, so it is the one the readme should be showing.
# The digest is the pin, because a tag can be moved and a commit cannot; the
# comment is there so a human reading the workflow knows what the digest means.
#
# Run it after publishing a release, then commit the readme.
#
#   scripts/update-digest.sh [remote]
#
# Reads the remote and rewrites one file. It fetches nothing into this clone and
# creates no commit, so it is safe to run against a dirty tree.
set -eu

cd "$(dirname "$0")/.."

remote="${1:-origin}"

# Straight from the remote, so a stale or missing local tag cannot answer.
refs="$(git ls-remote --tags "$remote" 'v*' 2>/dev/null || true)"
[ -n "$refs" ] || { echo "update-digest: no tags on '$remote'." >&2; exit 1; }

# `^{}` marks the commit an annotated tag points at. Strip it to rank the names,
# and keep it below to resolve one.
tag="$(printf '%s\n' "$refs" |
  sed 's|.*refs/tags/||; s|\^{}$||' |
  grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' |
  sort -V |
  tail -n1)"
[ -n "$tag" ] || { echo "update-digest: no stable release tag on '$remote'." >&2; exit 1; }

# Prefer the peeled entry: for an annotated tag the bare ref is the tag object,
# and pinning that would name something no runner can check out.
sha="$(printf '%s\n' "$refs" | awk -v r="refs/tags/$tag^{}" '$2 == r { print $1; exit }')"
[ -n "$sha" ] ||
  sha="$(printf '%s\n' "$refs" | awk -v r="refs/tags/$tag" '$2 == r { print $1; exit }')"
[ -n "$sha" ] || { echo "update-digest: could not resolve $tag." >&2; exit 1; }

# Only `uses:` lines. The prose says what the convention is and must not have a
# digest substituted into the middle of a sentence.
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
sed -E "s|(uses: unjs/setup-jup@)[^[:space:]]+([[:space:]]+#.*)?\$|\1$sha # $tag|" \
  README.md > "$tmp"

if cmp -s README.md "$tmp"; then
  echo "update-digest: README.md is already at $tag ($sha)."
  exit 0
fi

cat "$tmp" > README.md
echo "update-digest: README.md -> $tag ($sha)"
grep -n 'uses: unjs/setup-jup@' README.md
