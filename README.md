# RK3588/RK3576 NPU Toolboxes

Pre-built `toolbox`/`distrobox` containers for running LLMs on **Rockchip RK3588(S) / RK3576**
NPUs (Orange Pi 5 series, Radxa Rock 5/4 series, and other SBCs built on these SoCs) using
Rockchip's own **RKLLM** runtime — since these NPUs are not a llama.cpp backend target the
way Intel/AMD GPUs are.

Companion projects in the same family:
- [`amd-strix-halo-toolboxes`](https://github.com/kyuz0/amd-strix-halo-toolboxes) — AMD Ryzen AI Max "Strix Halo" iGPUs
- `intel-igpu-toolboxes` — Intel Arc / integrated GPUs
- [`tt-metal-toolboxes`](https://github.com/Kikobuf/tt-metal-toolboxes) / [`tt-vllm-toolboxes`](https://github.com/Kikobuf/tt-vllm-toolboxes) — Tenstorrent accelerators

---

## Table of Contents

- [Why This Is a Different Shape of Problem](#why-this-is-a-different-shape-of-problem)
- [Supported Hardware](#supported-hardware)
- [Supported Toolboxes](#supported-toolboxes)
- [Quick Start](#quick-start)
- [Runtime / Driver Compatibility](#runtime--driver-compatibility)
- [Converting Models](#converting-models)
- [Running the Server](#running-the-server)
- [The Experimental GGUF/llama.cpp Path](#the-experimental-ggufllamacpp-path)
- [Host Configuration](#host-configuration)
- [Building Locally](#building-locally)
- [Keeping Updated](#keeping-updated)
- [Troubleshooting](#troubleshooting)
- [References](#references)

---

## Why This Is a Different Shape of Problem

Unlike Intel/AMD GPUs, the RK3588/RK3576 NPU is **not** a llama.cpp backend target.
Models can't run on it directly — they have to be converted through Rockchip's own
toolchain first:

```
HF/PyTorch model → ONNX → RKNN (via RKNN-Toolkit2) → .rkllm → NPU runtime (rkllm-runtime)
```

So "getting llama.cpp running on an RK3588" isn't really the right frame — the working
stack is Rockchip's **RKLLM** SDK plus a community server layer
([**rkllama**](https://github.com/NotPunchnox/rkllama), an Ollama-style wrapper) on top.
There is also an experimental fork bringing GGUF support directly to the NPU, which this
repo tracks separately since it's far less mature — see
[The Experimental GGUF/llama.cpp Path](#the-experimental-ggufllamacpp-path).

The other big difference from your GPU-based toolboxes: **runtime/driver version pinning
is unusually strict here.** A given `rkllm-runtime` version requires an exact matching
NPU kernel driver version — mismatches are the single most common failure mode. See
[Runtime / Driver Compatibility](#runtime--driver-compatibility) before doing anything else.

## Supported Hardware

| SoC     | NPU        | Example Boards                                          | Quantization |
| ------- | ---------- | ----------------------------------------------------------| -------------- |
| RK3588 / RK3588S | 6 TOPS | Orange Pi 5/5 Plus/5 Pro/5 Max, Radxa Rock 5B/5C          | W8A8 only      |
| RK3576  | 6 TOPS     | Radxa Rock 4D, and other newer RK3576 SBCs                | W4A16 + W8A8   |

RK3576's W4A16 support means noticeably smaller model footprints for the same quality —
worth factoring in if you're choosing a board specifically for LLM work rather than reusing
one you already have.

## Supported Toolboxes

| Container Tag  | What it wraps                                                     | Notes                                                    |
| ---------------- | --------------------------------------------------------------------| ----------------------------------------------------------|
| `rkllama`         | [rkllama](https://github.com/NotPunchnox/rkllama) + RKLLM runtime  | Recommended default — OpenAI-compatible endpoints, multimodal, TTS/STT |
| `rk-llama-cpp`    | [invisiofficial/rk-llama.cpp](https://github.com/invisiofficial/rk-llama.cpp) fork | Experimental — GGUF models on NPU, less mature, fewer features |

---

## Quick Start

**Prerequisites:** you're running on an actual RK3588/RK3576 board (aarch64), with the
Rockchip NPU kernel driver already present in your board's kernel/BSP — see
[Host Configuration](#host-configuration).

```bash
toolbox create rkllama \
  --image ghcr.io/kikobuf/rk3588-toolboxes:rkllama \
  -- --device /dev/dri --device /dev/rknpu --group-add video

toolbox enter rkllama
```

*(Ubuntu/Armbian users: use `distrobox create` / `distrobox enter` instead of `toolbox`.)*

### Verify NPU visibility

```bash
cat /sys/kernel/debug/rknpu/version
```

If this fails, the host driver isn't installed correctly — nothing inside the container
will fix that; see [Host Configuration](#host-configuration).

### Launch a server

```bash
./scripts/run_server.sh --model Qwen2.5-1.5B-Instruct --platform rk3588
```

This pulls a pre-converted `.rkllm` model (see [Converting Models](#converting-models) if
you need a model that isn't already converted) and starts an OpenAI-compatible endpoint.

---

## Runtime / Driver Compatibility

This is the table to check **before** filing a "why doesn't this work" issue. RKLLM
runtime versions are tightly coupled to NPU kernel driver versions — a mismatch is the
most common cause of silent failures or crashes.

| rkllm-runtime | Required NPU driver | Notes                                    |
| --------------- | ---------------------- | -------------------------------------------|
| 1.3.0 (latest)  | 0.9.8+                 | Current `rkllama` default                 |
| 1.1.4           | 0.9.8                  |                                             |
| 1.1.1           | 0.9.6                  | Not compatible with 0.9.8 driver           |
| 1.0.1           | 0.9.3 (approx.)         | Older boards / legacy conversions          |
| 1.0.0           | 0.9.2 (approx.)         | Earliest widely-used version               |

> Source of truth: https://github.com/airockchip/rknn-llm/releases — cross-check before
> pinning a container tag. Also check your board vendor's kernel/BSP release notes, since
> the NPU driver ships as part of the kernel image, not as a separate installable package
> on most boards.

**Rule of thumb:** if you didn't build your own kernel, check what NPU driver version your
board's stock image/BSP ships **first**, then pick the matching `rkllm-runtime` — not the
other way around. Upgrading the runtime without a matching kernel/driver upgrade is the
most common source of "it was working, then I updated and it broke" reports.

---

## Converting Models

If the model you want isn't already available pre-converted (check
[Pelochus/ezrkllm-collection](https://huggingface.co/Pelochus/ezrkllm-collection) and the
model list in [`docs/models.md`](docs/models.md) first), convert it yourself:

```
HF/PyTorch model → RKNN-Toolkit2 (runs on x86_64 PC, NOT on the board) → .rkllm file → copy to board
```

Conversion runs on a separate x86_64 machine, not on the RK3588/RK3576 board itself. See
[`docs/models.md`](docs/models.md) for the full conversion walkthrough and known-working
model list.

## Running the Server

```bash
./scripts/run_server.sh \
  --model <model-name-or-path> \
  --platform rk3588 \
  --port 8080
```

Once running, `rkllama` exposes both its own API and OpenAI-compatible endpoints:

```bash
curl http://localhost:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "Qwen2.5-1.5B-Instruct", "messages": [{"role":"user","content":"hello"}]}'
```

## The Experimental GGUF/llama.cpp Path

[`invisiofficial/rk-llama.cpp`](https://github.com/invisiofficial/rk-llama.cpp) is a fork
bringing GGUF model support directly to the NPU, skipping the RKNN conversion step
entirely. This is genuinely experimental — expect missing features, rougher edges, and
less community support than the `rkllama` path. The `rk-llama-cpp` toolbox tag tracks this
fork separately so you can try it without disturbing your main `rkllama` setup.

```bash
toolbox create rk-llama-cpp \
  --image ghcr.io/kikobuf/rk3588-toolboxes:rk-llama-cpp \
  -- --device /dev/dri --device /dev/rknpu --group-add video

toolbox enter rk-llama-cpp
```

Treat this tag as "try it and see" rather than a production recommendation until the
upstream fork matures further.

---

## Host Configuration

See [`docs/host-config.md`](docs/host-config.md) for the full walkthrough. Summary:

- NPU kernel driver ships as part of your board's kernel/BSP image — there's no separate
  userspace driver installer the way Intel/Tenstorrent have one
- `/dev/rknpu` (or equivalent device node — varies slightly by BSP) must be passed through
  to the container
- CPU governor / performance mode tuning matters more here than on desktop-class hardware,
  since these are power-constrained SBCs

## Building Locally

```bash
docker build -t rk3588-toolboxes:rkllama toolboxes/rkllama \
  --platform linux/arm64
```

**Note:** these images must be built on (or cross-compiled for) `linux/arm64` — RK3588/RK3576
are ARM SoCs, unlike every other toolbox repo in this family which targets x86_64. If you're
building from an x86_64 dev machine, use `docker buildx` with QEMU emulation or build directly
on the board.

## Keeping Updated

```bash
./refresh-toolboxes.sh rkllama
./refresh-toolboxes.sh rk-llama-cpp
```

---

## Troubleshooting

- **`/sys/kernel/debug/rknpu/version` missing or errors** → NPU driver not present in your
  kernel/BSP, or debugfs not mounted. Check your board vendor's kernel documentation.
- **Model loads then crashes/produces garbage output** → almost always a
  rkllm-runtime/driver version mismatch. Check the
  [compatibility table](#runtime--driver-compatibility).
- **Conversion fails on the board itself** → RKNN-Toolkit2 conversion must run on an
  x86_64 PC, not on the ARM board. Convert elsewhere, then copy the `.rkllm` file over.
- **Slow performance vs. published benchmarks** → confirm the CPU governor is set to
  `performance` and the board isn't thermal-throttling (RK3588 SBCs commonly need active
  cooling to sustain NPU load).

---

## References

- [airockchip/rknn-llm](https://github.com/airockchip/rknn-llm) — official RKLLM SDK + runtime
- [NotPunchnox/rkllama](https://github.com/NotPunchnox/rkllama) — Ollama-style server wrapper
- [invisiofficial/rk-llama.cpp](https://github.com/invisiofficial/rk-llama.cpp) — experimental GGUF-on-NPU fork
- [Pelochus/ezrkllm-collection](https://huggingface.co/Pelochus/ezrkllm-collection) — pre-converted models
- [RKNN-Toolkit2](https://github.com/airockchip/rknn-toolkit2) — model conversion SDK

## Support

Hobby project, same spirit as the other toolbox repos in this family. Issues and PRs welcome.
