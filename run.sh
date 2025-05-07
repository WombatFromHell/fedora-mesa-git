#!/usr/bin/env bash

CNAME="fedora-mesa-git"
LABEL="${CNAME}:latest"
BUILDDIR="./output"

GIT="$(which git)"
REPODIR="mesa-git"
REPO=(--branch radv-float8-hack3 https://gitlab.freedesktop.org/DadSchoorse/mesa.git)

# prevent script from being run outside the project directory
script_dir="$(dirname "$(readlink -f "$0")")"
if [[ "$(pwd -P)" != "$script_dir" ]]; then
	echo "Error: script must be run from the dotfile root directory!"
	exit 1
fi

if [ -n "$GIT" ] && ! [ -d ./"$REPODIR" ]; then
	"$GIT" clone "${REPO[@]}" "$REPODIR"
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
