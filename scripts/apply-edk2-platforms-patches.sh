#!/bin/sh

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(dirname -- "$script_dir")
platforms_repo="$repo_root/src/edk2-platforms"
patch_file="$repo_root/patches/orion-o6-lsi-option-rom.patch"

if ! git -C "$platforms_repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: src/edk2-platforms is not initialized; clone with --recurse-submodules" >&2
  exit 1
fi

applied_files=0
patch_paths=$(git -C "$platforms_repo" apply --numstat "$patch_file" | awk '{print $3}')

for patch_path in $patch_paths; do
  if git -C "$platforms_repo" apply --reverse --check \
      --include="$patch_path" "$patch_file" >/dev/null 2>&1; then
    continue
  fi

  if git -C "$platforms_repo" apply --check \
      --include="$patch_path" "$patch_file"; then
    git -C "$platforms_repo" apply --include="$patch_path" "$patch_file"
    applied_files=$((applied_files + 1))
    continue
  fi

  echo "error: patch state is ambiguous for $patch_path" >&2
  exit 1
done

if ! git -C "$platforms_repo" apply --reverse --check "$patch_file"; then
  echo "error: Orion O6 LSI Option ROM patch is not fully applied" >&2
  exit 1
fi

if [ "$applied_files" -eq 0 ]; then
  echo "Orion O6 LSI Option ROM patch is already applied."
else
  echo "Applied Orion O6 LSI Option ROM patch to $applied_files file(s)."
fi
