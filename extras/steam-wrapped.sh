#!/usr/bin/env bash

WRAPPER_PATH="$(realpath "$HOME")/mesa/mesa-run.sh"
STEAM_PATH="$(which steam)"
ARGS=("DXIL_SPIRV_CONFIG=wmma_fp8_hack")

exec env "${ARGS[@]}" "$WRAPPER_PATH" "$STEAM_PATH" "$@"
