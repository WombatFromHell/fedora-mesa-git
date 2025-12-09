#!/usr/bin/env bash

script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
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
  local local_bin="/usr/local/bin"
  sudo mkdir -p "$local_bin" &&
    sudo ln -sf "$script_dir/mesa-run.sh" "$local_bin/mesa-run.sh" &&
    sudo ln -sf "$script_dir/steam-wrapped.sh" "$local_bin/steam-wrapped.sh" &&
    sudo ln -sf "$script_dir/lsfg-vk-ui" "$local_bin/lsfg-vk-ui"
}
link_desktop_file() {
  local UDD
  UDD="$(which update-desktop-database)"

  local app_dir
  mkdir -p ~/.local/share/applications/
  app_dir="$(realpath "$HOME"/.local/share/applications)"

  ln -sf "$script_dir"/steam-wrapped.desktop "$app_dir"/steam-wrapped.desktop
  ln -sf "$script_dir"/lsfg-vk-ui.desktop "$app_dir"/lsfg-vk-ui.desktop
  "$UDD" "$app_dir"
}

cache_creds
link_artifacts
# UNCOMMENT BELOW IF YOU WANT THE .DESKTOP SHORTCUT
# link_desktop_file

echo "Success! Simply use the 'mesa-run.sh' or 'steam-wrapped.sh' commands."
