#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MESA="$script_dir"

REALHOME="$(realpath "$HOME")"
# copy 'Lossless.dll' to "~/.local/share/Lossless.dll"
LOSSLESS="$REALHOME/.local/share/Lossless.dll"

# assume we're using OptiScaler (with FSR4_UPGRADE as a fallback)
ARGS=(
  # "DXIL_SPIRV_CONFIG=wmma_rdna3_workaround" # uncomment for RDNA3
  "LSFG_LEGACY=1"
  "LSFG_DLL_PATH=$LOSSLESS"
  "LSFG_PERFORMANCE_MODE=1"
  "LSFG_HDR_MODE=1"
  "PROTON_FSR4_UPGRADE=1"
  "WINEDLLOVERRIDES=dxgi,winmm=n,b"
  "radv_cooperative_matrix2_nv=false"
)
ENV_VARS=(
  "LD_LIBRARY_PATH=$MESA/lib64:$LD_LIBRARY_PATH"
  "VK_DRIVER_FILES=$MESA/share/vulkan/icd.d/radeon_icd.x86_64.json"
  "VK_ADD_IMPLICIT_LAYER_PATH=$MESA/share/vulkan/implicit_layer.d"
  "DRIRC_CONFIGDIR=$MESA/share/drirc.d"
  "GBM_BACKENDS_PATH=$MESA/lib64/gbm"
  "LIBGL_DRIVERS_PATH=$MESA/lib64/dri"
  "LIBVA_DRIVERS_PATH=$MESA/lib64/dri"
  "VDPAU_DRIVER_PATH=$MESA/lib64/dri"
)
[[ ${#ARGS[@]} -gt 0 ]] && ENV_VARS+=("${ARGS[@]}")

exec env "${ENV_VARS[@]}" "$@"
