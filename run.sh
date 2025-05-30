#!/usr/bin/env bash

CNAME="fedora-mesa-git"
LABEL="${CNAME}:latest"
BUILDDIR="./output"

GIT="$(which git)"
REPODIR="mesa-git"
#
#REPO=(--branch radv-float8-hack3 https://gitlab.freedesktop.org/DadSchoorse/mesa.git)
#REV="fa81930282c218e87232643937418bb2a1ca15bd" # pin to the last-known-good
#
REPO=(https://gitlab.freedesktop.org/mesa/mesa.git)
# REV="7485541cc3a8a4f60ef66e02265048aadf14b3ed" # pin to 25.1.1
REV="018f4f1c27a536b72988bcc401419bd3e4d74979" # pin to current upstream

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
	if "$GIT" reset --hard "$REV" && "$GIT" clean -fd; then
		cd "$script_dir/$REPODIR" || exit 1
	else
		echo "Something went wrong when resetting WIP repo!"
		exit 1
	fi

	# USE THE BELOW IF PULLING FROM UPSTREAM MESA REPO
	# apply radv-float8-hack3 patch from DadSchoorse's branch:
	# https://gitlab.freedesktop.org/DadSchoorse/mesa/-/commits/radv-float8-hack3
	if ! "$GIT" am --no-gpg-sign ../radv-float8-hack3.patch; then
		# if ! "$GIT" apply <../radv-float8-hack3.patch; then
		echo "Something went wrong when applying 'radv-float8-hack3.patch'!"
		exit 1
	else
		cd "$script_dir/$REPODIR" || exit 1
	fi
fi

mkdir -p "$BUILDDIR"

if podman build -t "$CNAME" .; then
	podman run -it --replace --rm \
		--userns=keep-id \
		-v ./"$REPODIR":/opt/mesa/mesa-git:z \
		-v "$BUILDDIR":/opt/mesa/output:z \
		--name "$CNAME" \
		"$LABEL"
fi
