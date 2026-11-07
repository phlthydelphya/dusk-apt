#!/bin/bash
# Print the newest .deb of each package found in the given directories.
# Usage: latest-debs.sh DIR...
set -euo pipefail

declare -A best_ver best_path
for dir in "$@"; do
	for deb in "$dir"/*.deb; do
		[[ -e $deb ]] || continue
		pkg=$(dpkg-deb -f "$deb" Package)
		ver=$(dpkg-deb -f "$deb" Version)
		if [[ -z ${best_ver[$pkg]:-} ]] || dpkg --compare-versions "$ver" gt "${best_ver[$pkg]}"; then
			best_ver[$pkg]=$ver
			best_path[$pkg]=$(realpath "$deb")
		fi
	done
done
for pkg in "${!best_path[@]}"; do
	printf '%s\n' "${best_path[$pkg]}"
done | sort
