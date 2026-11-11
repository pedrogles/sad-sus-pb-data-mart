#!/usr/bin/env python3
"""Adiciona justificativa conclusiva a duas paginas do DOC-R3, sem modificar R2, QVW ou QVS.

Execucao academica local no PDF de 98 paginas, com SHA do arquivo de entrada pinado.
O script nao atualiza o sumario, porque insere subsecao em paginas preexistentes.
"""
import argparse
import hashlib
import json
import unicodedata
from pathlib import Path
import fitz

EXPECTED_SOURCE_SHA256 = 'DA04BB440DC57DDD9DFB20331AFB548EDC3142143E82A0C92605EC8B7904CB01'
CONTENT = {
    25: '''<h3>3.7 Justificativa dos indicadores não exibidos</h3>
<p>A segunda entrega encerra a implementação acadêmica com três folhas e nove visualizações. A seção 2.9 registra indicadores previstos na modelagem, mas não resultados integralmente demonstrados. O escopo final prioriza análises descritivas cujos recortes e valores de referência possuem evidências delimitadas.</p>
<p><b>Internações por 1.000 habitantes (2.9.1):</b> não exibido porque requer relacionar internações pelo município de residência e ano à população da mesma referência. A associação entre fatos e os filtros aplicáveis não receberam validação física global.</p>
<p><b>Leitos SUS por 1.000 habitantes (2.9.2):</b> não exibido porque depende de média de snapshots mensais no município/ano, população anual compatível e definição histórica defensável da cobertura hospitalar CNES/LT, ainda não verificada integralmente.</p>
<p><b>Relação internações/leitos (2.9.3):</b> não exibida porque compara fluxo administrativo com estoque cadastral. Período, papel municipal, agregação e denominador exigiriam validação adicional. Mesmo que calculada, a razão não mediria taxa de ocupação.</p>''',
    26: '''<h3>4.1 Delimitação final dos resultados apresentados</h3>
<p>O fluxo residência → atendimento previsto na seção 2.9.4 está representado nos objetos M3-01 e M3-02. Medidas disponíveis nas tabelas fato — total de registros AIH, dias de permanência, valor total, indicador de óbito e leitos não SUS — não foram selecionadas como medidas diretas dos nove visuais. Também não foram apresentados rankings específicos de procedimentos/diagnósticos, composição SUS/não SUS e detalhamento de leitos por estabelecimento/tipo. Isso delimita a comunicação dos resultados, sem demonstrar que os campos sejam inúteis ou tenham sido excluídos do Data Mart.</p>
<p>O blueprint técnico de 14 visuais descreve um conjunto de possibilidades mais amplo que a interface acadêmica efetivamente entregue. <b>A segunda entrega encerra o escopo de implementação do grupo:</b> as três folhas e seus nove objetos constituem o produto demonstrado, sem compromisso de desenvolvimento posterior. As validações de associação, cobertura e indicadores cruzados não concluídas permanecem registradas como limites metodológicos; não são apresentadas como resultados homologados nem como um plano de trabalho futuro.</p>''',
}
CSS = '''body { font-family: sans-serif; font-size: 8.55pt; line-height: 1.35; color: #222b30; }
h3 {font-size: 10.6pt; font-weight: bold; color: #0f3440; margin: 0 0 5pt 0; }
p { margin: 0 0 6pt 0; }
b {font-weight: bold;}'''
BOXES = {25: (49, 565, 546, 776), 26: (49, 485, 546, 773)}

def sha256(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest().upper()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    if not args.source.is_file(): raise SystemExit('SOURCE_MISSING')
    if args.source.resolve() == args.output.resolve(): raise SystemExit('REFUSE_OVERWRITE_SOURCE')
    if args.output.exists(): raise SystemExit('REFUSE_OVERWRITE_TARGET')
    source_sha = sha256(args.source)
    if source_sha != EXPECTED_SOURCE_SHA256: raise SystemExit('SOURCE_SHA256_MISMATCH: ' + source_sha)
    doc=fitz.open(args.source)
    if len(doc)!=98: raise SystemExit('EXPECTED_98_PAGES')
    for pageidx,html in CONTENT.items():
        page=doc[pageidx]
        if not ('3.6 Síntese' in page.get_text() if pageidx==25 else '4 CONSIDERAÇÕES FINAIS' in page.get_text()):
            raise SystemExit(f'PAGE_ANCHOR_MISMATCH_{pageidx+1}')
        box=fitz.Rect(BOXES[pageidx])
        free,scale=page.insert_htmlbox(box,html,css=CSS,scale_low=1)
        if free < 7 or abs(scale-1)>0.0001: raise SystemExit(f'TEXT_OVERFLOW_P{pageidx+1}: {free},{scale}')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    doc.save(args.output,garbage=3,deflate=True)
    doc.close()
    revised=fitz.open(args.output)
    original=fitz.open(args.source)
    if len(revised)!=98: raise SystemExit('OUTPUT_PAGE_COUNT_MISMATCH')
    qa=[]
    for idx in range(98):
        if idx in CONTENT: continue
        a,b=original[idx],revised[idx]
        if a.get_text()!=b.get_text() or a.rect!=b.rect or a.rotation!=b.rotation:
            raise SystemExit(f'UNCHANGED_PAGE_TEXT_OR_GEOMETRY_DRIFT_{idx+1}')
        pixa=a.get_pixmap(matrix=fitz.Matrix(0.85,0.85),alpha=False)
        pixb=b.get_pixmap(matrix=fitz.Matrix(0.85,0.85),alpha=False)
        if pixa.samples!=pixb.samples: raise SystemExit(f'UNCHANGED_PAGE_RENDER_DRIFT_{idx+1}')
        qa.append(idx+1)
    p26=unicodedata.normalize("NFKC",revised[25].get_text()); p27=unicodedata.normalize("NFKC",revised[26].get_text())
    for x in ['3.7 Justificativa','Internações por 1.000','Leitos SUS por 1.000','Relação internações/leitos']:
        if x not in p26: raise SystemExit('MISSING_P26: '+x)
    for x in ['4.1 Delimitação','M3-01 e M3-02','14 visuais','sem compromisso']:
        if x not in p27: raise SystemExit('MISSING_P27: '+x)
    outputhash=sha256(args.output)
    manifest={
       'gate':'DOC_R3_ACADEMIC_FINAL_SCOPE_RATIONALE',
       'source_file':str(args.source),'source_sha256':source_sha,
       'output_file':str(args.output),'output_sha256':outputhash,
       'pages':98,'modified_pdf_pages':[26,27],
       'unmodified_pdf_pages_rendered_equal':len(qa),
       'modifications':'Added subsection 3.7 (three excluded derived indicators) and 4.1 (unused measures, 14-vs-9 scope, no future implementations)',
       'no_model_code_or_data_changes':True,
       'academic_review_required':True,
    }
    mp=args.output.with_suffix('.audit.json')
    if mp.exists(): raise SystemExit('REFUSE_OVERWRITE_MANIFEST')
    mp.write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf8')
    print(json.dumps(manifest,indent=2,ensure_ascii=False))

if __name__=='__main__':main()
