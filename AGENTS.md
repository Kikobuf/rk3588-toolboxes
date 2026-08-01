# AGENTS.md

Context for AI coding agents (Claude Code, etc.) working on this repo.

## What this repo is

Containerized `toolbox`/`distrobox` images for running LLMs on Rockchip RK3588/RK3576
NPUs via Rockchip's own RKLLM stack (`rkllama` server wrapper), plus a separate
experimental tag for GGUF-on-NPU support. Sibling repos in this family target Intel/AMD
GPUs and Tenstorrent accelerators.

## Key facts to keep in mind when editing

- This is **ARM (aarch64)** hardware, unlike every other toolbox repo in this family
  (Strix Halo, Intel iGPU, Tenstorrent are all x86_64). All Dockerfiles must target
  `linux/arm64` and CI must build on arm runners (or cross-compile via buildx+QEMU).
- RKLLM runtime version and NPU kernel driver version are tightly coupled — a mismatch is
  the #1 support issue. Any change to the pinned `RKLLM_RUNTIME_VERSION` build arg must be
  reflected in `docs/runtime-compatibility.md`, cross-checked against
  https://github.com/airockchip/rknn-llm/releases.
- Models must be converted through RKNN-Toolkit2 on a separate x86_64 machine before they
  can run on the board — this is not something the toolbox containers do themselves. Don't
  imply model conversion happens on-device anywhere in docs.
- The NPU driver ships as part of the board's kernel/BSP image, not as an installable
  userspace package — unlike Intel (oneAPI installer) or Tenstorrent (tt-installer). Don't
  add a "run this script to install the driver" step; it doesn't exist in the same form
  here.
- `rk-llama-cpp` (the GGUF-on-NPU fork) is intentionally kept as a separate, clearly-labeled
  experimental tag — don't promote it to the default/recommended path without a strong
  signal that the upstream fork has matured (feature parity, stability reports, etc.).
- RK3576 supports W4A16 quantization; RK3588 only supports W8A8. Don't conflate the two
  boards' capabilities in docs.

## Things NOT to do

- Don't assume x86_64 patterns from the other toolbox repos transfer directly — always
  double check arch-specific assumptions (base images, buildx platform flags, runner types).
- Don't merge `rkllama` and `rk-llama-cpp` into a single tag — they serve different
  maturity/feature tradeoffs and should stay independently selectable.
- Don't suggest driver/runtime version bumps without checking the compatibility table.
