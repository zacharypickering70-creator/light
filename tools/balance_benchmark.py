"""Run real combat logic with fixed builds, seeds and fresh permanent progression."""
import argparse
import json
import os
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser()
parser.add_argument("--godot", required=True)
parser.add_argument("--output", required=True)
parser.add_argument("--growth", type=float, default=1.035)
args = parser.parse_args()
game = Path(__file__).resolve().parents[1] / "game"
results = []
for build in ("flame", "control", "sustain", "burst"):
    for seed in (4523, 7319, 9021, 1607, 8841):
        process = subprocess.run(
            [args.godot, "--headless", "--path", str(game), "--", "--autoplay",
             f"--build={build}", f"--seed={seed}", f"--growth={args.growth}"],
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=65,
            encoding="utf-8", errors="replace", env=os.environ.copy(),
        )
        lines = process.stdout.splitlines()
        payloads = [line.removeprefix("BALANCE_RESULT ") for line in lines
                    if line.startswith("BALANCE_RESULT ")]
        errors = [line for line in lines if "SCRIPT ERROR" in line or "TEST_TIMEOUT" in line]
        if len(payloads) != 1 or errors:
            raise RuntimeError(f"{build}/{seed}: {process.stdout}")
        result = json.loads(payloads[0])
        results.append(result)
        Path(args.output).write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
        print(build, seed, result["final"], "ultimates", result["ultimates"], flush=True)
