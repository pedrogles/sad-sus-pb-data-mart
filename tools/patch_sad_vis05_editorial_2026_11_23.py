#!/usr/bin/env python3
"""Apply authorized AUD-01 editorial treatment only on PDF physical page 22.
Keep original figure pixels, header/footer, all 97 other pages and the input PDF.
Also render the versioned AUD-10 presentation script as a separate two-page PDF.
Run only after this script and the Markdown are committed to the canonical repo.
"""
import argparse
import hashlib
import html
import io
import json
import re
import subprocess
from pathlib import Path
import fitz
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.pagesizes import A4
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak

SOURCE_SHA = "4C6033F3131F4B05105BBFCD992A2A6E7896CD5A2D424BF0BEA513430D0ED9F3"
SOURCE_NAME = "SAD_Data_Mart_SUS_PB_DOC_R3_Entrega_Final_VIS05_2026.pdf"
TARGET_NAME = "SAD_Data_Mart_SUS_PB_DOC_R3_VIS05_Revisado_2026-11-23.pdf"
SCRIPT_NAME = "SAD_VIS05_Roteiro_Apresentacao_2026-11-23.pdf"
MD_REL = "docs/academic/vis05-presentation-script-2026-11-23.md"
ZONES = (fitz.Rect(48, 81, 548, 132), fitz.Rect(48, 338, 548, 680))
NORMAL = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
INTRO = ("Esta folha analisa o volume de novas internações administrativas por competência, de 2017 a 2019. "
         "A medida QTD_INTERNACAO não conta como novas internações as AIHs de continuidade, identificadas por "
         "IDENT=5. Os resultados não correspondem a pacientes únicos nem à demanda reprimida.")
CAPTION = ("Figura 7 — Produção Hospitalar: novas internações por ano de competência, ranking SERV e série mensal. "
           "Fonte: QlikView VIS-05 após reabertura, 15/11/2026.")
NOTE = ("<b>Nota de leitura:</b> no M1-01, “Ano da Internação”, exibido na captura, deve ser lido como "
        "“Ano de competência”. A análise utiliza PERIODO_ANO, derivado da competência administrativa "
        "do SIH/RD, e não o ano da data clínica de admissão. A medida e a agregação permanecem inalteradas.")
COMMENTS = (
    ("<b>M1-01 — Novas internações por ano de competência.</b> Os oráculos reportados indicam "
     "183.532 (2017), 183.311 (2018) e 188.246 (2019), totalizando 555.089 novas internações "
     "administrativas. Não foram recalculados neste DOC-R3."),
    ("<b>M1-02 — Evolução mensal.</b> A série apresenta 36 competências administrativas, de janeiro "
     "de 2017 a dezembro de 2019, sem inferência causal das flutuações exibidas."),
    ("<b>M1-03 — Distribuição por município.</b> O ranking representa o município de atendimento "
     "(SERV), distinto do município de residência (RES). A VIS-03 comprovou visualmente a navegação "
     "pelas categorias roladas, mas não auditou todos os totais municipais."),
)

def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest().upper()

def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()

def outside_text(page):
    result = []
    for block in page.get_text("dict")["blocks"]:
        if block.get("type") != 0:
            continue
        for line in block["lines"]:
            for span in line["spans"]:
                if not any(fitz.Rect(span["bbox"]).intersects(zone) for zone in ZONES):
                    result.append((span["text"], tuple(round(x, 2) for x in span["bbox"])))
    return result

def paragraph(c, text, y, size=9.65, leading=14.7, height=60, x=48, width=499.2756, center=False):
    style = ParagraphStyle("p", fontName="SadNormal", fontSize=size, leading=leading,
                           textColor=colors.HexColor("#20343c"), alignment=TA_CENTER if center else 0)
    p = Paragraph(text, style)
    _, h = p.wrap(width, height)
    if h > height:
        raise RuntimeError("TEXT_OVERFLOW: " + text[:70])
    p.drawOn(c, x, A4[1] - y - h)
    return h

def md_html(text):
    return re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", html.escape(text))

def render_script(md, target):
    styles = {
        "title": ParagraphStyle("title", fontName="SadBold", fontSize=17, leading=21, spaceAfter=12, textColor=colors.HexColor("#004e5b")),
        "h2": ParagraphStyle("h2", fontName="SadBold", fontSize=11, leading=14, spaceBefore=10, spaceAfter=5, textColor=colors.HexColor("#004e5b"), keepWithNext=True),
        "body": ParagraphStyle("body", fontName="SadNormal", fontSize=9.5, leading=13.3, spaceAfter=7, textColor=colors.HexColor("#20343c")),
    }
    flow = []
    for raw in md.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line:
            continue
        if line == "---":
            flow.append(PageBreak())
        elif line.startswith("# "):
            flow.append(Paragraph(md_html(line[2:]), styles["title"]))
        elif line.startswith("## "):
            flow.append(Paragraph(md_html(line[3:]), styles["h2"]))
        else:
            flow.append(Paragraph(md_html(line), styles["body"]))
    def footer(c, doc):
        c.setFont("SadNormal", 8)
        c.setFillColor(colors.HexColor("#5c6d73"))
        c.drawString(42, 28, "SAD / VIS-05 | roteiro para ensaio | 23/11/2026")
        c.drawRightString(A4[0]-42, 28, str(doc.page))
    SimpleDocTemplate(str(target), pagesize=A4, leftMargin=42, rightMargin=42, topMargin=35, bottomMargin=44).build(flow, onFirstPage=footer, onLaterPages=footer)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--source", required=True, type=Path)
    ap.add_argument("--output-dir", required=True, type=Path)
    ap.add_argument("--expected-commit", required=True)
    args = ap.parse_args()
    root = Path(__file__).resolve().parents[1]
    commit = git(root, "rev-parse", "HEAD")
    if commit != args.expected_commit:
        raise SystemExit("BLOCKED_CODE_COMMIT_MISMATCH")
    for rel in ("tools/patch_sad_vis05_editorial_2026_11_23.py", MD_REL):
        if git(root, "rev-parse", "HEAD:"+rel) != git(root, "hash-object", "--", str(root/rel)):
            raise SystemExit("BLOCKED_UNCOMMITTED_SOURCE")
    if args.source.name != SOURCE_NAME or sha(args.source) != SOURCE_SHA:
        raise SystemExit("BLOCKED_SOURCE_PIN")
    for name in (NORMAL, BOLD):
        if not Path(name).is_file():
            raise SystemExit("BLOCKED_FONT_MISSING")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    target = args.output_dir/TARGET_NAME
    script_pdf = args.output_dir/SCRIPT_NAME
    audit = args.output_dir/"SAD_VIS05_Revisao_Editorial_2026-11-23.audit.json"
    if any(p.exists() for p in (target, script_pdf, audit)):
        raise SystemExit("BLOCKED_REFUSE_OVERWRITE_OUTPUT")
    pdfmetrics.registerFont(TTFont("SadNormal", NORMAL))
    pdfmetrics.registerFont(TTFont("SadBold", BOLD))
    pdfmetrics.registerFontFamily("SadNormal", normal="SadNormal", bold="SadBold")
    doc = fitz.open(args.source)
    if len(doc) != 98:
        raise SystemExit("BLOCKED_EXPECTED_98_PAGES")
    page = doc[21]
    before_outside = outside_text(page)
    images = page.get_images(full=True)
    if len(images) != 1:
        raise SystemExit("BLOCKED_FIGURE_LAYOUT")
    figure_sha = hashlib.sha256(doc.extract_image(images[0][0])["image"]).hexdigest()
    figure_rect = tuple(page.get_image_rects(images[0][0])[0])
    for zone in ZONES:
        page.add_redact_annot(zone, fill=(1, 1, 1))
    page.apply_redactions(images=0, graphics=0, text=0)
    overlay = io.BytesIO()
    c = canvas.Canvas(overlay, pagesize=A4)
    paragraph(c, html.escape(INTRO), 84, height=48)
    paragraph(c, html.escape(CAPTION), 340, size=7.1, leading=9.5, height=24, center=True)
    c.setFillColor(colors.HexColor("#eef5f6"))
    c.roundRect(48, A4[1]-435, 499.2756, 66, 4, fill=1, stroke=0)
    paragraph(c, NOTE, 375, size=8.3, leading=12, height=54, x=57, width=481.2756)
    paragraph(c, COMMENTS[0], 450, height=64)
    paragraph(c, COMMENTS[1], 527, height=43)
    paragraph(c, COMMENTS[2], 583, height=65)
    c.save()
    over = fitz.open(stream=overlay.getvalue(), filetype="pdf")
    page.show_pdf_page(page.rect, over, 0)
    doc.save(target, garbage=3, deflate=True)
    doc.close()
    old, new = fitz.open(args.source), fitz.open(target)
    if len(new) != 98 or outside_text(new[21]) != before_outside:
        raise SystemExit("BLOCKED_PAGE22_OUTSIDE_TEXT_DRIFT")
    new_images = new[21].get_images(full=True)
    if len(new_images) != 1 or hashlib.sha256(new.extract_image(new_images[0][0])["image"]).hexdigest() != figure_sha or tuple(new[21].get_image_rects(new_images[0][0])[0]) != figure_rect:
        raise SystemExit("BLOCKED_FIGURE_CHANGED")
    preserved = []
    for i in range(98):
        if i == 21:
            continue
        a, b = old[i], new[i]
        if a.rect != b.rect or a.rotation != b.rotation or a.get_text() != b.get_text():
            raise SystemExit("BLOCKED_TEXT_GEOMETRY_DRIFT_PAGE_"+str(i+1))
        if a.get_pixmap(alpha=False).samples != b.get_pixmap(alpha=False).samples:
            raise SystemExit("BLOCKED_RENDER_DRIFT_PAGE_"+str(i+1))
        preserved.append(i+1)
    text = new[21].get_text()
    for required in ("Ano de competência", "183.532", "183.311", "188.246", "555.089", "36 competências"):
        if required not in text:
            raise SystemExit("BLOCKED_REQUIRED_TEXT_MISSING: "+required)
    if len(preserved) != 97 or sha(args.source) != SOURCE_SHA:
        raise SystemExit("BLOCKED_PRESERVATION")
    render_script(root/MD_REL, script_pdf)
    script_doc = fitz.open(script_pdf)
    if len(script_doc) != 2:
        raise SystemExit("BLOCKED_SCRIPT_EXPECTED_TWO_PAGES")
    result = {
        "gate": "SAD_VIS05_EDITORIAL_AND_SCRIPT_2026_11_23",
        "status": "PASS_PDF_PRESERVATION_VISUAL_REVIEW_PENDING",
        "code_commit": commit, "source_sha256": SOURCE_SHA, "output_sha256": sha(target),
        "output_path": str(target), "source_path": str(args.source), "pages": 98,
        "modified_pages": [22], "preserved_pages_text_geometry_and_render": "97/97_EQUAL_AT_72_DPI",
        "figure7_pixels_and_geometry": "UNCHANGED", "page22_outside_edit_zones_text": "UNCHANGED",
        "script_pdf": str(script_pdf), "script_pdf_sha256": sha(script_pdf),
        "script_markdown_sha256": sha(root/MD_REL), "script_pages": len(script_doc),
        "scope": ["AUD-01 clarified in page22 text/note; screenshot and QVW labels remain historical",
                  "AUD-10 operational filter restrictions adopted in the presentation script"],
        "limits": ["No QVW/QVD/QVS/model/expression/association changes",
                   "No new physical QlikView session, merge or submission",
                   "Teacher file-source/three-sheet acceptance and online rehearsal remain pending"],
    }
    audit.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps(result, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    main()
