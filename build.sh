#!/usr/bin/env bash

CNAME="fedora-mesa-git"
LABEL="${CNAME}:latest"
BUILDDIR="output"

REPODIR="mesa-git"
PATCHES=(
	34918.patch
	35069.patch
	35269.patch
	35674.patch
	35676.patch
	35718.patch
)

#
# REPO STUFF
#
HACK_REPO=(--branch radv-float8-hack3 https://gitlab.freedesktop.org/DadSchoorse/mesa.git)
HACK_REV="0db494288e18ff26c94eea8d1261df24f065a1d3"
#
REPO=(https://gitlab.freedesktop.org/mesa/mesa.git)
REV="cf4a1374597dd0532e8d24a070e8885b78559901" # pin to last-known-good
# REV="bcb723ed9eb536a931b9dcc66ca19124038f880b" # pin to 25.1.4

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

git_clone() {
	if [ "$FP8HACK" -eq 1 ]; then
		echo "Using 'radv-float8-hack3' fork..."
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
	"$GIT" clean -fd
}

git_patch() {
	for patch in "${PATCHES[@]}"; do
		if "$GIT" am --no-gpg-sign ../patches/"$patch"; then
			echo "Applied: '$patch'..."
		elif grep -q 'rebase-apply' <<<"$(git am "$patch" 2>&1)"; then
			echo "Skipping '$patch' due to already being applied..."
			git am --abort 2>/dev/null
		else
			echo "Uncaught Error! Something went wrong applying patch: '$patch'..."
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
	git_patch
	build
}

main
