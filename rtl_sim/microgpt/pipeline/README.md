# MicroGPT Preparation Pipeline

This directory is reserved for preparing model data for RTL inference.

The initial pipeline stages are:

1. Train MicroGPT.
2. Export the trained parameters as signed 16-bit Q4.12 files.
3. Generate a fixed input-token sequence for replay.

Programs for these stages:

```text
train_and_export.py
generate_input_tokens.py
```

The later reference execution, RTL trace generation, and output comparison
stages will be added separately.
