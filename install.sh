#!/usr/bin/env bash

MODE=0
REALHOME="$(realpath "$HOME")"
ARTIFACTDIR="$(realpath "./output")"
PKGNAME="fedora-mesa-git"
UDD="$(which update-desktop-database)"

PKGDIR_DEFAULT="$(realpath "./artifact")"
TARGETDIR_DEFAULT="$REALHOME/mesa"

enforce_local() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local current_dir
  current_dir="$(pwd)"

  if [[ "$script_dir" != "$current_dir" ]]; then
    echo "This script must be run from the repo directory: $script_dir"
    exit 1
  fi
}
enforce_local

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
  pkgfile="${REALHOME}/Downloads/${PKGNAME}-$(date +%m%d%y_%H%M).tar.gz"

  echo "Packaging Mesa artifacts..."
  tar -czf "$pkgfile" -C "$PKGDIR" . &&
    rm -rf "$PKGDIR"
  echo "Success! Created package: $pkgfile"
}

copy_lsfgvk() {
  # extract the release lsfg-vk archive to "./lsfg-vk" and preserve the paths
  local outdir="$1"
  local tmpdir="./lsfg-vk"
  cache_creds

  if [ -d "$tmpdir" ]; then
    local local_icons="$REALHOME/.local/share/icons"
    local local_apps="$REALHOME/.local/share/applications"

    local vklsfglib="liblsfg-vk.so"
    local vklsfglayer="VkLayer_LS_frame_generation.json"

    # include 'lsfg-vk-ui' so our local 'install.sh' can use it later
    cp -f "$tmpdir"/usr/bin/lsfg-vk-ui "$outdir"/

    if [ "$MODE" -eq 1 ]; then
      # mutate critical files only if we're in install mode
      mkdir -p "$local_icons" &&
        cp -rf "$tmpdir"/usr/share/icons/* "$local_icons"/
      mkdir -p "$local_apps" &&
        mkdir -p "/usr/local/bin/" &&
        cp -f "$tmpdir"/usr/share/applications/lsfg-vk-ui.desktop "$local_apps"/ &&
        sudo cp -f "$tmpdir"/usr/bin/lsfg-vk-ui "/usr/local/bin/"

      if [ -n "$UDD" ]; then
        echo "Updating desktop database with 'lsfg-vk-ui.desktop'"
        "$UDD" "$local_apps"
      fi
    else
      # include the lsfg-vk-ui.desktop file in packaging mode
      cp -f "$tmpdir"/usr/share/applications/lsfg-vk-ui.desktop "$outdir"/
    fi

    cp -f "$tmpdir"/usr/lib/"$vklsfglib" "$outdir"/lib64/"$vklsfglib"
    mkdir -p "$outdir"/share/vulkan/implicit_layer.d/ &&
      cp -f "$tmpdir"/usr/share/vulkan/implicit_layer.d/"$vklsfglayer" "$outdir"/share/vulkan/implicit_layer.d/
    if [ "$MODE" -eq 1 ]; then
      sed -i "s|\"$vklsfglib\"|\"$outdir/lib64/$vklsfglib\"|g" \
        "$outdir"/share/vulkan/implicit_layer.d/"$vklsfglayer"
    fi

    echo "Ensure 'Lossless.dll' is copied into: '$REALHOME/.local/share/'"
  else
    echo "Error: './lsfg-vk' not found, skipping!"
    return 1
  fi
}

copy_artifacts() {
  local outdir=$1
  cache_creds

  rm -rf "$outdir"
  mkdir -p "$outdir/"

  cp -rf ./extras/* "$outdir"/
  cp -rf "$ARTIFACTDIR"/* "$outdir"/
  sed -i "s|/opt/mesa/output|$outdir|g" "$outdir"/share/vulkan/icd.d/radeon_icd.x86_64.json
  local vk_al2lib="libVkLayer_MESA_anti_lag.so"
  sed -i "s|\"$vk_al2lib\"|\"$outdir/lib64/$vk_al2lib\"|g" "$outdir"/share/vulkan/implicit_layer.d/VkLayer_MESA_anti_lag.json

  # ensure 'lsfg-vk' files are copied to local artifacts
  copy_lsfgvk "$1"

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
