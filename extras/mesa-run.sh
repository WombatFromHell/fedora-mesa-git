#!/bin/bash

MESA="$HOME/mesa"
LD_LIBRARY_PATH="$MESA"/lib64:"$LD_LIBRARY_PATH" \
	VK_ICD_FILENAMES="$MESA"/share/vulkan/icd.d/radeon_icd.x86_64.json \
	VK_DRIVER_FILES="$MESA"/share/vulkan/icd.d/radeon_icd.x86_64.json \
	DRIRC_CONFIGDIR="$MESA"/share/drirc.d \
	LIBGL_DRIVERS_PATH="$MESA"/lib64/dri \
	LIBVA_DRIVERS_PATH="$MESA"/lib64/dri \
	VDPAU_DRIVER_PATH="$MESA"/lib64/dri \
	D3D_MODULE_PATH="$MESA"/lib64/d3d/d3dadapter9.so.1 \
	exec "$@"
