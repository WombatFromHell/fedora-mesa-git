#!/usr/bin/env bash

MODE=0
REALHOME="$(realpath "$HOME")"
ARTIFACTDIR="$(realpath "./output")"
PKGNAME="fedora-mesa-git"
LOCAL_APPS="$REALHOME/.local/share/applications"
UDD="$(which update-desktop-database)"

PKGDIR_DEFAULT="$(realpath "./artifact")"
TARGETDIR_DEFAULT="$REALHOME/mesa"

cache_creds() {
	sudo -v
	local status="$?"
	if [ "$status" -eq 130 ] || [ "$status" -eq 1 ]; then
		echo "Error: Cannot obtain sudo credentials!"
		exit 1
	else
		return 0
	fi
}

show_help() {
	cat <<EOF
Usage: $0 [OPTIONS]

Install or package custom Mesa build.

Options:
  -h, --help      Show this help message and exit
  -i, --install [PATH]   Install Mesa to a specified directory (default is "$TARGETDIR_DEFAULT")
  -p, --package [PATH]   Create a compressed package of Mesa artifacts into a specified output path ...
                         ... (default is "$PKGDIR_DEFAULT")
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
	cache_creds

	rm -rf "$outdir"
	mkdir -p "$outdir/"

	cp -f ./extras/{install.sh,mesa-run.sh,steam-wrapped.sh,steam-wrapped.desktop} "$outdir"/
	cp -rf "$ARTIFACTDIR"/* "$outdir"/
	sed -i "s|/opt/mesa/output|$outdir|g" "$outdir"/share/vulkan/icd.d/radeon_icd.x86_64.json
	local vk_al2lib="libVkLayer_MESA_anti_lag.so"
	sed -i "s|\"$vk_al2lib\"|\"$outdir/lib64/$vk_al2lib\"|g" "$outdir"/share/vulkan/implicit_layer.d/VkLayer_MESA_anti_lag.json

	sudo ln -sf "$outdir"/mesa-run.sh /usr/local/bin/mesa-run.sh
	sudo ln -sf "$outdir"/steam-wrapped.sh /usr/local/bin/steam-wrapped.sh
	# cp -f "$outdir"/steam-wrapped.desktop "$LOCAL_APPS"/steam-wrapped.desktop
	# "$UDD" "$LOCAL_APPS" && echo "Ran 'update-desktop-database' successfully..."
}

install_mesa() {
	if [ "$MODE" -eq 1 ]; then
		if [ -d "$TARGETDIR" ] &&
			! confirm "Warning: '$TARGETDIR' already exists, continuing will overwrite it!"; then
			exit 1
		fi

		copy_artifacts "$TARGETDIR"
	elif [ "$MODE" -eq 2 ]; then
		if [ -d "$PKGDIR" ] &&
			! confirm "Warning: '$PKGDIR' already exists, continuing will overwrite it!"; then
			exit 1
		fi

		copy_artifacts "$PKGDIR"
		package_artifacts
	fi

	echo "Success! Simply use the 'mesa-run.sh' or 'steam-wrapped.sh' commands."
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
		MODE=1

		if [[ -n $2 && $2 != -* ]]; then
			echo "Path specified: $2"
			TARGETDIR="$2"
			shift 2
		else
			shift
			TARGETDIR="${TARGETDIR:-$TARGETDIR_DEFAULT}"
		fi

		install_mesa
		;;
	-p | --package)
		MODE=2

		if [[ -n $2 && $2 != -* ]]; then
			PKGDIR="$2"
			shift 2
		else
			shift
			PKGDIR="${PKGDIR:-$PKGDIR_DEFAULT}"
		fi

		install_mesa
		;;
	*)
		echo "Unknown option: $1"
		show_help
		exit 1
		;;
	esac
fi
