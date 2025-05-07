#!/usr/bin/env bash

REALHOME="$(realpath "$HOME")"
ARTIFACTDIR="$(realpath "./output")"

TARGETDIR="$REALHOME/mesa"
LOCAL_APPS="$REALHOME/.local/share/applications"

confirm() {
	read -r -p "$1 (Y/n) " response
	if [[ "$response" == "n" || "$response" == "N" ]]; then
		echo "Aborting..."
		return 1
	else
		return 0
	fi
}

if [ -z "$ARTIFACTDIR" ] || ! [ -d "$ARTIFACTDIR" ]; then
	echo "Error: could not find Mesa build artifact directory '$ARTIFACTDIR'!"
	exit 1
fi

if [ -d "$TARGETDIR" ]; then
	! confirm "Warning: '$TARGETDIR' already exists, continuing will overwrite it!" && exit 1
fi

chmod 0755 ./extras/mesa-run.sh ./extras/steam-wrapped.sh
sudo cp -f ./extras/steam-wrapped.sh /usr/local/bin/
sudo ln -sf "$REALHOME"/mesa/mesa-run.sh /usr/local/bin/mesa-run.sh

cp -f ./extras/steam-wrapped.desktop "$LOCAL_APPS"/ &&
	update-desktop-database "$LOCAL_APPS"

if sudo chown -R "$USER":"$USER" "$ARTIFACTDIR" &&
	mkdir -p "$TARGETDIR"/ && cp -rf "$ARTIFACTDIR"/* "$TARGETDIR"/ &&
	cp -f ./extras/mesa-run.sh "$TARGETDIR"/; then
	echo "Success! Use the 'Steam (wrapped)' shortcut or 'mesa-run.sh'..."
fi
