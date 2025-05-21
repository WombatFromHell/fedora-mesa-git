#!/usr/bin/env bash

CNAME="fedora-mesa-git"
LABEL="${CNAME}:latest"
BUILDDIR="./output"

GIT="$(which git)"
REPODIR="mesa-git"
# REPO=(--branch radv-float8-hack3 https://gitlab.freedesktop.org/DadSchoorse/mesa.git)
REPO=(https://gitlab.freedesktop.org/mesa/mesa.git)
# REV="7485541cc3a8a4f60ef66e02265048aadf14b3ed" # pin to 25.1.1 (busted)
REV="97f71420dfdf86de084b64cbcbd65855063fcc94" # pin to current upstream

# prevent script from being run outside the project directory
script_dir="$(dirname "$(readlink -f "$0")")"
if [[ "$(pwd -P)" != "$script_dir" ]]; then
	echo "Error: script must be run from the project directory!"
	exit 1
fi

if [ -n "$GIT" ] && ! [ -d ./"$REPODIR" ]; then
	"$GIT" clone "${REPO[@]}" "$REPODIR"
	cd "$REPODIR" || exit 1
	# reset repo to pinned revision state
	"$GIT" reset --hard "$REV"
	"$GIT" clean -fd
	# apply radv-float8-hack3 patch from DadSchoorse:
	# https://gitlab.freedesktop.org/DadSchoorse/mesa/-/commit/4823285a2e5b2df849b55861dd4f051dd2598bf1
	if ! "$GIT" am --no-gpg-sign ../radv-float8-hack3.patch; then
		# if ! "$GIT" apply <../radv-float8-hack3.patch; then
		echo "Something went wrong when applying 'radv-float8-hack3.patch'!"
		exit 1
	else
		cd "$script_dir" || exit 1
	fi
fi

chmod 0755 ./entry.sh
mkdir -p "$BUILDDIR"

if podman build -t "$CNAME" .; then
	podman run -it --replace --rm \
		--userns=keep-id \
		-v ./"$REPODIR":/opt/mesa/mesa-git:z \
		-v "$BUILDDIR":/opt/mesa/output:z \
		--name "$CNAME" \
		"$LABEL"
fi
