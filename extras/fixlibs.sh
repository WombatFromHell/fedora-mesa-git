#!/usr/bin/env bash
set -euo pipefail

script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
MESA_PREFIX="$script_dir"

LIBDIR="$MESA_PREFIX/lib64"
JSON_DIRS=(
  "$MESA_PREFIX/share/vulkan/icd.d"
  "$MESA_PREFIX/share/vulkan/implicit_layer.d"
)

for dir in "${JSON_DIRS[@]}"; do
  if ! [ -d "$dir" ]; then
    echo "Error: '$dir' does not exist!"
    exit 1
  fi

  for json in "$dir"/*.json; do
    echo "Fixing $json"

    # Grab the library_path value (filename or full path)
    libval=$(grep -oP '"library_path":\s*"\K[^"]+' "$json")

    libname=$(basename "$libval")
    newpath="$LIBDIR/$libname"

    if [[ ! -f "$newpath" ]]; then
      echo "ERROR: $newpath does not exist. Skipping $json." >&2
      continue
    fi

    # Replace only the library_path value, not the whole line
    sed -i -E "s|(\"library_path\":\s*\").*(\")|\1$newpath\2|" "$json"
  done
done
