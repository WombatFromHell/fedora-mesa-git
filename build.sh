#!/usr/bin/env bash

CNAME="fedora-mesa-git"
LABEL="${CNAME}:latest"
BUILDDIR="output"

REPODIR="mesa-git"
PATCHES=(
	34918 # recommended by Etaash
	35269 # raytracing optimization
	# 35854 # pending rebase
	# 35919 # RDNA3
	34242 # AL2 support
)

REPO=(https://gitlab.freedesktop.org/mesa/mesa.git)
REV="e55e63c5a752d9c83e535963ca79781631ac327a" # pin to last known-good (7/11/25)

# prevent script from being run outside the project directory
script_dir="$(dirname "$(readlink -f "$0")")"
if [[ "$(pwd -P)" != "$script_dir" ]]; then
	echo "Error: script must be run from the project directory!"
	exit 1
fi

GIT="$(which git)"
if [ -z "$GIT" ]; then
	echo "Error! Cannot locate 'git' in path!"
	exit 1
fi

update_patches() {
	local base_url="https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests"
	local path
	path="$(realpath ./patches)"

	rm -f "$path/*.patch"
	for patch in "${PATCHES[@]}"; do
		local file="${patch}.patch"

		echo "Re-fetching '$file'..."
		curl -L "${base_url}/${file}" -o "${path}/${file}" 2>/dev/null
	done
}

git_clone() {
	echo "Using mesa upstream..."
	local WREPO=("${REPO[@]}")
	if ! [ -d ./"$REPODIR" ]; then
		"$GIT" clone "${WREPO[@]}" "$REPODIR"
	fi
}

git_reset() {
	local WREV=$REV

	if ! [ -d ./"$REPODIR" ]; then
		echo "Error: $REPODIR not found!"
		exit 1
	fi

	cd "$script_dir/$REPODIR" || exit 1
	# always reset repo to pinned revision
	"$GIT" fetch
	"$GIT" am --abort
	"$GIT" reset --hard "$WREV"
	"$GIT" clean -fdx
}

git_patch() {
	local patch_cmd=("$GIT" am --no-gpg-sign --whitespace=fix)
	for patch in "${PATCHES[@]}"; do
		local patchn="$patch.patch"
		local path="../patches/$patchn"

		if "${patch_cmd[@]}" "$path"; then
			echo "Applied: '$patchn'..."
		elif grep -q 'rebase-apply' <<<"$("${patch_cmd[@]}" "$path" 2>&1)"; then
			echo "Aborting on: '${patchn}'..."
			"$GIT" am --abort 2>/dev/null
			exit 1
		else
			echo "Uncaught Error! Something went wrong applying patch: '${patchn}'..."
			exit 1
		fi
	done
}

build() {
	cd "$script_dir" || exit 1
	mkdir -p "$script_dir/$BUILDDIR"

	if podman build -t "$CNAME" .; then
		podman run -it --replace --rm \
			-v ./"$BUILDDIR":/opt/mesa/output:z \
			--name "$CNAME" \
			"$LABEL"
	fi
}

main() {
	git_clone
	git_reset
	update_patches
	git_patch
	build
}

main
