# rkllama toolbox
#
# Wraps NotPunchnox/rkllama (an Ollama-style server for Rockchip NPUs) plus
# the RKLLM runtime it depends on. Must be built for linux/arm64 — RK3588/
# RK3576 are ARM SoCs.
#
# Upstream now ships rkllama as a pip-installable package (pyproject.toml):
# the rkllm-runtime and rknn-runtime libraries are vendored directly in the
# repo under src/rkllama/lib, and there's no install.sh or top-level
# requirements.txt anymore. RKLLAMA_REF pins an exact commit (instead of
# tracking main) so a future upstream restructuring can't silently break
# this build again the way this one did — bump it deliberately and
# cross-check docs/runtime-compatibility.md (currently: rkllm-runtime 1.3.0 /
# rknn-runtime 2.3.2) when you do.

FROM arm64v8/ubuntu:24.04

LABEL org.opencontainers.image.source="https://github.com/Kikobuf/rk3588-toolboxes"
LABEL org.opencontainers.image.description="rkllama + RKLLM runtime, packaged for toolbox/distrobox"

ARG RKLLAMA_REF=76bda5a4daf143babcd3e9a3d69e63f879c86e04
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        curl \
        git \
        vim \
        htop \
        python3.12 \
        python3.12-dev \
        python3-pip \
        python3.12-venv \
        build-essential \
        cmake \
        ffmpeg \
        libsm6 \
        libxext6 \
        libgomp1 \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

# Ubuntu 24.04 marks the system Python as externally-managed (PEP 668); use
# a venv so `pip install` works without --break-system-packages.
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:${PATH}"

WORKDIR /opt/rkllama

RUN git init -q && \
    git remote add origin https://github.com/NotPunchnox/rkllama.git && \
    git fetch --depth 1 origin "${RKLLAMA_REF}" && \
    git checkout FETCH_HEAD

# librkllmrt.so is loaded by rkllama itself via an absolute path
# (importlib.resources), but librknnrt.so is dlopen'd by soname by the
# rknn-toolkit-lite2 C extension, so it needs to be on the system lib path.
RUN cp src/rkllama/lib/librkllmrt.so src/rkllama/lib/librknnrt.so /usr/lib/ && \
    chmod 755 /usr/lib/librkllmrt.so /usr/lib/librknnrt.so && \
    ldconfig

# Installs rkllama plus its pinned dependencies (Flask, transformers, torch,
# etc.) and the rknn-toolkit-lite2 wheel vendored in src/rkllama/lib.
RUN pip install --no-cache-dir "setuptools<82.0.0" && \
    pip install --no-cache-dir .

# The GGUF/llama.cpp path (rkllama_server's --llamacpp flag) is handled by
# the separate rk-llama-cpp toolbox — see AGENTS.md — so it's left unset here.

EXPOSE 8080

CMD ["/bin/bash"]
