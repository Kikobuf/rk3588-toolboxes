# rk-llama-cpp toolbox (EXPERIMENTAL)
#
# Wraps invisiofficial/rk-llama.cpp — an experimental fork bringing GGUF
# model support directly to the RK3588/RK3576 NPU, skipping the RKNN
# conversion step. Expect rougher edges than the rkllama toolbox.
#
# Must be built for linux/arm64.
#
# The Rockchip NPU backend is opt-in via -DLLAMA_RKNPU2=ON (off by default in
# upstream's CMakeLists) — see ggml/src/ggml-rknpu2/README.md upstream for
# the canonical build steps. The librknnrt.so/headers it links against are
# vendored directly in the repo under ggml/src/ggml-rknpu2/libs, no separate
# download needed. RK_LLAMA_CPP_REF pins an exact commit (instead of tracking
# this fast-moving fork's main branch) so an upstream restructuring can't
# silently break this build again.

FROM arm64v8/ubuntu:24.04

LABEL org.opencontainers.image.source="https://github.com/Kikobuf/rk3588-toolboxes"
LABEL org.opencontainers.image.description="Experimental GGUF-on-NPU llama.cpp fork, packaged for toolbox/distrobox"

ARG RK_LLAMA_CPP_REF=81eff6a45c6abbb99e26907ef7fe8f7bf3ed2c62
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        curl \
        git \
        vim \
        htop \
        build-essential \
        cmake \
        ninja-build \
        python3 \
        python3-pip \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/rk-llama.cpp

RUN git init -q && \
    git remote add origin https://github.com/invisiofficial/rk-llama.cpp.git && \
    git fetch --depth 1 origin "${RK_LLAMA_CPP_REF}" && \
    git checkout FETCH_HEAD

# LLAMA_RKNPU2 is required to actually build the NPU backend — without it
# this silently produces a CPU-only llama.cpp build.
RUN mkdir -p build && cd build && \
    cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DLLAMA_RKNPU2=ON && \
    ninja

# The rknpu2 backend only resolves librknnrt.so at link time via
# rpath-link, which isn't embedded in the binary — copy it onto the system
# lib path so the built binaries can dlopen it at runtime too.
RUN cp ggml/src/ggml-rknpu2/libs/librknnrt.so /usr/lib/ && \
    chmod 755 /usr/lib/librknnrt.so && ldconfig

WORKDIR /opt/rk-llama.cpp

CMD ["/bin/bash"]
