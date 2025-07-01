#!/bin/bash

MESA="$HOME/mesa"

# assume we're using OptiScaler (with FSR4_UPGRADE as a fallback)
ARGS=(
	# "DXIL_SPIRV_CONFIG=wmma_rdna3_workaround" # uncomment for RDNA3
	"PROTON_FSR4_UPGRADE=1"
	"WINEDLLOVERRIDES=dxgi=n,b,winmm=n,b"
	"radv_cooperative_matrix2_nv=false"
)
ENV_VARS=(
	"LD_LIBRARY_PATH=$MESA/lib64:$LD_LIBRARY_PATH"
	"VK_ICD_FILENAMES=$MESA/share/vulkan/icd.d/radeon_icd.x86_64.json"
	"VK_DRIVER_FILES=$MESA/share/vulkan/icd.d/radeon_icd.x86_64.json"
	"DRIRC_CONFIGDIR=$MESA/share/drirc.d"
	"LIBGL_DRIVERS_PATH=$MESA/lib64/dri"
	"LIBVA_DRIVERS_PATH=$MESA/lib64/dri"
	"VDPAU_DRIVER_PATH=$MESA/lib64/dri"
)
[[ ${#ARGS[@]} -gt 0 ]] && ENV_VARS+=("${ARGS[@]}")

exec env "${ENV_VARS[@]}" "$@"
