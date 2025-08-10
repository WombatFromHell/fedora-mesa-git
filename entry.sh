#!/usr/bin/env bash

cd "/opt/mesa" || exit 1
OUTDIR="$(realpath ./output)"
MESON="$(which meson)"

# LINKER OPTS
COMMON_LARGS=()
# COMPILER FLAGS
COMMON_FLAGS=()

MESON_OPTS=(
  setup build64/ --reconfigure --libdir lib64 -Dprefix="$OUTDIR"
  "-Dgallium-drivers=radeonsi,zink,llvmpipe" -Dvideo-codecs=all -Dvulkan-drivers=amd -Dbuildtype=release
  -Dvulkan-layers=anti-lag
)
[[ ${#COMMON_FLAGS[@]} -gt 0 ]] &&
  MESON_OPTS+=("-Dc_args=${COMMON_FLAGS[*]}" "-Dcpp_args=${COMMON_FLAGS[*]}")
[[ ${#COMMON_LARGS[@]} -gt 0 ]] &&
  MESON_OPTS+=("-Dc_link_args=${COMMON_LARGS[*]}" "-Dcpp_link_args=${COMMON_LARGS[*]}")

NINJA="$(which ninja)"
NINJA_OPTS=(-C build64 install)

if [ -z "$MESON" ] || [ -z "$NINJA" ]; then
  echo "Error: 'meson' or 'ninja' are not detected in system path! Exiting!"
  exit 1
fi

cd "mesa-git" || exit 1
# ensure we build/reconfigure from scratch every time
rm -rf ./build64 || exit 1

if ! "$MESON" "${MESON_OPTS[@]}"; then
  echo "Error: something went wrong when configuring meson build!"
  exit 1
fi
if ! "$NINJA" "${NINJA_OPTS[@]}"; then
  echo "Error: something went wrong when compiling Mesa!"
  exit 1
fi
