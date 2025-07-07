#!/usr/bin/env bash

script_dir="$(dirname "$(readlink -f "$0")")"
cd "$script_dir" || exit 1

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

link_artifacts() {
	sudo ln -sf "${script_dir}/mesa-run.sh" "/usr/local/bin/mesa-run.sh"
	sudo ln -sf "${script_dir}/steam-wrapped.sh" "/usr/local/bin/steam-wrapped.sh"
}
link_desktop_file() {
	local UDD
	UDD="$(which update-desktop-database)"

	local app_dir
	mkdir -p ~/.local/share/applications/
	app_dir="$(realpath "$HOME"/.local/share/applications)"

	ln -sf "$script_dir"/steam-wrapped.desktop "$app_dir"/steam-wrapped.desktop
	"$UDD" "$app_dir"
}

cache_creds
link_artifacts
# UNCOMMENT BELOW IF YOU WANT THE .DESKTOP SHORTCUT
# link_desktop_file

echo "Success! Simply use the 'mesa-run.sh' or 'steam-wrapped.sh' commands."
