# Runtime / Driver Compatibility

This is the single most important table in this repo. RKLLM runtime versions are tightly
coupled to specific NPU kernel driver versions — an RKLLM runtime built against the wrong
driver version will typically fail silently, crash on load, or produce garbage output
rather than giving a clear error message.

## Compatibility table

| rkllm-runtime | Required NPU driver | rknn-runtime | Notes                              |
| --------------- | ---------------------- | -------------- | ------------------------------------- |
| 1.3.0 (latest)  | 0.9.8+                 | 2.3.2          | Current `rkllama` default              |
| 1.1.4           | 0.9.8                  | ~2.0.0         |                                         |
| 1.1.1           | 0.9.6                  | ~1.6.0         | **Not** compatible with 0.9.8 driver   |
| 1.0.1           | ~0.9.3                 | ~1.5.0         | Older boards / legacy conversions      |
| 1.0.0           | ~0.9.2                 | ~1.4.0         | Earliest widely-used version           |

> Source of truth for the latest versions: https://github.com/airockchip/rknn-llm/releases
> — always check there before pinning a container build, since Rockchip ships new runtime
> versions fairly frequently and this table will drift out of date.

## How to check what you have

```bash
# NPU driver version (on the host, not in the container)
cat /sys/kernel/debug/rknpu/version

# rkllm-runtime version (inside the container, if already built)
python3 -c "import rkllm; print(rkllm.__version__)" 2>/dev/null || \
  find / -iname "*rkllm*" -name "*.so*" 2>/dev/null
```

## The rule that matters

**Pick your runtime based on your driver, not the other way around.** Your NPU driver
version is fixed by whatever kernel/BSP image your board is running — it's not something
you casually upgrade the way you'd `apt upgrade` a userspace package. If you upgrade the
container's `rkllm-runtime` without a matching driver upgrade (which usually means
flashing a new BSP image), expect breakage.

## Pre-converted model compatibility

Pre-converted `.rkllm` model files (e.g. from
[Pelochus/ezrkllm-collection](https://huggingface.co/Pelochus/ezrkllm-collection)) are
themselves tied to the runtime version they were converted with — a model converted with
runtime 1.0.0 may not load correctly on a 1.3.0 runtime and vice versa. Check the model's
listed conversion runtime version before assuming a downloaded `.rkllm` file will just
work on your setup.
