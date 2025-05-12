#!/usr/bin/env bash

MODE=0
REALHOME="$(realpath "$HOME")"
ARTIFACTDIR="$(realpath "./output")"
PKGNAME="fedora-mesa-git"
PKGDIR="$(realpath "./artifact")"

UDD="$(which update-desktop-database)"
TARGETDIR="$REALHOME/mesa"
LOCAL_APPS="$REALHOME/.local/share/applications"

show_help() {
	cat <<EOF
Usage: $0 [OPTIONS]

Install or package custom Mesa build.

Options:
  -h, --help      Show this help message and exit
  -i, --install   Install Mesa to user's home directory (default)
  -p, --package   Create a compressed package of Mesa artifacts
EOF
}

confirm() {
	read -r -p "$1 (Y/n) " response
	if [[ "$response" == "n" || "$response" == "N" ]]; then
		echo "Aborting..."
		return 1
	else
		return 0
	fi
}

package_artifacts() {
	local pkgfile
	pkgfile="${PKGDIR}/${PKGNAME}-$(date +%m%d%Y).tar.gz"

	echo "Packaging Mesa artifacts..."
	rm -rf "$PKGDIR" && mkdir -p "$PKGDIR"
	tar -czf "$pkgfile" -C "$ARTIFACTDIR" .
	echo "Success! Created package: $pkgfile"
}

copy_artifacts() {
	local outdir=$1
	rm -rf "$outdir"
	mkdir -p "$outdir"/
	cp -f ./extras/{mesa-run.sh,steam-wrapped.sh,steam-wrapped.desktop} "$outdir"/
	# correct the lib path in mesa-run.sh
	sed -i "s|/opt/mesa/output|${outdir}|g" "$ARTIFACTDIR"/share/vulkan/icd.d/radeon_icd.x86_64.json
	cp -rf "$ARTIFACTDIR"/* "$outdir"/
	# make links for system-wide usage
	sudo ln -sf "$outdir"/mesa-run.sh /usr/local/bin/mesa-run.sh
	sudo ln -sf "$outdir"/steam-wrapped.sh /usr/local/bin/steam-wrapped.sh
	# copy .desktop file for wrapped Steam and run update-desktop-database
	cp -f "$outdir"/steam-wrapped.desktop "$LOCAL_APPS"/steam-wrapped.desktop
	"$UDD" "$LOCAL_APPS" && echo "Ran 'update-desktop-database' successfully..."
}

install_mesa() {
	if [ "$MODE" -eq 1 ]; then
		[ -d "$TARGETDIR" ] &&
			! confirm "Warning: '$TARGETDIR' already exists, continuing will overwrite it!" && exit 1
		copy_artifacts "$TARGETDIR"
	elif [ "$MODE" -eq 2 ]; then
		[ -d "$PKGDIR" ] &&
			! confirm "Warning: '$PKGDIR' already exists, continuing will overwrite it!" && exit 1
		copy_artifacts "$PKGDIR"
	fi

	echo "Success! Use the 'Steam (wrapped)' shortcut or 'mesa-run.sh' command"
}

if [ -z "$ARTIFACTDIR" ] || ! [ -d "$ARTIFACTDIR" ]; then
	echo "Error: could not find Mesa build artifact directory '$ARTIFACTDIR'!"
	exit 1
fi

MODE=1
if [[ $# -eq 0 ]]; then
	install_mesa # default to "-i" behavior
else
	case "$1" in
	-h | --help)
		show_help
		exit 0
		;;
	-i | --install)
		install_mesa
		;;
	-p | --package)
		MODE=2
		install_mesa
		;;
	*)
		echo "Unknown option: $1"
		show_help
		exit 1
		;;
	esac
fi
