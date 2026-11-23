#!/usr/bin/env python3
"""Recompose the authorized academic PDF; never access QVW/QVD or change model.
The source PDF, canonical chapter drafts and all 13 annex blobs are pinned.
Run from a committed checkout with --expected-commit. No QlikView execution.
"""
import argparse, hashlib, html, io, json, re, subprocess, textwrap
from pathlib import Path
import fitz
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer,
    PageBreak, NextPageTemplate, Image, Table, TableStyle, KeepTogether, Preformatted)
from reportlab.platypus.tableofcontents import TableOfContents
SOURCE_SHA='F3F1F5C9F677D6F39C1BA7B24A12E4E1A38C33F1736D381B8173BE32CDF43DB3'
ANNEX=[
('DIM_TEMPO - organização da transformação','transf_main.qvs','32e028287ca8823d3126b0797e055c12569c3cd2'),
('DIM_MUNICIPIO','transf_dim_municipio.qvs','8632442ff7ac07b7c24bab4d168737ff8f9e9cbc'),
('DIM_ESTABELECIMENTO','transf_dim_estabelecimento.qvs','2021e5a54656144e49e2b1b32a6b663193b181aa'),
('DIM_PROCEDIMENTO','transf_dim_procedimento.qvs','42080861dd6c94afd3044887f2ed47289ddd8492'),
('DIM_DIAGNOSTICO','transf_dim_diagnostico.qvs','c3d85de9ddad940bbf3bd50392cbb45a1302d9a5'),
('DIM_CARATER_ATENDIMENTO','transf_dim_carater_atendimento.qvs','ed18d2a1a2b9aec132d8c64c8942664207d20254'),
('DIM_MOTIVO_SAIDA_PERMANENCIA','transf_dim_motivo_saida_permanencia.qvs','b38429fd1a04d911f9ecde59d75522f48e41b6f2'),
('DIM_TIPO_LEITO','transf_dim_tipo_leito.qvs','0a303df6988b7ddc733d320e459c40b6eb3a1d51'),
('FATO_INTERNACAO','transf_fato_internacao.qvs','fb85a96ccb6d36dbf22ee00dff0eb01326fca940'),
('FATO_CAPACIDADE_LEITO','transf_fato_capacidade_leito.qvs','adf0a500a2f29b16a0782a5b48fb9e047a5cd6ab'),
('Gravação da capacidade em QVD','phase_v_capacidade_leito_qvd_create.qvs','8d2cbb7e2e39c6dfcf06ff31da45d312323eeecb'),
('FATO_POPULACAO','transf_fato_populacao_inmemory.qvs','201f337c3b71993349e93623bc007398f58942a9'),
('Gravação da população em QVD','phase_v_populacao_qvd_create.qvs','23d7dcca8e9f2505b3dc2d4dfae82f812d64eca3')]
FIGS={1:(8,0,'Modelo conceitual (DER), com cardinalidades mínima e máxima.'),
2:(10,0,'Modelo lógico relacional normalizado.'),3:(14,0,'Esquema estrela do processo de internação.'),
4:(15,0,'Esquema estrela do processo de capacidade de leitos.'),5:(16,0,'Esquema estrela do processo de população.'),
6:(18,0,'Constelação de esquemas estrela.'),7:(21,0,'Produção Hospitalar: novas internações por ano de competência, série mensal e municípios de atendimento.'),
8:(22,0,'Leitos Cadastrais Observados: séries mensais, referência municipal de dezembro de 2019 e presença de registros.'),
9:(23,0,'Fluxos e Contexto Territorial: residência, atendimento e população municipal.'),
10:(24,0,'Mensagem de indisponibilidade do ranking de dezembro de 2019 sob seleção temporal incompatível.'),
11:(24,1,'Mensagem de incompatibilidade entre a população anual e a seleção de competência mensal.')}

def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest().upper()
def git(root,*args): return subprocess.check_output(['git','-C',str(root),*args],text=True).strip()
def register_fonts():
    base=Path('/usr/share/fonts/truetype/liberation')
    for name,file in [('Body','LiberationSerif-Regular.ttf'),('Bold','LiberationSerif-Bold.ttf'),('Italic','LiberationSerif-Italic.ttf'),('BoldItalic','LiberationSerif-BoldItalic.ttf'),('Mono','LiberationMono-Regular.ttf')]:
        pdfmetrics.registerFont(TTFont(name,str(base/file)))
    pdfmetrics.registerFontFamily('Body',normal='Body',bold='Bold',italic='Italic',boldItalic='BoldItalic')
    pdfmetrics.registerFontFamily('Mono',normal='Mono',bold='Mono',italic='Mono',boldItalic='Mono')

STYLE={}
def styles():
    STYLE.update({
    'body':ParagraphStyle('body',fontName='Body',fontSize=11.5,leading=16,alignment=TA_JUSTIFY,spaceAfter=8,allowWidows=0,allowOrphans=0,splitLongWords=True),
    'h1':ParagraphStyle('h1',fontName='Bold',fontSize=15,leading=19,spaceAfter=18,keepWithNext=True),
    'h2':ParagraphStyle('h2',fontName='Bold',fontSize=12.5,leading=16,spaceBefore=13,spaceAfter=9,keepWithNext=True),
    'h3':ParagraphStyle('h3',fontName='Bold',fontSize=11.5,leading=15,spaceBefore=9,spaceAfter=6,keepWithNext=True),
    'caption':ParagraphStyle('caption',fontName='Body',fontSize=10,leading=13,alignment=TA_CENTER,spaceAfter=8),
    'small':ParagraphStyle('small',fontName='Body',fontSize=9.5,leading=13,spaceAfter=8),
    'cell':ParagraphStyle('cell',fontName='Body',fontSize=9.5,leading=12,splitLongWords=True),
    'code':ParagraphStyle('code',fontName='Mono',fontSize=7.5,leading=10,spaceAfter=0),
    'cover':ParagraphStyle('cover',fontName='Bold',fontSize=12,leading=17,alignment=TA_CENTER,spaceAfter=7),
    'title':ParagraphStyle('title',fontName='Bold',fontSize=18,leading=24,alignment=TA_CENTER,spaceAfter=16),
    'subtitle':ParagraphStyle('subtitle',fontName='Body',fontSize=13,leading=18,alignment=TA_CENTER,spaceAfter=10)})

def inline(s):
    s=html.escape(s)
    s=re.sub(r'`([^`]+)`',lambda m: '<font size="10">'+m[1]+'</font>',s)
    s=re.sub(r'\*\*(.+?)\*\*',r'<b>\1</b>',s)
    s=re.sub(r'~~(.+?)~~',r'<strike>\1</strike>',s)
    return s.replace('✓','Sim')

class Report(BaseDocTemplate):
    def __init__(self,path,**kwargs):
        super().__init__(str(path),pagesize=A4,leftMargin=57,rightMargin=57,topMargin=63,bottomMargin=54,**kwargs)
        self.addPageTemplates([PageTemplate('portrait',frames=[Frame(57,54,A4[0]-114,A4[1]-117,id='p',leftPadding=0,rightPadding=0,topPadding=0,bottomPadding=0)],onPage=self.chrome),
          PageTemplate('wide',pagesize=landscape(A4),frames=[Frame(57,54,A4[1]-114,A4[0]-117,id='w',leftPadding=0,rightPadding=0,topPadding=0,bottomPadding=0)],onPage=self.chrome)])
    def chrome(self,c,doc):
        if doc.page==1:return
        w,h=c._pagesize
        c.saveState(); c.setFont('Body',9); c.setFillColor(colors.HexColor('#444444'))
        c.drawString(57,h-35,'SAD - Data Mart SUS PB')
        c.drawRightString(w-57,h-35,'Sistemas de Informação | 2026.2')
        c.setStrokeColor(colors.HexColor('#999999'));c.setLineWidth(.35);c.line(57,h-43,w-57,h-43)
        c.drawRightString(w-57,30,str(doc.page-2) if doc.page>2 else '')
        c.restoreState()
    def afterFlowable(self,flow):
        if isinstance(flow,Paragraph) and flow.style.name in ('h1','h2'):
            text=flow.getPlainText(); level=0 if flow.style.name=='h1' else 1
            key='section-'+str(self.seq.nextf('heading'))
            self.canv.bookmarkPage(key);self.canv.addOutlineEntry(text,key,level,False)
            self.notify('TOCEntry',(level,text,self.page-2,key))

def prepare_chapters(root):
    a=(root/'docs/academic/chapter-1-draft.md').read_text()
    a='# 1 REGRAS DE NEGÓCIO\n\n'+a[a.index('## 1.1'):]
    a=a.replace('A proposta busca permitir análises como:','A modelagem considerou as análises abaixo. Os itens tachados não foram implementados; as limitações de integração e uso dos dados são descritas na seção 3.7:')
    a=a.replace('- leitos SUS por habitante;','- ~~leitos SUS por habitante~~;').replace('- internações por habitante;','- ~~internações por habitante~~;').replace('- relação descritiva entre demanda hospitalar e capacidade cadastrada;','- ~~relação descritiva entre demanda hospitalar e capacidade cadastrada~~;')
    a=a.replace('Estratégia de validação dos dados.','Análise preliminar das fontes.').replace('checkpoints','amostras de referência').replace('schemas','estruturas dos arquivos').replace('Discovery','análise preliminar')
    a=a.replace('A carga e a validação dos 36 meses completos serão realizadas na etapa de implementação, repetindo os controles definidos nesta análise preliminar.','Os resultados da implementação consideram as 36 competências de 2017 a 2019. A análise inicial das amostras serviu à modelagem, sem substituir as verificações necessárias aos indicadores que cruzam as fontes.')
    a=a.replace('Para os indicadores anuais definidos neste projeto, será utilizada a **média dos doze snapshots mensais disponíveis do ano**, evitando a soma indevida de estoques mensais.','Para os indicadores anuais previstos na modelagem, a regra proposta é utilizar a **média dos doze registros mensais disponíveis do ano**, evitando a soma indevida de estoques. Os indicadores derivados que dependem dessa regra não foram implementados, conforme a seção 3.7.')
    # Preserve the proposed rules, visibly marking the non-implemented indicator scope.
    for n in (14,15,16):
        pat=rf'(### RN{n}[^\n]*)(.*?)(?=\n### RN|\Z)'
        def strike_rule(m):
            head=m[1].replace('### ','### ~~')+'~~'
            blocks=[]
            for p in m[2].strip().split('\n\n'):
                if p.startswith('- '): blocks.extend('~~'+line+'~~' for line in p.splitlines())
                else: blocks.append('~~'+p.replace('\n',' ')+'~~')
            return head+'\n\n'+'\n\n'.join(blocks)+'\n\nIndicador previsto, não implementado. Justificativa na seção 3.7.\n'
        a=re.sub(pat,strike_rule,a,flags=re.S)
    for n in (1,2): a=re.sub(rf'\*\*Figura {n} [^\n]+',f'@FIGURE:{n}',a)
    start=a.index('### 1.7.1');end=a.index('## 1.8')
    a=a[:start]+'''### 1.7.1 Relações principais

| Relação | Chave | Atributos e referências |
|---|---|---|
| UF | PK: cod_uf | sigla_uf; nome_uf |
| MUNICIPIO | PK: cod_ibge_7; UK: cod_datasus_6 | nome_municipio; FK cod_uf |
| ESTABELECIMENTO | PK: cnes | Identidade permanente do cadastro |
| ESTABELECIMENTO_COMPETENCIA | PK: cnes + competencia | FK cod_ibge_7; tp_unid; tp_gestao; nat_jur; vinc_sus; cnpj_mantenedora; cep |
| PROCEDIMENTO | PK: cod_procedimento | Nome e descrição oficial; hierarquias SIGTAP no modelo dimensional |
| DIAGNOSTICO | PK: cod_diagnostico | Descrição oficial CID-10 |
| CARATER_ATENDIMENTO | PK: cod_carater | Descrição oficial |
| MOTIVO_SAIDA_PERMANENCIA | PK: cod_motivo | Descrição oficial |
| TIPO_LEITO | PK: cod_tipo_leito | Descrição oficial |
| LEITO | PK: cod_leito | FK cod_tipo_leito; descrição |
| REGISTRO_AIH | PK técnica: id_registro_aih | FK cnes + competencia; município de residência; procedimento; diagnóstico; caráter; motivo; atributos operacionais |
| CAPACIDADE_LEITO | PK: cnes + competencia + cod_leito | qt_exist; qt_sus |
| POPULACAO_MUNICIPAL | PK: cod_ibge_7 + ano | populacao |

'''+a[end:]
    b=(root/'docs/academic/chapter-2-draft.md').read_text(); b='# 2 MODELAGEM DIMENSIONAL\n\n'+b[b.index('## 2.1'):]
    b=b.replace('checkpoints','amostras de referência').replace('fatos distintas','tabelas fato distintas')
    b=b.replace('Todas decorrem','Todas decorrem').replace('Elas não foram criadas apenas para atingir o mínimo acadêmico de seis dimensões:','As dimensões são:')
    b=b.replace('Essas medidas são semi-aditivas no tempo. Para os indicadores anuais deste projeto, será utilizada a **média dos doze snapshots mensais disponíveis do ano**, e não a soma direta das competências, porque cada mês representa um estoque de capacidade naquele momento.','Essas medidas são semi-aditivas no tempo. A modelagem prevê a média dos doze registros mensais para indicadores anuais, em lugar da soma das competências. Os indicadores dependentes dessa média não foram implementados; as visualizações apresentam os registros mensais e a referência fixa de dezembro de 2019.')
    b=b.replace('A população também é semi-aditiva no tempo e será utilizada principalmente como denominador de indicadores municipais.','A população também é semi-aditiva no tempo. Seu uso como denominador foi previsto na modelagem; a implementação apresenta as estimativas anuais separadamente, sem os indicadores derivados descritos na seção 2.9.')
    for n in (3,4,5,6):b=re.sub(rf'\*\*Figura {n} [^\n]+',f'@FIGURE:{n}',b)
    start=b.index('## 2.9');end=b.index('## 2.10')
    b=b[:start]+'''## 2.9 Indicadores derivados previstos na modelagem

Os itens tachados foram propostos, mas não foram implementados devido às limitações de compatibilidade e verificação dos dados descritas na seção 3.7. As definições são mantidas para distinguir a proposta inicial dos resultados apresentados.

### 2.9.1 ~~Internações por 1.000 habitantes~~

~~Razão entre internações de residentes no município e ano e a população estimada do mesmo município e ano, multiplicada por 1.000.~~

### 2.9.2 ~~Leitos SUS por 1.000 habitantes~~

~~Razão entre a média mensal de leitos SUS no município e ano e a população estimada correspondente, multiplicada por 1.000.~~

### 2.9.3 ~~Relação entre internações e leitos~~

~~Razão entre internações realizadas no município e período e a capacidade média de leitos no mesmo município e período.~~

Essa relação seria descritiva e não corresponderia à taxa de ocupação hospitalar.

### 2.9.4 Fluxo entre residência e atendimento

A comparação dos dois papéis de DIM_MUNICIPIO permite analisar deslocamentos registrados entre residência e atendimento. Essa análise foi implementada nos objetos M3-01 e M3-02.

'''+b[end:]
    return a+'\n\n'+b+'\n\n'+(root/'docs/academic/vis05-unified-report-content-2026-11-23.md').read_text()

class Composer:
    def __init__(self,source,out): self.source=source;self.out=out;self.flow=[];self.tables=0;self.images=[]
    def para(self,t,style='body'): return Paragraph(inline(t),STYLE[style])
    def figure(self,n):
        page,index,caption=FIGS[n]; info=self.source[page].get_image_info(xrefs=True)[index]
        data=self.source.extract_image(info['xref'])['image']; path=self.out/f'figure_{n:02}.png';path.write_bytes(data)
        self.images.append({'figure':n,'source_page':page+1,'sha256':hashlib.sha256(data).hexdigest().upper()})
        wide=n in (1,2,7,8,9)
        if wide:self.flow.extend([NextPageTemplate('wide'),PageBreak()])
        elif n==6:self.flow.append(PageBreak())
        img=Image(io.BytesIO(data)); maxw=landscape(A4)[0]-114 if wide else A4[0]-114
        maxh=landscape(A4)[1]-180 if wide else (640 if n==6 else 400)
        ratio=min(maxw/img.imageWidth,maxh/img.imageHeight);img.drawWidth=img.imageWidth*ratio;img.drawHeight=img.imageHeight*ratio
        source='elaboração própria (2026).' if n<=6 else 'interface do projeto no QlikView 12 (2026).'
        block=[self.para(f'Figura {n} - {caption}','caption'),img,Spacer(1,7),self.para('Fonte: '+source,'caption')]
        self.flow.append(KeepTogether(block))
        if wide:self.flow.extend([NextPageTemplate('portrait'),PageBreak()])
    def table(self,lines):
        rows=[[c.strip() for c in x.strip().strip('|').split('|')] for x in lines]
        rows=[row for row in rows if not all(re.fullmatch(r'[: -]+',c) for c in row)]
        count=len(rows[0]); width=A4[0]-114
        widths=([width*.42,width*.58] if count==2 else ([width*.31,width*.27,width*.42] if count==3 else [width*.46]+[width*.18]*3))
        data=[[Paragraph(('<b>'+inline(c)+'</b>') if i==0 else inline(c),STYLE['cell']) for c in row] for i,row in enumerate(rows)]
        t=Table(data,colWidths=widths,repeatRows=1,hAlign='LEFT')
        t.setStyle(TableStyle([('VALIGN',(0,0),(-1,-1),'TOP'),('BACKGROUND',(0,0),(-1,0),colors.HexColor('#ededed')),('LINEBELOW',(0,0),(-1,0),.6,colors.black),('LINEBELOW',(0,1),(-1,-1),.25,colors.HexColor('#bbbbbb')),('LEFTPADDING',(0,0),(-1,-1),6),('RIGHTPADDING',(0,0),(-1,-1),6),('TOPPADDING',(0,0),(-1,-1),6),('BOTTOMPADDING',(0,0),(-1,-1),6)]))
        t.keepWithNext=True
        self.tables+=1;self.flow.extend([t,self.para('Fonte: elaboração própria (2026).','caption'),Spacer(1,5)])
    def markdown(self,text):
        lines=text.splitlines();i=0
        while i<len(lines):
            line=lines[i].strip();i+=1
            if not line or line=='---':continue
            if line.startswith('@FIGURE:'):self.figure(int(line.split(':')[1]));continue
            if line.startswith('|'):
                block=[line]
                while i<len(lines) and lines[i].strip().startswith('|'):block.append(lines[i].strip());i+=1
                self.table(block);continue
            if line.startswith('#'):
                level=len(line)-len(line.lstrip('#'));value=line[level:].strip()
                if level==1:
                    if self.flow and not isinstance(self.flow[-1],PageBreak):self.flow.append(PageBreak())
                    self.flow.append(self.para(value,'h1'))
                else:self.flow.append(self.para(value,'h2' if level==2 else 'h3'))
                continue
            if line.startswith('- '):self.flow.append(self.para('• '+line[2:]));continue
            block=[line]
            while i<len(lines) and lines[i].strip() and not lines[i].startswith(('#','|','@FIGURE:','- ','---')):block.append(lines[i].strip());i+=1
            self.flow.append(self.para(' '.join(block)))
    def annexes(self,root):
        records=[]
        for idx,(title,name,blob) in enumerate(ANNEX):
            p=root/'TRANSFORMACAO'/name
            if git(root,'hash-object',str(p))!=blob:raise RuntimeError('ANNEX_BLOB_MISMATCH '+name)
            content=p.read_text(encoding='utf-8-sig');records.append({'file':name,'git_blob':blob,'sha256':sha(p),'lines':len(content.splitlines())})
            self.flow.append(PageBreak())
            if idx in (0,8):
                self.flow.append(self.para('ANEXO I - SCRIPTS DAS DIMENSÕES' if idx==0 else 'ANEXO II - SCRIPTS DAS TABELAS FATO','h1'))
                self.flow.append(self.para('As listagens abaixo reproduzem os arquivos de transformação associados ao projeto. Os comentários e identificadores técnicos foram mantidos para preservar o código documentado. A reprodução de um script não significa que todas as suas etapas tenham sido executadas na interface acadêmica.','small'))
            self.flow.append(self.para(title,'h3'));self.flow.append(self.para('Arquivo: TRANSFORMACAO/'+name,'small'))
            for number,line in enumerate(content.splitlines(),1):
                # Wrap for presentation only. Continuations are indented and line numbers retained.
                line=line.expandtabs(4)
                maxchars=93
                parts=textwrap.wrap(line,width=maxchars,replace_whitespace=False,drop_whitespace=False,break_long_words=True,break_on_hyphens=False) or ['']
                for j,part in enumerate(parts):
                    rendered=(f'{number:4d}  ' if j==0 else '      ')+part
                    self.flow.append(Preformatted(rendered,STYLE['code'],dedent=0))
        return records

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--source',required=True,type=Path);ap.add_argument('--output',required=True,type=Path);ap.add_argument('--expected-commit',required=True);args=ap.parse_args()
    root=Path(__file__).resolve().parents[1];commit=git(root,'rev-parse','HEAD')
    if commit!=args.expected_commit:raise RuntimeError('COMMIT_MISMATCH')
    if git(root,'status','--porcelain','--untracked-files=no'):raise RuntimeError('TRACKED_FILES_MODIFIED')
    if sha(args.source)!=SOURCE_SHA:raise RuntimeError('SOURCE_HASH_MISMATCH')
    print('SOURCE_COMMIT='+commit,flush=True)
    args.output.mkdir(parents=True,exist_ok=True);register_fonts();styles()
    original=fitz.open(args.source);c=Composer(original,args.output);manuscript=prepare_chapters(root)
    (args.output/'relatorio-editorial.md').write_text(manuscript,encoding='utf-8')
    c.flow.extend([Spacer(1,45),c.para('UNIESP','cover'),c.para('CURSO DE SISTEMAS DE INFORMAÇÃO','cover'),c.para('SISTEMAS DE APOIO À DECISÃO - 2026.2','cover'),c.para('Professor Fábio Nicácio de Medeiros','subtitle'),Spacer(1,90),c.para('PROPOSTA DE UM DATA MART NA ÁREA DE SAÚDE PÚBLICA','title'),c.para('Análise da demanda hospitalar, capacidade de leitos e população do SUS na Paraíba','subtitle'),Spacer(1,65),c.para('Pedro Gabriel Lima e Silva','subtitle'),Spacer(1,100),c.para('João Pessoa - PB','subtitle'),c.para('2026','subtitle'),PageBreak(),c.para('SUMÁRIO','h3')])
    toc=TableOfContents();toc.levelStyles=[ParagraphStyle('toc0',fontName='Bold',fontSize=10.5,leading=14,spaceBefore=7),ParagraphStyle('toc1',fontName='Body',fontSize=10,leading=13,leftIndent=13,spaceBefore=3)]
    c.flow.extend([toc,PageBreak()]);c.markdown(manuscript);annex=c.annexes(root)
    target=args.output/'SAD_Data_Mart_SUS_PB_Relatorio_Uniformizado_2026-11-23.pdf'
    temp=args.output/'layout-temporario.pdf';Report(temp,title='Data Mart SUS PB - Relatório acadêmico',author='Pedro Gabriel Lima e Silva').multiBuild(c.flow)
    pdf=fitz.open(temp);md=pdf.metadata;md.update({'producer':'','creator':'','subject':'Data Mart SUS PB, 2017 a 2019','keywords':'SUS; Paraíba; Data Mart; QlikView'});pdf.set_metadata(md);pdf.save(target,garbage=4,deflate=True);pdf.close();temp.unlink()
    final=fitz.open(target);text='\n'.join(p.get_text() for p in final)
    forbidden=['PASS_RESTRICTED','PASS restrito','PASS visual','oráculos','ChatGPT','OpenAI','Codex','GLOBAL_APPROVAL','sem aprovação global de C2']
    for token in forbidden:
        if token.casefold() in text.casefold():raise RuntimeError('FORBIDDEN_PROSE '+token)
    for val in ['555.089','294.635','260.454','7.140','4.018.127','4.467','3.464','97','IDENT=5']:
        if val not in text:raise RuntimeError('MISSING_VALUE '+val)
    if len(c.images)!=11:raise RuntimeError('FIGURES_MISSING')
    if sha(args.source)!=SOURCE_SHA:raise RuntimeError('SOURCE_CHANGED')
    audit={'source_sha256':SOURCE_SHA,'output_sha256':sha(target),'commit':commit,'pages':len(final),'figures':c.images,'annexes':annex,'tables':c.tables,'qvw_opened':False,'qvd_changed':False,'source_preserved':True,'visual_review':'PENDING','scope':'Layout and academic prose; no analytical or QlikView changes'}
    (args.output/'editorial-build.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2))
    for i,p in enumerate(final):
        if i<40 or len(p.get_text())<100:p.get_pixmap(matrix=fitz.Matrix(.9,.9)).save(args.output/f'review-{i+1:03}.png')
    print(json.dumps({'output':str(target),'pages':len(final),'sha256':sha(target),'visual_review':'PENDING'}))
if __name__=='__main__':main()
