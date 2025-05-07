#!/usr/bin/env bash

cd "/opt/mesa" || exit 1
OUTDIR="$(realpath ./output)"

MESON="$(which meson)"
MESON_OPTS=(setup build64 --reconfigure --libdir lib64 --prefix "$OUTDIR" "-Dgallium-drivers=radeonsi,zink" -Dvideo-codecs=all -Dvulkan-drivers=amd -Dbuildtype=release)

NINJA="$(which ninja)"
NINJA_OPTS=(-C build64 install)

if [ -z "$MESON" ] || [ -z "$NINJA" ]; then
	echo "Error: 'meson' or 'ninja' are not detected in system path! Exiting!"
	exit 1
fi

cd "mesa-git" || exit 1

if ! "$MESON" "${MESON_OPTS[@]}"; then
	echo "Error: something went wrong when configuring meson build!"
	exit 1
fi
if ! "$NINJA" "${NINJA_OPTS[@]}"; then
	echo "Error: something went wrong when compiling Mesa!"
	exit 1
fi
