#!/usr/bin/env bash
#
# run_server.sh — launch rkllama inside the toolbox, serving whatever
# .rkllm models are found under a models directory. Assumes you're already
# inside the rkllama toolbox container.
#
# Usage:
#   ./run_server.sh --models <models-dir> --platform <rk3588|rk3576> [--port <port>]

set -euo pipefail

MODELS_DIR=""
PLATFORM="rk3588"
PORT="8080"

usage() {
  echo "Usage: $0 --models <models-dir> --platform <rk3588|rk3576> [--port <port>]"
  echo ""
  echo "  --models     Directory containing your .rkllm model files"
  echo "  --platform   Target NPU platform: rk3588 or rk3576 (default: rk3588)"
  echo "  --port       Port to serve on (default: 8080)"
  echo ""
  echo "rkllama serves every model found under --models; pick which one to use"
  echo "per request via the \"model\" field in the API call, Ollama-style."
  echo "See docs/models.md for pre-converted model sources and conversion steps."
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --models) MODELS_DIR="$2"; shift 2 ;;
    --platform) PLATFORM="$2"; shift 2 ;;
    --port) PORT="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown argument: $1" >&2; usage ;;
  esac
done

if [[ -z "$MODELS_DIR" ]]; then
  echo "Error: --models is required." >&2
  usage
fi

if [[ "$PLATFORM" != "rk3588" && "$PLATFORM" != "rk3576" ]]; then
  echo "Error: --platform must be rk3588 or rk3576." >&2
  exit 1
fi

if [[ ! -e /dev/rknpu ]] && [[ ! -e /sys/kernel/debug/rknpu/version ]]; then
  echo "Warning: NPU device/debugfs not found. Check docs/host-config.md." >&2
fi

echo "==> Launching rkllama on ${PLATFORM} (port ${PORT}), serving models from '${MODELS_DIR}'"

rkllama_server \
  --processor "${PLATFORM}" \
  --models "${MODELS_DIR}" \
  --port "${PORT}"
