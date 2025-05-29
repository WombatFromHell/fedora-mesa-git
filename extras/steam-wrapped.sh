#!/usr/bin/env bash

WRAPPER_PATH="$(realpath "$HOME")/mesa/mesa-run.sh"
STEAM_PATH="$(which steam)"

exec env "$WRAPPER_PATH" "$STEAM_PATH" "$@"
