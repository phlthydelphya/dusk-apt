#!/bin/bash
# Make FINGERPRINT the repo's signing key: write SignWith into
# conf/distributions and export the public key to keyring/.
# Usage: set-key.sh FINGERPRINT
set -euo pipefail

here=$(cd "$(dirname "$0")/.." && pwd)
fpr=${1:-}
if [[ ! $fpr =~ ^[0-9A-F]{40}$ ]]; then
	echo "usage: $0 FINGERPRINT (40 hex digits, upper case)" >&2
	exit 2
fi
# The secret key must be here, or reprepro cannot sign
if ! gpg --batch --list-secret-keys "$fpr" >/dev/null 2>&1; then
	echo "no secret key $fpr in this keyring" >&2
	exit 1
fi

dist=$here/conf/distributions
sed -i '/^SignWith:/d; /^# SignWith/d' "$dist"
printf 'SignWith: %s\n' "$fpr" >>"$dist"

# Binary keyring, as Debian's and Ubuntu's keyring packages ship it
gpg --batch --export "$fpr" >"$here/keyring/dusk-archive-keyring.gpg"
gpg --batch --armor --export "$fpr" >"$here/keyring/dusk-archive-keyring.asc"
echo "signing key set to $fpr"
