#!/usr/bin/env python3
"""VIS-05 academic PDF: replace only Figures 7-9 after strict SHA-256 preflight.

Git branch provenance required before gate execution. Does not modify source files,
Git main, QlikView binaries, or other PDF pages. Keeps a JSON audit beside output.
"""
import argparse
import hashlib
import io
import json
from pathlib import Path

import fitz
from PIL import Image

SOURCE_NAME = "SAD_Data_Mart_SUS_PB_DOC_R3_Entrega_Final_VIS04_2026.pdf"
TARGET_NAME = "SAD_Data_Mart_SUS_PB_DOC_R3_Entrega_Final_VIS05_2026.pdf"
SOURCE_SHA = "BB7A6A6D7C2ADC3BE80831F4F8E98642D7CE9D07A25B7F03000A9DF2E8071302"
FIGURES = {
    21: {
        "file": "image(20261115-125358).png",
        "sha": "144F0CBCED0AFD20E6FC921EDA21617D6BB6A5C949615DB6E69FCDE0A3E05B71",
        "caption": "Figura 7 — Produção Hospitalar: internações por ano, ranking SERV e série mensal. Fonte: QlikView VIS-05 após reabertura, 15/11/2026.",
        "caption_rect": (49, 339.9, 546, 369),
    },
    22: {
        "file": "image(20261115-125414).png",
        "sha": "01970300310460CC5CE6F00A88903F267CDDE3DE435DB5A56168A2714CE294E1",
        "caption": "Figura 8 — Leitos Cadastrais Observados, com legendas M2-03 corrigidas. Fonte: QlikView VIS-05 após reabertura, 15/11/2026.",
        "caption_rect": (49, 285.9, 546, 314),
    },
    23: {
        "file": "image(20261115-125441).png",
        "sha": "96C539895F6C88345EFFDCE68DE685DC7CBD2A8683ECEAB8EF7E2125EE3EA802",
        "caption": "Figura 9 — Fluxos RES/SERV, pares dirigidos e população anual. Fonte: QlikView VIS-05 após reabertura, 15/11/2026.",
        "caption_rect": (49, 285.9, 546, 314),
    },
}
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def page_other_text(page, caption_rect):
    """Verify text unaffected outside the original figure-caption zone."""
    r = fitz.Rect(caption_rect)
    out = []
    for b in page.get_text("dict")["blocks"]:
        if b.get("type") != 0:
            continue
        for line in b["lines"]:
            for s in line["spans"]:
                if fitz.Rect(s["bbox"]).intersects(r):
                    continue
                out.append((s["text"], tuple(round(v, 2) for v in s["bbox"])))
    return out


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input-dir", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    src_path = args.input_dir / SOURCE_NAME
    out_path = args.output_dir / TARGET_NAME
    audit_path = args.output_dir / (TARGET_NAME + ".audit.json")
    if not src_path.is_file() or sha(src_path) != SOURCE_SHA:
        raise SystemExit("BLOCKED_SOURCE_SHA_MISMATCH_OR_MISSING")
    if not Path(FONT).is_file():
        raise SystemExit("BLOCKED_FONT_MISSING")
    if out_path.exists() or audit_path.exists():
        raise SystemExit("BLOCKED_REFUSE_OVERWRITE_OUTPUT")
    for cfg in FIGURES.values():
        p = args.input_dir / cfg["file"]
        if not p.is_file() or sha(p) != cfg["sha"]:
            raise SystemExit("BLOCKED_IMAGE_SHA_MISMATCH_OR_MISSING: " + cfg["file"])

    doc = fitz.open(src_path)
    if len(doc) != 98:
        raise SystemExit("BLOCKED_PAGE_COUNT")
    figures_manifest = {}
    for index, cfg in FIGURES.items():
        page = doc[index]
        before_text = page_other_text(page, cfg["caption_rect"])
        images = page.get_images(full=True)
        if len(images) != 1 or len(page.get_image_rects(images[0][0])) != 1:
            raise SystemExit("BLOCKED_IMAGE_LAYOUT_PAGE_" + str(index + 1))
        image_xref = images[0][0]
        image_rect = page.get_image_rects(image_xref)[0]
        if not (495 < image_rect.width < 505 and 190 < image_rect.height < 205):
            raise SystemExit("BLOCKED_FIGURE_GEOMETRY_PAGE_" + str(index + 1))
        with Image.open(args.input_dir / cfg["file"]) as picture:
            if picture.width < 1600 or picture.height < 1000:
                raise SystemExit("BLOCKED_IMAGE_DIMENSIONS")
            # Preserve every chart and entire sheet, without application chrome/taskbar.
            crop = (0, 120, picture.width, 968)
            cropped = picture.convert("RGB").crop(crop)
            stream = io.BytesIO()
            cropped.save(stream, format="PNG", optimize=True)
        page.replace_image(image_xref, stream=stream.getvalue())
        caption_rect = fitz.Rect(cfg["caption_rect"])
        page.add_redact_annot(caption_rect, fill=(1, 1, 1))
        page.apply_redactions(images=0, graphics=0, text=0)
        font = f"VIS05_FIG_{index + 1}"
        page.insert_font(fontname=font, fontfile=FONT)
        inserted = page.insert_textbox(
            caption_rect, cfg["caption"], fontname=font, fontsize=7.1,
            align=fitz.TEXT_ALIGN_CENTER, lineheight=1.32,
            color=(0.23, 0.32, 0.36), overlay=True,
        )
        if inserted < 0:
            raise SystemExit("BLOCKED_CAPTION_OVERFLOW_PAGE_" + str(index + 1))
        if page_other_text(page, cfg["caption_rect"]) != before_text:
            raise SystemExit("BLOCKED_NON_CAPTION_TEXT_DRIFT_PAGE_" + str(index + 1))
        figures_manifest[str(index + 1)] = {
            "figure": index - 14,
            "file": cfg["file"], "image_sha256": cfg["sha"],
            "crop": crop, "figure_rect": tuple(image_rect),
            "caption": cfg["caption"], "caption_rect": tuple(caption_rect),
        }
    args.output_dir.mkdir(parents=True, exist_ok=True)
    doc.save(out_path, garbage=3, deflate=True)
    doc.close()
    old = fitz.open(src_path)
    new = fitz.open(out_path)
    if len(old) != len(new) or len(new) != 98:
        raise SystemExit("BLOCKED_OUTPUT_PAGE_COUNT")
    preserved = []
    changed = []
    for i in range(98):
        a, b = old[i], new[i]
        if i in FIGURES:
            cfg = FIGURES[i]
            if page_other_text(a, cfg["caption_rect"]) != page_other_text(b, cfg["caption_rect"]):
                raise SystemExit("BLOCKED_CHANGED_PAGE_NONFIGURE_DRIFT_" + str(i + 1))
            if len(b.get_images(full=True)) != 1 or "VIS-05" not in b.get_text():
                raise SystemExit("BLOCKED_FIGURE_MISSING_" + str(i + 1))
            if a.get_pixmap(matrix=fitz.Matrix(0.9, 0.9), alpha=False).samples == b.get_pixmap(matrix=fitz.Matrix(0.9, 0.9), alpha=False).samples:
                raise SystemExit("BLOCKED_FIGURE_NOT_CHANGED_" + str(i + 1))
            changed.append(i + 1)
            continue
        if a.rect != b.rect or a.rotation != b.rotation or a.get_text() != b.get_text():
            raise SystemExit("BLOCKED_TEXT_GEOMETRY_DRIFT_" + str(i + 1))
        if len(a.get_images(full=True)) != len(b.get_images(full=True)):
            raise SystemExit("BLOCKED_IMAGE_COUNT_DRIFT_" + str(i + 1))
        if a.get_pixmap(matrix=fitz.Matrix(0.7, 0.7), alpha=False).samples != b.get_pixmap(matrix=fitz.Matrix(0.7, 0.7), alpha=False).samples:
            raise SystemExit("BLOCKED_RENDER_DRIFT_" + str(i + 1))
        preserved.append(i + 1)
    if len(preserved) != 95 or changed != [22, 23, 24]:
        raise SystemExit("BLOCKED_SCOPE_DRIFT")
    audit = {
        "gate": "VIS05_ACADEMIC_FIGURES_DOCUMENTARY",
        "status": "PASS_RESTRICTED_PDF_INTEGRITY_ONLY",
        "source_path": str(src_path), "source_sha256": sha(src_path),
        "output_path": str(out_path), "output_sha256": sha(out_path),
        "pages": 98, "modified_pages": changed,
        "preserved_pages_count": len(preserved),
        "preserved_pages_text_geometry_and_render": "95/95_EQUAL",
        "changed_pages_noncaption_text": "UNCHANGED",
        "figures": figures_manifest,
        "limits": [
            "VIS-05 QVW only verified by local operator; not examined in this environment",
            "Municipalities of residence outside PB may lack descriptive names",
            "M3-01 labels not globally certified dynamic under selections",
            "CNES/LT historical hospital coverage and C2/C3/C4 not approved",
            "Online rehearsal, teacher acceptance, submission and production not approved",
        ],
    }
    audit_path.write_text(json.dumps(audit, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(audit, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
