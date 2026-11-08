#!/bin/bash
# Build the dusk-archive-keyring deb: the repo's public key in
# /usr/share/keyrings and a deb822 source that trusts it only for the
# Dusk repo (Signed-By), never system-wide.
# One deb per suite, since dusk.sources names the suite; the version ends in
# the Ubuntu release, so upgrading to a newer release sorts higher.
# Usage: build.sh [CODENAME]   (default stonking)
# Prints the path of the built deb.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
key=$here/dusk-archive-keyring.gpg
[[ -s $key ]] || { echo "no $key: run scripts/set-key.sh first" >&2; exit 1; }
codename=${1:-stonking}
case $codename in
	resolute) release=26.04 ;;
	stonking) release=26.10 ;;
	*) echo "unknown suite: $codename" >&2; exit 2 ;;
esac
version=$(<"$here/VERSION")+$release
pkg=dusk-archive-keyring

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
install -D -m 0644 "$key" "$root/usr/share/keyrings/$pkg.gpg"
install -d "$root/etc/apt/sources.list.d"
sed "s/^Suites: .*/Suites: $codename/" "$here/dusk.sources" >"$root/etc/apt/sources.list.d/dusk.sources"
chmod 0644 "$root/etc/apt/sources.list.d/dusk.sources"
install -D -m 0644 "$here/../LICENSE" "$root/usr/share/doc/$pkg/copyright"
install -d "$root/DEBIAN"
echo /etc/apt/sources.list.d/dusk.sources >"$root/DEBIAN/conffiles"
cat >"$root/DEBIAN/control" <<CONTROL
Package: $pkg
Version: $version
Architecture: all
Multi-Arch: foreign
Section: misc
Priority: optional
Maintainer: phlthydelphya <291215135+phlthydelphya@users.noreply.github.com>
Description: GnuPG key and apt source for the Dusk package repository
 Installs the public key that signs the Dusk apt repository and an apt
 source that trusts that key for the Dusk repository only.
CONTROL

mkdir -p "$here/out"
deb=$here/out/${pkg}_${version}_all.deb
rm -f "$deb"
# Reproducible: the same VERSION always gives the same bytes
epoch=$(date -u -d "$(tr . - <"$here/VERSION")" +%s)
find "$root" -exec touch -h -d "@$epoch" {} +
SOURCE_DATE_EPOCH=$epoch dpkg-deb --root-owner-group -Zxz --build "$root" "$deb" >/dev/null
echo "$deb"
