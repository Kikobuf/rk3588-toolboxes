#!/usr/bin/env bash
#
# refresh-toolboxes.sh — pull the latest image for one or all rk3588 toolbox
# tags and recreate the corresponding toolbox/distrobox container.
#
# Usage:
#   ./refresh-toolboxes.sh all
#   ./refresh-toolboxes.sh rkllama
#   ./refresh-toolboxes.sh rk-llama-cpp

set -euo pipefail

REGISTRY="${RK3588_TOOLBOXES_REGISTRY:-ghcr.io/kikobuf/rk3588-toolboxes}"

if command -v toolbox >/dev/null 2>&1; then
  TOOLCMD="toolbox"
elif command -v distrobox >/dev/null 2>&1; then
  TOOLCMD="distrobox"
else
  echo "Neither 'toolbox' nor 'distrobox' found on PATH. Install one first." >&2
  exit 1
fi

DEVICE_ARGS="--device /dev/dri --device /dev/rknpu --group-add video"

refresh_one() {
  local tag="$1"
  local container_name="${tag}"
  local image="${REGISTRY}:${tag}"

  echo "==> Refreshing ${container_name} (${image})"
  docker pull "${image}" || podman pull "${image}"

  if ${TOOLCMD} list 2>/dev/null | grep -q "${container_name}"; then
    echo "    Removing existing container ${container_name}"
    ${TOOLCMD} rm -f "${container_name}" || true
  fi

  echo "    Creating ${container_name}"
  ${TOOLCMD} create "${container_name}" \
    --image "${image}" \
    -- ${DEVICE_ARGS}

  echo "    Done. Enter with: ${TOOLCMD} enter ${container_name}"
}

TARGET="${1:-all}"

case "$TARGET" in
  all)
    refresh_one "rkllama"
    refresh_one "rk-llama-cpp"
    ;;
  rkllama|rk-llama-cpp)
    refresh_one "$TARGET"
    ;;
  *)
    echo "Unknown target: $TARGET" >&2
    echo "Usage: $0 [all|rkllama|rk-llama-cpp]" >&2
    exit 1
    ;;
esac
