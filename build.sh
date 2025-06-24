#!/usr/bin/env bash

CNAME="fedora-mesa-git"
LABEL="${CNAME}:latest"
BUILDDIR="output"

GIT="$(which git)"
REPODIR="mesa-git"
PATCHES=(
	# radv-float8-hack3.patch
	# radv-fsr4-exts.patch
	# matrix2-nv.patch
	35269.patch
	34918.patch
)

#
# UNCOMMENT THESE TWO VARS TO USE THE FORK
REPO=(--branch radv-float8-hack3 https://gitlab.freedesktop.org/DadSchoorse/mesa.git)
REV="0db494288e18ff26c94eea8d1261df24f065a1d3"
#
# BELOW IS AN EXPERIMENTAL REBASE
# REPO=(--branch radv-fsr4-exts https://gitlab.freedesktop.org/DadSchoorse/mesa.git)
# REV="47c705fe75ceacb987d0ab0a410ecd186ae62bc7"
#
# UNCOMMENT THESE TWO VARS TO USE MESA UPSTREAM
# REPO=(https://gitlab.freedesktop.org/mesa/mesa.git)
# REV="bcb723ed9eb536a931b9dcc66ca19124038f880b" # pin to 25.1.4
# REV="b0f8c22682b1aa46206f672cdfff1dd9f26e168c" # pin to current upstream

# prevent script from being run outside the project directory
script_dir="$(dirname "$(readlink -f "$0")")"
if [[ "$(pwd -P)" != "$script_dir" ]]; then
	echo "Error: script must be run from the project directory!"
	exit 1
fi

if [ -n "$GIT" ] && ! [ -d ./"$REPODIR" ]; then
	"$GIT" clone "${REPO[@]}" "$REPODIR"
fi

cd "$script_dir/$REPODIR" || exit 1
# always reset repo to pinned revision
"$GIT" reset --hard "$REV" && "$GIT" clean -fd

# COMMENT THIS OUT IF PULLING FROM FORKED MESA REPO
for patch in "${PATCHES[@]}"; do
	if ! "$GIT" am --no-gpg-sign ../patches/"$patch"; then
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
