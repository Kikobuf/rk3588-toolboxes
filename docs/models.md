# Converting and Running Models

## Pre-converted models (start here)

Check these sources before converting anything yourself:

- [Pelochus/ezrkllm-collection](https://huggingface.co/Pelochus/ezrkllm-collection) —
  broad collection of pre-converted `.rkllm` models (Llama 2/3, Qwen2, Phi-2, etc.)
- `rkllama`'s own model registry/pull command, if using a version that supports it

Known-working examples from the community collection:

| Model                    | Size  | Converted with runtime | Notes                          |
| -------------------------- | ------- | ------------------------- | --------------------------------- |
| Llama 2 Chat 7B            | 7B    | 1.0.0                      | Not compatible with newer runtimes without reconversion |
| Qwen2 1.5B                 | 1.5B  | 1.0.1                      | Good starting point for smaller boards |
| Llama 3.2 3B               | 3B    | 1.1.1 / 1.1.4              | Runtime-specific builds available |
| Phi-2                      | 2.7B  | 1.0.0                      |                                    |

## Converting a model yourself

Conversion runs on a separate **x86_64** machine using RKNN-Toolkit2 — it does not run on
the RK3588/RK3576 board itself.

```
HF/PyTorch model → ONNX → RKNN-Toolkit2 → .rkllm file → copy to board
```

High-level steps (see [airockchip/rknn-llm](https://github.com/airockchip/rknn-llm) for
the authoritative, up-to-date conversion script and parameters):

1. On an x86_64 PC, install RKNN-Toolkit2 (Python, from Rockchip's SDK)
2. Export your HF model to the format their conversion script expects
3. Run the conversion script, specifying your target platform (`rk3588` or `rk3576`) and
   quantization (`w8a8` for RK3588, `w4a16` or `w8a8` for RK3576)
4. Copy the resulting `.rkllm` file to your board (scp, USB, etc.)
5. Place it where `rkllama` expects model files (check `rkllama`'s own docs/config for
   the exact path — it varies by version)

## Running with rkllama

```bash
./scripts/run_server.sh --model <model-name> --platform rk3588
```

See the main [README's Running the Server section](../README.md#running-the-server) for
the OpenAI-compatible API usage once the server is up.

## Multimodal / TTS / STT

`rkllama` also supports vision models (Qwen2VL/Qwen2.5VL/Qwen3VL/MiniCPMV/InternVL) and
speech models (Piper TTS, MMS-TTS, Whisper/omniASR-CTC for STT) through the same server —
check `rkllama`'s own README for the current model list and endpoint usage, since this
expands faster than this toolbox repo's docs can track reliably.
