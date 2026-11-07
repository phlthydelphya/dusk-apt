#!/bin/bash
# Install the tools dusk-apt needs. Run with sudo.
set -euo pipefail
if [[ $EUID -ne 0 ]]; then
	echo "run with sudo: sudo $0" >&2
	exit 1
fi
apt-get update
apt-get install -y reprepro
