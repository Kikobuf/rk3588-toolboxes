# Host Configuration

RK3588/RK3576 boards are ARM SBCs with an on-die NPU — there's no separate discrete
accelerator to pass through the way there is with Intel Arc or Tenstorrent PCIe cards.
The NPU driver ships as part of the board's kernel/BSP image itself.

## 1. Confirm your kernel has NPU support

Most vendor images (Orange Pi's, Radxa's, Armbian's RK3588/RK3576 builds) include the
RKNPU driver already. Verify:

```bash
ls /dev/rknpu* 2>/dev/null || echo "device node not found"
cat /sys/kernel/debug/rknpu/version 2>/dev/null || echo "driver info not available"
```

If neither works, you likely need a different kernel/BSP image — this is not something
fixable from inside a container.

## 2. Note your driver version before choosing a runtime

```bash
cat /sys/kernel/debug/rknpu/version
```

Cross-check this against [`docs/runtime-compatibility.md`](runtime-compatibility.md) /
the main README's compatibility table **before** picking an `rkllm-runtime` version to
build the container with. Getting this backwards (picking the runtime first, then hoping
the driver matches) is the most common setup mistake.

## 3. Passing the NPU through to the container

```bash
toolbox create rkllama \
  --image ghcr.io/kikobuf/rk3588-toolboxes:rkllama \
  -- --device /dev/dri --device /dev/rknpu --group-add video
```

Some BSPs expose the NPU under a slightly different device path — check `ls /dev/rk*`
on your specific board/image if `/dev/rknpu` doesn't exist.

## 4. CPU governor / thermal management

These are power- and thermal-constrained SBCs, unlike desktop GPUs. Sustained NPU load
without adequate cooling will throttle:

```bash
sudo apt-get install cpufrequtils
sudo cpupower frequency-set -g performance
```

Active cooling (fan, not just a heatsink) is recommended for sustained inference
workloads on RK3588 boards — passive cooling is fine for short bursts but will throttle
under continuous load.

## 5. Memory considerations

Unlike discrete GPUs, RK3588/RK3576 boards use shared system RAM for the NPU. Larger
models will compete with the OS and any other running processes for the same memory pool
— leave headroom rather than assuming all onboard RAM is available to the model.

## 6. Cross-architecture build note

If you're building these toolbox images from an x86_64 development machine rather than
on the board itself, use `docker buildx` with QEMU emulation:

```bash
docker buildx build --platform linux/arm64 -t rk3588-toolboxes:rkllama toolboxes/rkllama
```

Native builds on the board itself are simpler but slower; cross-builds are faster but
require buildx/QEMU setup on the host.
