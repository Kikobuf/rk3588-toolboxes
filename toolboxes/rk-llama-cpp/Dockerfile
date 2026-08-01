# rk-llama-cpp toolbox (EXPERIMENTAL)
#
# Wraps invisiofficial/rk-llama.cpp — an experimental fork bringing GGUF
# model support directly to the RK3588/RK3576 NPU, skipping the RKNN
# conversion step. Expect rougher edges than the rkllama toolbox.
#
# Must be built for linux/arm64.

FROM arm64v8/ubuntu:24.04

LABEL org.opencontainers.image.source="https://github.com/Kikobuf/rk3588-toolboxes"
LABEL org.opencontainers.image.description="Experimental GGUF-on-NPU llama.cpp fork, packaged for toolbox/distrobox"

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

RUN git clone --depth 1 --recurse-submodules \
    https://github.com/invisiofficial/rk-llama.cpp.git .

# Build flags/target may shift as this fork evolves — check upstream's own
# build instructions if this step starts failing after a refresh.
RUN mkdir -p build && cd build && \
    cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release && \
    ninja

WORKDIR /opt/rk-llama.cpp

CMD ["/bin/bash"]
