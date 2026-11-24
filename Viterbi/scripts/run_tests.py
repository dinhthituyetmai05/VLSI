"""Generate a brute-force ML oracle, compile RTL, and run actual HDL simulation."""
import argparse
import json
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def encode(message: int) -> int:
    """Polynomial definition, independent of the decoder's state/ACS implementation."""
    word = 0
    for t in range(8):
        current = (message >> t) & 1
        previous = (message >> (t - 1)) & 1 if t >= 1 else 0
        older = (message >> (t - 2)) & 1 if t >= 2 else 0
        word |= (current ^ previous ^ older) << (2 * t + 1)
        word |= (current ^ older) << (2 * t)
    return word


def run(command: list[str], log_path: Path) -> str:
    result = subprocess.run(command, cwd=ROOT, text=True, capture_output=True)
    output = result.stdout + result.stderr
    log_path.write_text(output, encoding="utf-8")
    print(output.strip())
    if result.returncode:
        raise SystemExit(f"Command failed ({result.returncode}); see {log_path}")
    return output


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--iverilog", default=shutil.which("iverilog"))
    parser.add_argument("--vvp", default=shutil.which("vvp"))
    parser.add_argument("--encoded", type=Path, help="Teacher's output.txt")
    parser.add_argument("--expected", type=Path, help="Teacher's input.txt")
    args = parser.parse_args()
    if not args.iverilog or not args.vvp:
        parser.error("Icarus Verilog required; supply --iverilog and --vvp if absent from PATH")
    if bool(args.encoded) != bool(args.expected):
        parser.error("Supply both --encoded and --expected")
    build = ROOT / "build"
    build.mkdir(exist_ok=True)
    codebook = [encode(message) for message in range(256)]
    assert len(set(codebook)) == 256
    # Equal-distance tie rule: smallest information byte. With LSB-first data,
    # the RTL's lower predecessor/final-state rule gives exactly this ordering.
    print("Generating oracle by exhaustive search over all 256 codewords...")
    oracle_path = build / "oracle.hex"
    with oracle_path.open("w", encoding="ascii") as oracle:
        for received in range(65536):
            message = min(range(256), key=lambda m: (received ^ codebook[m]).bit_count())
            oracle.write(f"{received:04x} {message:02x}\n")
    # Synthetic file fixtures are explicitly separate from the teacher's files.
    encoded_path = build / "sample_output.txt"
    expected_path = build / "sample_input.txt"
    encoded_path.write_text("".join(f"{word:016b}\n" for word in codebook), encoding="ascii")
    expected_path.write_text("".join(f"{message:08b}\n" for message in range(256)), encoding="ascii")
    rtl = [line for line in (ROOT / "src/files.f").read_text().splitlines() if line]
    for top, source, plusargs in [
        ("tb_viterbi_top", "tb/tb_viterbi_top.sv", [f"+VECTORS={oracle_path.as_posix()}"]),
        ("tb_viterbi_files", "tb/tb_viterbi_files.sv",
         [f"+ENCODED={encoded_path.as_posix()}", f"+EXPECTED={expected_path.as_posix()}"]),
    ]:
        executable = build / f"{top}.vvp"
        run([args.iverilog, "-g2012", "-Wall", "-s", top, "-o", str(executable), *rtl, source],
            build / f"{top}_compile.log")
        run([args.vvp, str(executable), *plusargs], build / f"{top}.log")
    if args.encoded:
        run([args.vvp, str(build / "tb_viterbi_files.vvp"),
             f"+ENCODED={args.encoded.resolve().as_posix()}",
             f"+EXPECTED={args.expected.resolve().as_posix()}"], build / "teacher_vectors.log")
    summary = {
        "exhaustive_received_words": 65536,
        "bit_orders_tested": ["LSB first", "MSB first"],
        "clean_messages": 256,
        "reset_abort_recovery_cases": 5,
        "held_enable_frames": 2,
        "synthetic_file_vectors": 256,
        "teacher_vectors_tested": bool(args.encoded),
        "physical_PPA_verified": False,
    }
    (build / "verification_summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
