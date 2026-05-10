from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageChops, ImageDraw, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SHOWCASE_DIR = ROOT / "docs" / "showcase" / "screenshots"
ACTUAL_DIR = Path(
    __import__("os").environ.get(
        "VISUAL_ACTUAL_DIR",
        ROOT / "output" / "parity" / "route_audit_runtime" / "screenshots",
    )
)
OUT_DIR = ROOT / "output" / "parity" / "visual_diff"
REPORT = OUT_DIR / "visual_diff_report.md"


def normalized_diff(showcase: Image.Image, actual: Image.Image) -> tuple[float, Image.Image]:
    showcase = showcase.convert("RGB")
    actual = actual.convert("RGB").resize(showcase.size)
    diff = ImageChops.difference(showcase, actual)
    histogram = diff.histogram()
    channels = 3
    max_score = showcase.size[0] * showcase.size[1] * 255 * channels
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

    for showcase_path in sorted(SHOWCASE_DIR.glob("*.png")):
        actual_path = ACTUAL_DIR / showcase_path.name
        if not actual_path.exists():
            rows.append((showcase_path.name, "missing", 100.0, "", "actual screenshot missing"))
            continue

        showcase = Image.open(showcase_path)
        actual = Image.open(actual_path)
        score, diff = normalized_diff(showcase, actual)

        diff_path = OUT_DIR / f"{showcase_path.stem}_diff.png"
        diff.save(diff_path)

        status = "pass" if score <= 8 else "review" if score <= 18 else "fail"
        note = "within threshold" if status == "pass" else "manual visual review required"
        rows.append((showcase_path.name, status, score, diff_path.name, note))

        thumb_size = (160, 346)
        panels = [
            label(ImageOps.fit(showcase, thumb_size), "showcase"),
            label(ImageOps.fit(actual, thumb_size), "actual"),
            label(ImageOps.fit(diff, thumb_size), f"diff {score:.1f}%"),
        ]
        triptych = Image.new("RGB", (thumb_size[0] * 3 + 24, thumb_size[1] + 28), "white")
        x = 0
        for panel in panels:
            triptych.paste(panel, (x, 0))
            x += thumb_size[0] + 12
        triptychs.append((showcase_path.stem, triptych))

    contact_cols = 2
    gap = 18
    if triptychs:
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
      contact.save(OUT_DIR / "visual_diff_contact_sheet.png")

    lines = [
        "# Visual Diff Report",
        "",
        "Thresholds:",
        "",
        "- pass: <= 8%",
        "- review: > 8% and <= 18%",
        "- fail: > 18%",
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
