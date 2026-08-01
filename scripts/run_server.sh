#!/usr/bin/env bash
#
# run_server.sh — launch rkllama inside the toolbox with a given model and
# platform. Assumes you're already inside the rkllama toolbox container.
#
# Usage:
#   ./run_server.sh --model <model-name> --platform <rk3588|rk3576> [--port <port>]

set -euo pipefail

MODEL=""
PLATFORM="rk3588"
PORT="8080"

usage() {
  echo "Usage: $0 --model <model-name> --platform <rk3588|rk3576> [--port <port>]"
  echo ""
  echo "  --model      Model name or path to a .rkllm file"
  echo "  --platform   Target NPU platform: rk3588 or rk3576 (default: rk3588)"
  echo "  --port       Port to serve on (default: 8080)"
  echo ""
  echo "See docs/models.md for pre-converted model sources and conversion steps."
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model) MODEL="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown argument: $1" >&2; usage ;;
  esac
done

if [[ -z "$MODEL" ]]; then
  echo "Error: --model is required." >&2
  usage
fi

if [[ "$PLATFORM" != "rk3588" && "$PLATFORM" != "rk3576" ]]; then
  echo "Error: --platform must be rk3588 or rk3576." >&2
  exit 1
fi

if [[ ! -e /dev/rknpu ]] && [[ ! -e /sys/kernel/debug/rknpu/version ]]; then
  echo "Warning: NPU device/debugfs not found. Check docs/host-config.md." >&2
fi

echo "==> Launching rkllama with model '${MODEL}' on ${PLATFORM} (port ${PORT})"

cd /opt/rkllama
python3 server.py \
  --model "${MODEL}" \
  --platform "${PLATFORM}" \
  --port "${PORT}"
