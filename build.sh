#!/usr/bin/env bash

CNAME="fedora-mesa-git"
LABEL="${CNAME}:latest"
BUILDDIR="output"

REPODIR="mesa-git"
PATCHES=(
	34918
	35269
	35445
	# 35734 # needs rebasing
	35746
	35784
	35876
)

#
# REPO STUFF
#
# HACK_REPO=(--branch radv-float8-hack3 https://gitlab.freedesktop.org/DadSchoorse/mesa.git)
# HACK_REV="0db494288e18ff26c94eea8d1261df24f065a1d3"
#
BRANCH_NAME="radv-bvh8-dsbvh"
HACK_REPO=(--branch "$BRANCH_NAME" https://gitlab.freedesktop.org/pixelcluster/mesa.git)
HACK_REV="916c15386bdd1e69dc4606bb545be15195e7a6d2"
#
REPO=(https://gitlab.freedesktop.org/mesa/mesa.git)
# REV="c7cb7b7dc3a79c78aa8e164075385184606a972e" # pin to latest pipeline-checked commit
REV="e1acffbfc00aa11710ae55ae7426461cde1fbbb9" # pin to last known-good (6/26/25)

FP8HACK=0
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
	echo "$0 [--fp8hack]"
	exit 1
elif [ "$1" == "--fp8hack" ]; then
	FP8HACK=1
fi

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
	for patch in "${PATCHES[@]}"; do
		local file="${patch}.patch"
		local path
		path="$(realpath ./patches)"

		echo "Re-fetching '$file'..."
		curl -L "${base_url}/${file}" -o "${path}/${file}" 2>/dev/null
	done
}

git_clone() {
	if [ "$FP8HACK" -eq 1 ]; then
		echo "Using '$BRANCH_NAME' fork..."
		local WREPO=("${HACK_REPO[@]}")
	else
		echo "Using mesa upstream..."
		local WREPO=("${REPO[@]}")
	fi

	if ! [ -d ./"$REPODIR" ]; then
		"$GIT" clone "${WREPO[@]}" "$REPODIR"
	fi
}

git_reset() {
	if ! [ -d ./"$REPODIR" ]; then
		echo "Error: $REPODIR not found!"
		exit 1
	fi

	if [ "$FP8HACK" -eq 1 ]; then
		local WREV=$HACK_REV
	else
		local WREV=$REV
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
			echo "Skipping '${patchn}'..."
			"$GIT" am --abort 2>/dev/null
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
