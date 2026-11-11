#!/usr/bin/env python3
"""Refresh only Figures 7-9 of the 98-page academic DOC-R3 using VIS-04 GUI screenshots.

Protected by strict input hash and screenshot hashes. Creates a new PDF (never replaces input),
updates only physical pages 22-24, and compares 95 untouched pages by text and rendering.
No PDF content source, QVW, QVS, QVD, or Git state is modified.
"""
import hashlib, io, json
from pathlib import Path
import fitz
from PIL import Image

BASE = Path('/mnt/data')
SOURCE = BASE / 'SAD_Data_Mart_SUS_PB_DOC_R3_Entrega_Final_2026.pdf'
TARGET = BASE / 'SAD_Data_Mart_SUS_PB_DOC_R3_Entrega_Final_VIS04_2026.pdf'
EXPECTED_SOURCE_SHA = 'D5FC55797DA939C2E2815B66309A05953B4E5D9C1927DC1E7D74A9879658D44D'
FIGURES = {
  21: ('image(20261111-005536).png', '7F79DEB490CF9962B0B9FC7CBC6B3AE7940003998F7D5936CDE7DED6B82254BD',
       'Figura 7 — Produção Hospitalar: internações por ano, ranking SERV e série mensal. Fonte: QlikView VIS-04 após reabertura, 10/11/2026.',
       fitz.Rect(49, 341, 546, 369)),
  22: ('image(20261111-005526).png', '6ECC8AC2CEC3C683BA75FB0425BE9F8BEC941C5F454DCB363369116D54693616',
       'Figura 8 — Leitos Cadastrais Observados, com legendas M2-03 corrigidas. Fonte: QlikView VIS-04 após reabertura, 10/11/2026.',
       fitz.Rect(49, 287, 546, 314)),
  23: ('image(20261111-005512).png', 'E2EF2B79ED42756F4D591C7A12626283D7D2376445C18ACB05AD136F35562688',
       'Figura 9 — Fluxos RES/SERV, pares dirigidos e população anual. Fonte: QlikView VIS-04 após reabertura, 10/11/2026.',
       fitz.Rect(49, 287, 546, 314)),
}
FONT='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'

def sha(path):
  return hashlib.sha256(Path(path).read_bytes()).hexdigest().upper()

def run():
  assert SOURCE.is_file() and sha(SOURCE)==EXPECTED_SOURCE_SHA, 'SOURCE_HASH_MISMATCH_OR_MISSING'
  assert not TARGET.exists(), 'REFUSE_OVERWRITE_TARGET'
  src=fitz.open(SOURCE)
  assert len(src)==98, 'EXPECTED_98_PAGES'
  image_manifest={}
  for index, (filename, expected_sha, caption, caption_rect) in FIGURES.items():
    img_path=BASE/filename
    assert img_path.is_file() and sha(img_path)==expected_sha, 'SCREENSHOT_HASH_MISMATCH '+filename
    img=Image.open(img_path).convert('RGB')
    # Crop to the QlikView sheet, excluding application chrome and task bar. Keep original aspect.
    cropped=img.crop((0, 92, img.width, 756))
    stream=io.BytesIO();cropped.save(stream,format='PNG')
    page=src[index]
    page_images=page.get_images(full=True)
    assert len(page_images)==1 and len(page.get_image_rects(page_images[0][0]))==1, 'UNEXPECTED_IMAGE_LAYOUT'
    old_rect=page.get_image_rects(page_images[0][0])[0]
    assert 450<old_rect.width<520 and 180<old_rect.height<215, 'UNEXPECTED_FIGURE_RECT'
    page.replace_image(page_images[0][0],stream=stream.getvalue())
    # Target caption rectangle is below the figure; preserve the figure and all other graphics.
    page.add_redact_annot(caption_rect,fill=(1,1,1))
    page.apply_redactions(images=0,graphics=0,text=0)
    # Integrate a 2-line caption in the same zone.
    font='DV_FIG_'+str(index)
    page.insert_font(fontname=font,fontfile=FONT)
    inserted=page.insert_textbox(caption_rect, caption,
      fontname=font,fontsize=7.1,align=fitz.TEXT_ALIGN_CENTER,
      lineheight=1.32,color=(0.23,0.32,0.36),overlay=True)
    assert inserted>=0, f'CAPTION_OVERFLOW_PAGE_{index+1}_{inserted}'
    image_manifest[str(index+1)]={'input':filename,'sha256':expected_sha,'source_figure_xref':page_images[0][0],
        'rect':tuple(old_rect),'caption':caption,'cropped_size':cropped.size}
  src.save(TARGET,garbage=3,deflate=True)
  src.close()
  old,new=fitz.open(SOURCE),fitz.open(TARGET)
  assert len(new)==len(old)==98
  preserved=0
  for i in range(98):
    if i in FIGURES:
      assert len(new[i].get_images(full=True))==1 and 'VIS-04' in new[i].get_text(), 'FIGURE_NOT_REPLACED'
      assert old[i].get_text() != new[i].get_text(), 'CAPTION_NOT_CHANGED'
      continue
    a,b=old[i],new[i]
    assert a.rect==b.rect and a.rotation==b.rotation, 'GEOMETRY_DRIFT_'+str(i+1)
    assert a.get_text()==b.get_text(), 'TEXT_DRIFT_'+str(i+1)
    assert len(a.get_images(full=True))==len(b.get_images(full=True)), 'IMAGES_DRIFT_'+str(i+1)
    if a.get_pixmap(matrix=fitz.Matrix(.7,.7),alpha=False).samples != b.get_pixmap(matrix=fitz.Matrix(.7,.7),alpha=False).samples:
      raise AssertionError('RENDER_DRIFT_'+str(i+1))
    preserved+=1
  assert preserved==95
  record={'output':str(TARGET),'output_sha256':sha(TARGET),'source':str(SOURCE),'source_sha256':sha(SOURCE),
          'pages_total':98,'pages_modified':[22,23,24],
          'pages_preserved_text_and_rendering':preserved,'figures':image_manifest,
          'limitations':['GUI screenshot proof only; not semantic Qlik validation',
                         'M3-01 free text labels not proven dynamic under selections',
                         'No C2/C3/C4 production approval']}
  meta=TARGET.with_suffix('.audit.json');assert not meta.exists()
  meta.write_text(json.dumps(record,ensure_ascii=False,indent=2),encoding='utf-8')
  print(json.dumps({'output':str(TARGET),'sha256':sha(TARGET),'pages':len(new),'preserved':preserved,'manifest':str(meta)},indent=2))
if __name__=='__main__':run()
