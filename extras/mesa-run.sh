#!/usr/bin/env bash

script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
MESA="$script_dir"

ARGS=(
  # "DXIL_SPIRV_CONFIG=wmma_rdna3_workaround" # uncomment for RDNA3
  radv_legacy_sparse_binding=true # Indian Jones fixes
  radv_zero_vram=true             # Indian Jones fixes
)
ENV_VARS=(
  "LD_LIBRARY_PATH=$MESA/lib64:$LD_LIBRARY_PATH"
  "VK_DRIVER_FILES=$MESA/share/vulkan/icd.d/radeon_icd.x86_64.json"
  "VK_ADD_IMPLICIT_LAYER_PATH=$MESA/share/vulkan/implicit_layer.d"
  "DRIRC_CONFIGDIR=$MESA/share/drirc.d"
  "LIBGL_DRIVERS_PATH=$MESA/lib64/dri"
  "LIBVA_DRIVERS_PATH=$MESA/lib64/dri"
  "VDPAU_DRIVER_PATH=$MESA/lib64/vdpau"
)
[[ ${#ARGS[@]} -gt 0 ]] && ENV_VARS+=("${ARGS[@]}")

exec env "${ENV_VARS[@]}" "$@"
