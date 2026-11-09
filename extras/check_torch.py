# /// script
# requires-python = ">=3.14"
# dependencies = ["torch>=2.15,<3", "numpy>=2.2"]
# ///
"""Check PyTorch on this Mac: version, Apple GPU (MPS) support and a quick speed test.

Run it from anywhere:   uv run check_torch.py
uv reads the block above, builds a throwaway environment with torch, and runs
the script in it. Your projects are not touched.
"""

import platform
import time

import torch


def sync(device: str) -> None:
    """GPU work is queued, not finished, when a call returns. Wait for it before timing."""
    if device == "mps":
        torch.mps.synchronize()


def matmul_tflops(device: str, n: int = 2048, reps: int = 20) -> float:
    a = torch.randn(n, n, device=device)
    b = torch.randn(n, n, device=device)
    for _ in range(3):  # warm-up: the first calls compile and cache GPU kernels
        a @ b
    sync(device)
    start = time.perf_counter()
    for _ in range(reps):
        a @ b
    sync(device)
    seconds = (time.perf_counter() - start) / reps
    return 2 * n**3 / seconds / 1e12  # an n x n matmul is about 2n^3 floating-point operations


def main() -> None:
    print(f"Python {platform.python_version()} on {platform.machine()}, torch {torch.__version__}")
    print(f"MPS built into this torch: {torch.backends.mps.is_built()}")
    print(f"MPS available: {torch.backends.mps.is_available()}")

    devices = ["cpu", "mps"] if torch.backends.mps.is_available() else ["cpu"]
    for device in devices:
        print(f"{device:>4}: {matmul_tflops(device):5.2f} TFLOPS on a 2048 x 2048 float32 matmul")

    if "mps" in devices:
        x = torch.ones(3, device="mps")
        print(f"Tensor on the GPU: {x} (device={x.device})")


if __name__ == "__main__":
    main()
