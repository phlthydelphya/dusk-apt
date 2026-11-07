#!/bin/bash
# Add the newest Dusktop debs and the keyring deb to the repo, export a
# signed tree into public/ and commit it as the single gh-pages commit.
# Pushing is a separate, manual step: git -C public push -f origin gh-pages
# Usage: publish.sh [--dist DIR]
#   --dist DIR   directory of Dusktop debs (default ~/dusk-theme/packaging/dist)
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
dist=$HOME/dusk-theme/packaging/dist
codename=stonking
while (($#)); do
	case $1 in
		--dist) dist=$2; shift 2 ;;
		-h|--help) sed -n '2,7p' "$0"; exit 0 ;;
		*) echo "unknown option: $1" >&2; exit 2 ;;
	esac
done

command -v reprepro >/dev/null || { echo "missing reprepro: sudo $here/scripts/install-deps.sh" >&2; exit 1; }
grep -Eq '^SignWith: [0-9A-F]{40}$' "$here/conf/distributions" \
	|| { echo "no signing key: run scripts/set-key.sh FINGERPRINT" >&2; exit 1; }

# public/ is a worktree of the orphan gh-pages branch
if [[ ! -e $here/public/.git ]]; then
	git -C "$here" worktree add --orphan -b gh-pages "$here/public"
fi

mapfile -t debs < <("$here/scripts/latest-debs.sh" "$dist")
((${#debs[@]})) || { echo "no debs in $dist" >&2; exit 1; }
debs+=("$(bash "$here/keyring/build.sh")")

for deb in "${debs[@]}"; do
	# An already published version is skipped, a newer one replaces it
	reprepro -b "$here" includedeb "$codename" "$deb"
done
reprepro -b "$here" deleteunreferenced
reprepro -b "$here" export "$codename"

# Bootstrap key for people adding the repo by hand
install -m 0644 "$here/keyring/dusk-archive-keyring.gpg" "$here/public/dusk-archive-keyring.gpg"
install -m 0644 "$here/keyring/dusk-archive-keyring.asc" "$here/public/dusk-archive-keyring.asc"
: >"$here/public/.nojekyll"

# One parentless commit per publish, so old debs never pile up in history
git -C "$here/public" add -A
tree=$(git -C "$here/public" write-tree)
commit=$(git -C "$here/public" commit-tree "$tree" -m "Publish $(date -u +%Y-%m-%dT%H:%MZ)")
git -C "$here/public" reset -q --soft "$commit"
echo "published $(git -C "$here/public" rev-parse --short HEAD) on gh-pages (not pushed)"
reprepro -b "$here" list "$codename"
