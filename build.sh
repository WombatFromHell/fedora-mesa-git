#!/usr/bin/env bash

CNAME="fedora-mesa-git"
LABEL="${CNAME}:latest"
BUILDDIR="output"

GIT="$(which git)"
REPODIR="mesa-git"
PATCHES=(
	35269.patch
	34918.patch
)

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
	echo "$0 [--fp8hack]"
	exit 1
fi

#
HACK_REPO=(--branch radv-float8-hack3 https://gitlab.freedesktop.org/DadSchoorse/mesa.git)
HACK_REV="0db494288e18ff26c94eea8d1261df24f065a1d3"
#
REPO=(https://gitlab.freedesktop.org/mesa/mesa.git)
REV="cf4a1374597dd0532e8d24a070e8885b78559901" # pin to last-known-good
# REV="bcb723ed9eb536a931b9dcc66ca19124038f880b" # pin to 25.1.4

# prevent script from being run outside the project directory
script_dir="$(dirname "$(readlink -f "$0")")"
if [[ "$(pwd -P)" != "$script_dir" ]]; then
	echo "Error: script must be run from the project directory!"
	exit 1
fi

if [ -n "$GIT" ] && ! [ -d ./"$REPODIR" ]; then
	if [ "$#" -eq 0 ]; then
		echo "Using mesa upstream..."
		"$GIT" clone "${REPO[@]}" "$REPODIR"
	elif [ "$1" == "--fp8hack" ]; then
		echo "Using 'radv-float8-hack3' fork..."
		"$GIT" clone "${HACK_REPO[@]}" "$REPODIR"
	fi
fi

cd "$script_dir/$REPODIR" || exit 1

if [ -d ./"$REPODIR" ] && [ "$1" != "--fp8hack" ]; then
	# always reset repo to pinned revision
	"$GIT" fetch &&
		"$GIT" reset --hard "$REV" &&
		"$GIT" clean -fd
elif [ -d ./"$REPODIR" ]; then
	"$GIT" fetch &&
		"$GIT" reset --hard "$HACK_REV" &&
		"$GIT" clean -fd
fi

for patch in "${PATCHES[@]}"; do
	echo "Attempting to apply patchfile: $patch"
	if ! "$GIT" am --no-gpg-sign --whitespace=fix ../patches/"$patch"; then
		echo "Something went wrong when applying the patch file!"
		exit 1
	fi
done

cd "$script_dir" || exit 1
mkdir -p "$script_dir/$BUILDDIR"

if podman build -t "$CNAME" .; then
	podman run -it --replace --rm \
		--userns=keep-id \
		-v ./"$REPODIR":/opt/mesa/mesa-git:z \
		-v ./"$BUILDDIR":/opt/mesa/output:z \
		--name "$CNAME" \
		"$LABEL"
fi
