#!/bin/bash
# Build the dusk-archive-keyring deb: the repo's public key in
# /usr/share/keyrings and a deb822 source that trusts it only for the
# Dusk repo (Signed-By), never system-wide.
# Prints the path of the built deb.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
key=$here/dusk-archive-keyring.gpg
[[ -s $key ]] || { echo "no $key: run scripts/set-key.sh first" >&2; exit 1; }
version=$(<"$here/VERSION")
pkg=dusk-archive-keyring

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
install -D -m 0644 "$key" "$root/usr/share/keyrings/$pkg.gpg"
install -D -m 0644 "$here/dusk.sources" "$root/etc/apt/sources.list.d/dusk.sources"
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
dpkg-deb --root-owner-group -Zxz --build "$root" "$deb" >/dev/null
echo "$deb"
