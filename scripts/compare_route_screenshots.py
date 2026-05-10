from __future__ import annotations

import os
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SCREENSHOT_DIR = Path(
    os.environ.get(
        "PARITY_SCREENSHOT_DIR",
        ROOT / "output" / "parity" / "route_audit_screenshot_mode" / "screenshots",
    )
)
RUNTIME_DIR = Path(
    os.environ.get(
        "PARITY_RUNTIME_DIR",
        ROOT / "output" / "parity" / "route_audit_runtime" / "screenshots",
    )
)
OUT_DIR = Path(
    os.environ.get(
        "PARITY_DIFF_OUTPUT_DIR",
        ROOT / "output" / "parity" / "runtime_vs_screenshot",
    )
)
REPORT = OUT_DIR / "runtime_vs_screenshot_report.md"


def normalized_diff(left: Image.Image, right: Image.Image) -> tuple[float, Image.Image]:
    left = left.convert("RGB")
    right = right.convert("RGB").resize(left.size)
    diff = ImageChops.difference(left, right)
    histogram = diff.histogram()
    channels = 3
    max_score = left.size[0] * left.size[1] * 255 * channels
    score = sum(value * (index % 256) for index, value in enumerate(histogram)) / max_score
    return score * 100, diff


def label(image: Image.Image, text: str) -> Image.Image:
    band = Image.new("RGB", (image.width, image.height + 28), "white")
    band.paste(image, (0, 0))
    draw = ImageDraw.Draw(band)
    draw.text((8, image.height + 8), text, fill="black")
    return band


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    rows = []
    triptychs = []

    for screenshot_path in sorted(SCREENSHOT_DIR.glob("*.png")):
        runtime_path = RUNTIME_DIR / screenshot_path.name
        if not runtime_path.exists():
            rows.append((screenshot_path.name, "missing", 100.0, "", "runtime screenshot missing"))
            continue

        screenshot = Image.open(screenshot_path)
        runtime = Image.open(runtime_path)
        score, diff = normalized_diff(screenshot, runtime)
        diff_path = OUT_DIR / f"{screenshot_path.stem}_diff.png"
        diff.save(diff_path)

        status = "pass" if score <= 2 else "review" if score <= 8 else "fail"
        note = "consistent" if status == "pass" else "manual review required"
        rows.append((screenshot_path.name, status, score, diff_path.name, note))

        thumb_size = (160, 346)
        panels = [
            label(ImageOps.fit(screenshot, thumb_size), "screenshot mode"),
            label(ImageOps.fit(runtime, thumb_size), "runtime"),
            label(ImageOps.fit(diff, thumb_size), f"diff {score:.1f}%"),
        ]
        triptych = Image.new("RGB", (thumb_size[0] * 3 + 24, thumb_size[1] + 28), "white")
        x = 0
        for panel in panels:
            triptych.paste(panel, (x, 0))
            x += thumb_size[0] + 12
        triptychs.append((screenshot_path.stem, triptych))

    if triptychs:
        contact_cols = 2
        gap = 18
        cell_w = triptychs[0][1].width
        cell_h = triptychs[0][1].height + 22
        rows_count = (len(triptychs) + contact_cols - 1) // contact_cols
        contact = Image.new(
            "RGB",
            (contact_cols * cell_w + (contact_cols + 1) * gap, rows_count * cell_h + (rows_count + 1) * gap),
            "white",
        )
        draw = ImageDraw.Draw(contact)
        for index, (name, image) in enumerate(triptychs):
            col = index % contact_cols
            row = index // contact_cols
            x = gap + col * (cell_w + gap)
            y = gap + row * (cell_h + gap)
            contact.paste(image, (x, y))
            draw.text((x, y + image.height + 4), name, fill="black")
        contact.save(OUT_DIR / "runtime_vs_screenshot_contact_sheet.png")

    lines = [
        "# Runtime vs Screenshot Mode Report",
        "",
        "Thresholds:",
        "",
        "- pass: <= 2%",
        "- review: > 2% and <= 8%",
        "- fail: > 8%",
        "",
        "| Screenshot | Status | Diff | Diff image | Note |",
        "|---|---|---:|---|---|",
    ]
    for name, status, score, diff_name, note in rows:
        lines.append(f"| {name} | {status} | {score:.2f}% | {diff_name} | {note} |")

    REPORT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Wrote {REPORT}")
    fail_count = sum(1 for _, status, *_ in rows if status == "fail")
    review_count = sum(1 for _, status, *_ in rows if status == "review")
    print(f"pass={len(rows) - fail_count - review_count} review={review_count} fail={fail_count}")
    return 1 if fail_count else 0


if __name__ == "__main__":
    raise SystemExit(main())
