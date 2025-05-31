#!/usr/bin/env bash

CNAME="fedora-mesa-git"
LABEL="${CNAME}:latest"
BUILDDIR="output"

GIT="$(which git)"
REPODIR="mesa-git"
PATCHFILE="radv-float8-hack3.patch"
#
# UNCOMMENT THESE TWO VARS TO USE THE FORK
#REPO=(--branch radv-float8-hack3 https://gitlab.freedesktop.org/DadSchoorse/mesa.git)
#REV="fa81930282c218e87232643937418bb2a1ca15bd" # pin to the last-known-good
#
# UNCOMMENT THESE TWO VARS TO USE MESA UPSTREAM
REPO=(https://gitlab.freedesktop.org/mesa/mesa.git)
REV="05c2c748db410a68f97d81d431b35eab38774c90" # pin to current upstream (May 30 '25)
# REV="85d2c8f8aeac9e8a9b945dd46000513add0af4bd" # pin to 25.1.1

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
if ! "$GIT" am --no-gpg-sign ../"$PATCHFILE"; then
	echo "Something went wrong when applying the patch file!"
	exit 1
fi

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
