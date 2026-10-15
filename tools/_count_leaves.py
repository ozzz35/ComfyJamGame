import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_R = 75
DEFAULT_D = 0.02
DEFAULT_S = 0.75


def leaf_count(r: int, d: float, s: float) -> int:
    return round(r * r * s * d)


def parse_piles(path: Path) -> list[tuple[str, int, float, float, int]]:
    text = path.read_text(encoding="utf-8")
    piles: list[tuple[str, int, float, float, int]] = []
    pattern = re.compile(
        r'\[node name="(LeafPile[^"]*)" parent="Leaves"[^\]]*\](.*?)(?=\n\[node name=|\Z)',
        re.DOTALL,
    )
    for m in pattern.finditer(text):
        name, body = m.group(1), m.group(2)
        r, d, s = DEFAULT_R, DEFAULT_D, DEFAULT_S
        for line in body.splitlines():
            line = line.strip()
            if line.startswith("pile_radius"):
                r = int(float(line.split("=", 1)[1].strip()))
            elif line.startswith("density"):
                d = float(line.split("=", 1)[1].strip())
            elif line.startswith("squish"):
                s = float(line.split("=", 1)[1].strip())
        piles.append((name, r, d, s, leaf_count(r, d, s)))
    return piles


def main() -> None:
    scenes = [
        ("Tutorial (job.tscn)", ROOT / "scenes/jobs/job.tscn"),
        ("Job 1 (job1.tscn)", ROOT / "scenes/jobs/job1.tscn"),
        ("Job 2 (job2.tscn)", ROOT / "scenes/jobs/job2.tscn"),
        ("Job 3 (job3.tscn)", ROOT / "scenes/jobs/job3.tscn"),
    ]
    rows = []
    for label, path in scenes:
        piles = parse_piles(path)
        total = sum(c for *_, c in piles)
        counts = sorted(c for *_, c in piles)
        rows.append((label, len(piles), total, counts))
        print(f"=== {label} ===")
        print(f"Piles: {len(piles)}  |  Leaves: {total}")
        if counts:
            mid = counts[len(counts) // 2]
            print(f"Per pile (min / median / max): {counts[0]} / {mid} / {counts[-1]}")
        print()

    print("--- Comparison (runtime spawn count, same as yard_level._count_leaves) ---")
    for label, n_piles, total, _ in sorted(rows, key=lambda x: x[2]):
        print(f"{label:24} {total:5} leaves  ({n_piles} piles)")


if __name__ == "__main__":
    main()
