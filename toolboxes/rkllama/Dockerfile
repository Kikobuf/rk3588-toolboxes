# rkllama toolbox
#
# Wraps NotPunchnox/rkllama (an Ollama-style server for Rockchip NPUs) plus
# the RKLLM runtime it depends on. Must be built for linux/arm64 — RK3588/
# RK3576 are ARM SoCs.

FROM arm64v8/ubuntu:24.04

LABEL org.opencontainers.image.source="https://github.com/Kikobuf/rk3588-toolboxes"
LABEL org.opencontainers.image.description="rkllama + RKLLM runtime, packaged for toolbox/distrobox"

ARG RKLLM_RUNTIME_VERSION=1.3.0
ARG RKNN_RUNTIME_VERSION=2.3.2
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        curl \
        git \
        vim \
        htop \
        python3 \
        python3-pip \
        python3-venv \
        build-essential \
        cmake \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/rkllama

RUN git clone --depth 1 https://github.com/NotPunchnox/rkllama.git .

# rkllama's install script pulls in the matching rkllm-runtime + rknn-runtime
# libs for the pinned versions above. See docs/runtime-compatibility.md in
# this repo before bumping these ARGs independently of each other.
RUN chmod +x ./install.sh && \
    RKLLM_VERSION=${RKLLM_RUNTIME_VERSION} RKNN_VERSION=${RKNN_RUNTIME_VERSION} \
    ./install.sh || true

RUN pip install --no-cache-dir --break-system-packages -r requirements.txt || true

ENV LD_LIBRARY_PATH="/opt/rkllama/lib:${LD_LIBRARY_PATH}"

EXPOSE 8080

CMD ["/bin/bash"]
