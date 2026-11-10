#!/usr/bin/env python3
# DOC-R3: standalone replacement of R2 physical PDF pages 21–28 only.
# IMPORTANT: does NOT load/modify R2 itself; never represents a complete 98-page report.
# Prerequisite: images received from operator, available only outside git.
import argparse, hashlib, io, json, os
from pathlib import Path
from xml.sax.saxutils import escape
from PIL import Image
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4
from reportlab.lib.utils import ImageReader
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib import colors

FILENAMES = {
    "fig7": "image(20261110-150448).png",
    "fig8": "image(20261110-200952).png",
    "fig9": "image(20261110-150502).png",
    "fig10": "image(20261110-151027).png",
    "fig11": "image(20261110-175604).png",
}
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"
BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
W, H = A4
LEFT, RIGHT = 49, 48
TEXT_WIDTH = W - LEFT - RIGHT
BOTTOM = 54

def digest(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        while True:
            b = f.read(1024 * 1024)
            if not b: break
            h.update(b)
    return h.hexdigest().upper()

class Pages:
    def __init__(self, out, source):
        pdfmetrics.registerFont(TTFont("DejaVu", FONT))
        pdfmetrics.registerFont(TTFont("DejaVuBold", BOLD))
        pdfmetrics.registerFontFamily("DejaVu", normal="DejaVu", bold="DejaVuBold", italic="DejaVu", boldItalic="DejaVuBold")
        self.c = canvas.Canvas(str(out), pagesize=A4, pageCompression=1)
        self.c.setTitle("SAD — DOC-R3 | Capítulos 3–5 (páginas substitutivas)")
        self.c.setAuthor("Projeto acadêmico SAD — SUS PB")
        self.root = source
        self.page_num = 0
        self.y = H
        self.body = ParagraphStyle("body", fontName="DejaVu", fontSize=8.45, leading=13, spaceAfter=0, textColor=colors.HexColor("#222b30"))
        self.small = ParagraphStyle("small", parent=self.body, fontSize=7.3, leading=10.5)
        self.caption = ParagraphStyle("caption", parent=self.body, fontSize=7.3, leading=10.5, alignment=1, textColor=colors.HexColor("#3e555f"))
        self.head = ParagraphStyle("head", parent=self.body, fontName="DejaVuBold", fontSize=10.6, leading=15, textColor=colors.HexColor("#0f3440"))
        self.note = ParagraphStyle("note", parent=self.body, fontSize=8.1, leading=12, textColor=colors.HexColor("#224e5a"))

    def new(self, title):
        if self.page_num:
            self.c.showPage()
        self.page_num += 1
        self.y = H - 81
        self.c.setFillColor(colors.HexColor("#385560"))
        self.c.setFont("DejaVuBold", 7.3)
        self.c.drawRightString(W - RIGHT, H - 32, "SAD 2026.2  |  DATA MART SUS — PARAÍBA")
        self.c.setStrokeColor(colors.HexColor("#c2d0d3"))
        self.c.line(LEFT, H - 42, W - RIGHT, H - 42)
        self.c.setFillColor(colors.HexColor("#0f3440"))
        self.c.setFont("DejaVuBold", 12.3)
        self.c.drawString(LEFT, H - 69, title)
        self.c.setStrokeColor(colors.HexColor("#b0bcc0"))
        self.c.line(LEFT, 45, W - RIGHT, 45)
        self.c.setFillColor(colors.HexColor("#5f717a"))
        self.c.setFont("DejaVu", 6.8)
        self.c.drawString(LEFT, 32, "DOC-R3 — caderno substitutivo, não integrado ao R2")
        self.c.drawRightString(W - RIGHT, 32, "Página " + str(18 + self.page_num))

    def p(self, text, style=None, before=0, after=11):
        self.y -= before
        para = Paragraph(text, style or self.body)
        aw, ah = para.wrap(TEXT_WIDTH, 2000)
        if self.y - ah < BOTTOM:
            raise RuntimeError("OVERFLOW on replacement page " + str(self.page_num) + ", paragraph: " + text[:80])
        para.drawOn(self.c, LEFT, self.y - ah)
        self.y -= ah + after
        return ah

    def h(self, text):
        self.p(escape(text), self.head, before=5, after=7)

    def figure(self, key, label, region=None, height=278, after=10):
        path = self.root / FILENAMES[key]
        im = Image.open(path).convert("RGB")
        # Remove Windows title bar, Qlik toolbars and taskbar in full-sheet images.
        if region is None:
            region = (0, 104, im.width, min(im.height - 115, 861))
        crop = im.crop(region)
        targetw = TEXT_WIDTH
        targeth = targetw * crop.height / crop.width
        if targeth > height:
            targeth = height
            targetw = height * crop.width / crop.height
        cap = Paragraph(label, self.caption)
        _, hc = cap.wrap(TEXT_WIDTH, 1000)
        if self.y - targeth - hc - 14 < BOTTOM:
            raise RuntimeError("FIGURE_OVERFLOW " + key + " on page " + str(self.page_num))
        x = (W - targetw) / 2
        buf = io.BytesIO()
        crop.save(buf, "PNG", optimize=True)
        buf.seek(0)
        self.c.drawImage(ImageReader(buf), x, self.y - targeth, width=targetw, height=targeth, mask="auto")
        self.y -= targeth + 8
        cap.drawOn(self.c, LEFT, self.y - hc)
        self.y -= hc + after

    def table(self, columns, rows, widths, rowheight=29):
        x=LEFT
        h = rowheight * (len(rows)+1)
        if self.y - h < BOTTOM:
            raise RuntimeError("TABLE_OVERFLOW page " + str(self.page_num))
        self.c.setFillColor(colors.HexColor("#eaf0f1"))
        self.c.rect(LEFT,self.y-rowheight,TEXT_WIDTH,rowheight,stroke=0,fill=1)
        data=[columns]+rows
        for j,row in enumerate(data):
            yy=self.y-j*rowheight
            x=LEFT
            for k,t in enumerate(row):
                val=str(t)
                s=self.small
                if j==0:
                    s=ParagraphStyle("thead",parent=self.small,fontName="DejaVuBold")
                p=Paragraph(escape(val),s)
                _,ph=p.wrap(widths[k]-8,rowheight+60)
                p.drawOn(self.c,x+4, yy-3-ph)
                x+=widths[k]
            self.c.setStrokeColor(colors.HexColor("#d9e1e3"))
            self.c.line(LEFT,yy-rowheight,W-RIGHT,yy-rowheight)
        self.y-=h+12

    def done(self):
        if self.page_num != 8:
            raise RuntimeError("Replacement must have exactly 8 pages")
        self.c.save()

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--images",type=Path,required=True)
    ap.add_argument("--output",type=Path,required=True)
    a=ap.parse_args()
    for k, fn in FILENAMES.items():
        if not (a.images/fn).is_file():
            raise SystemExit("MISSING_INPUT "+str(a.images/fn))
    a.output.parent.mkdir(parents=True,exist_ok=True)
    d=Pages(a.output,a.images)

    d.new("3 IMPLEMENTAÇÃO")
    d.p("Data Mart para análise da demanda hospitalar, capacidade de leitos e população do SUS na Paraíba (2017–2019)",d.note,after=11)
    d.p("<b>NOTA METODOLÓGICA — DOC-R3 (10/11/2026).</b> As figuras correspondem a diferentes cópias experimentais do QlikView 12, identificadas nas legendas. A revisão atualiza o acabamento visual demonstrado no gate VIS-03, sem apresentar a QVW TEMP como painel de produção homologado.",d.note,after=13)
    d.h("3.1 Solução de BI e organização dos dados")
    d.p("A implementação utiliza o QlikView 12, com análise associativa e consumo de arquivos QVD. O fluxo adotado mantém BASE → EXTRACAO → QVD → TRANSFORMACAO → QVD → PAINEL. As três fontes são SIH/SUS (eventos administrativos de internação), CNES/LT (quantidades cadastrais de leitos) e IBGE/SIDRA (estimativas anuais da população).")
    d.p("A estrutura dimensional preserva FATO_INTERNACAO, FATO_CAPACIDADE_LEITO e FATO_POPULACAO, além de oito dimensões aprovadas. Os grãos dos três processos permanecem distintos. Município de residência (RES) e município de atendimento (SERV) representam papéis diferentes, sem equivalência territorial automática.")
    d.p("Conforme logs e verificações locais reportados no repositório, o protótipo de consumo possui três folhas com nove objetos. A interface foi refinada em QVWs de trabalho, protegendo as fontes; foi demonstrada persistência visual restrita após salvar e reabrir uma nova cópia com o gráfico de observabilidade corrigido. Não houve aprovação física global dos contratos C2/C3/C4.")
    d.table(["Folha", "Objetos", "Fonte predominante"],[
        ["Produção Hospitalar","M1-01 a M1-03","SIH/RD"],
        ["Leitos Cadastrais Observados","M2-01 a M2-03","CNES/LT e observabilidade"],
        ["Fluxos e Contexto Territorial","M3-01 a M3-03","SIH/RD e IBGE/SIDRA"],
    ],[212,120,TEXT_WIDTH-332],rowheight=28)
    d.p("Quadro 1 — Organização das nove visualizações na QVW TEMP do MVP acadêmico. Fonte: implementação experimental documentada no repositório.",d.caption)

    d.new("3.2 Folha 1 — Produção Hospitalar")
    d.p("Esta folha analisa os registros de <b>novas internações administrativas</b> no período de 2017–2019. A medida QTD_INTERNACAO não conta como novas internações as AIHs de continuidade com IDENT=5. Os resultados não equivalem a pacientes únicos, prevalência de doença ou demanda reprimida.")
    d.figure("fig7","Figura 7 — Produção Hospitalar: novas internações por ano, ranking do município de atendimento (SERV) e 36 competências. Fonte: screenshot da cópia VIS-02 fornecida em 10/11/2026.",height=300)
    d.p("<b>M1-01 — Internações por ano.</b> O oráculo reportado para o protótipo é 183.532 (2017), 183.311 (2018) e 188.246 (2019): 555.089 registros de novas internações no triênio. Os valores não foram recalculados nesta revisão editorial.")
    d.p("<b>M1-02 — Evolução mensal.</b> A série mostra 36 competências administrativas entre janeiro de 2017 e dezembro de 2019. Oscilações na série não demonstram relação causal ou sazonalidade clínica por si sós.")
    d.p("<b>M1-03 — Município de atendimento.</b> O ranking horizontal organiza os registros pelo papel SERV, e não RES. A rolagem de itens fora do primeiro quadro foi verificada visualmente na VIS-03, sem auditoria independente de todos os municípios.")

    d.new("3.3 Folha 2 — Leitos Cadastrais Observados")
    d.figure("fig8","Figura 8 — Leitos Cadastrais Observados com legendas de M2-03 corrigidas e persistentes após salvar/reabrir a QVW TEMP controlada. Fonte: captura do QlikView fornecida em 10/11/2026.",height=298)
    d.p("<b>M2-01 — Leitos por competência.</b> As duas séries distinguem leitos SUS de leitos existentes nos retratos mensais do cadastro CNES/LT. Leitos são uma medida semi-aditiva no tempo: somar 36 snapshots não representa capacidade anual.")
    d.p("<b>M2-02 — Leitos SUS por município (201912).</b> O ranking é fixado em dezembro de 2019; seleção de outra competência pode ser incompatível. Ausência de registro não significa leito zero nem garante cobertura hospitalar.")
    d.p("<b>M2-03 — Observabilidade município × competência.</b> A ilha analítica independente apresenta 8.028 células: 4.467 sem linha LT (não significa zero), 3.464 com SUS positivo observado e 97 com zero SUS observado. São <b>células município × mês, não municípios distintos</b>. As categorias foram traduzidas em legendas curtas sem alterar o campo, a medida ou as contagens reportadas no protótipo.")
    d.p("A tabela auxiliar <b>P23_A1_ISLAND</b> foi criada intencionalmente sem chaves compartilhadas com o modelo associativo principal, como <b>%LINK_KEY</b>. Por isso, M2-03 apresenta o panorama fixo da PB em 2017–2019 e <b>não acompanha filtros globais</b>. A ilha não constitui uma quarta tabela fato da constelação acadêmica. Mesmo quando existe linha LT observada, seu campo não comprova o recorte estritamente hospitalar histórico. As legendas passaram por validação visual local restrita, não por certificação científica de CNES.")

    d.new("3.4 Folha 3 — Fluxos e Contexto Territorial")
    d.figure("fig9","Figura 9 — Fluxos e Contexto Territorial: categorias RES/SERV, pares dirigidos e população municipal anual. Fonte: screenshot da QVW refinada em estado sem seleções visíveis, 10/11/2026.",height=292)
    d.p("<b>M3-01 — Residência versus atendimento.</b> Os resultados reportados são 294.635 novas internações com RES=SERV e 260.454 com RES diferente de SERV, totalizando 555.089. São eventos administrativos, e não avaliação direta de acesso ou qualidade.")
    d.p("<b>M3-02 — Pares residência → atendimento.</b> A tabela mantém a direção da origem residencial ao município de atendimento. Municípios de residência fora da Paraíba não recebem artificialmente estimativa populacional municipal PB.")
    d.p("<b>M3-03 — População municipal por ano.</b> A tabela exibe a estimativa IBGE por município e ano, sem total acumulado de três anos. A população é semi-aditiva no tempo; não se pode somar 2017, 2018 e 2019 como se fossem habitantes distintos.")
    d.p("A apresentação diferencia consultas sobre municípios de serviço e estimativas territoriais de residência. O estado incompatível de filtro mensal usa mensagem própria, conforme registro restrito de interface.")

    d.new("3.5 Tratamento de seleções incompatíveis")
    d.p("O mecanismo associativo não garante compatibilidade semântica entre toda seleção e todo indicador. Nas cópias TEMP, algumas situações são deliberadamente sinalizadas como indisponíveis para impedir que valores de períodos diferentes sejam interpretados como equivalentes.")
    d.figure("fig10","Figura 10 — Aviso de M2-02: competência 201801 não representa o indicador de leitos fixado em 201912. Recorte do gráfico correspondente, anterior ao acabamento de legendas de M2-03.",region=(12,507,830,862),height=155,after=12)
    d.p("Para o cenário mensal reportado, o gráfico M2-02 mostra mensagem de indisponibilidade quando a competência nativa diverge de 201912. A ilha de observabilidade mantém o panorama global, independentemente do filtro. A figura recorta apenas o aviso de M2-02 e não deve ser usada como evidência da versão final de CH06.")
    d.figure("fig11","Figura 11 — Aviso M3-03: consulta de população anual indisponível em filtro de competência mensal. Fonte: screenshot após correção de overflow informada pelo operador.",region=(13,188,480,746),height=247,after=10)
    d.p("O aviso no objeto M3-03 torna explícita a incompatibilidade temporal. Os cenários fotografados sustentam validação <b>restrita</b>, não homologação da matriz completa de seleções nativas nem do contrato global C2/P5.",d.small,after=4)

    d.new("3.6 Síntese e limites da implementação")
    d.p("As três folhas demonstram, em caráter experimental, a utilização conjunta de registros SIH/RD, retratos cadastrais CNES/LT e população anual IBGE em uma interface QlikView 12. A organização oferece análises descritivas de volume, tempo e território, sem inferir causalidade ou indicadores interfontes não homologados.")
    d.p("Na VIS-03, foram inspecionados os nove objetos em três folhas, a navegação de rankings M1-03 e M2-02 e avisos contextuais sob seleção de competência mensal. O único bloqueio crítico identificado — valores técnicos sobrepostos de observabilidade M2-03 — foi corrigido em cópia separada. Captura pós-save/reabertura informou persistência das legendas com correspondência correta entre categoria, cor e texto.")
    d.table(["Verificação", "Estado com escopo declarado"], [
        ["Três folhas / nove objetos","PASS de renderização GUI restrita"],
        ["Rolagem de rankings / avisos 201801","PASS de cenários GUI restritos"],
        ["M2-03: mapeamento e persistência","PASS visual restrito em QVW de trabalho"],
        ["Originais C4 e VIS-02","Hashes estáveis reportados pelo operador"],
        ["Apresentação online / compressão","INCONCLUSIVO: transmissão não ensaiada"],
        ["C2/C3/C4, Fase IX, produção","NÃO APROVADOS"],
    ],[245,TEXT_WIDTH-245],rowheight=34)
    d.p("A validade dos valores permanece condicionada ao universo e aos filtros descritos. O contrato da Link Table e das associações globais (C3), medidas/denominadores/filtros (C4/P5) e gate físico C2 ainda requerem os procedimentos específicos da arquitetura formal, na ordem estabelecida pelo projeto. A construção do MVP não autoriza a implementação definitiva do blueprint de 14 visuais.")
    d.p("As QVWs originais e os QVDs não foram alterados para esta atualização editorial. As figuras representam cópias temporárias demonstradas pelo operador, não certificação independente de propriedades internas ou aprovação de uso operacional no SUS.")

    d.new("4 CONSIDERAÇÕES FINAIS")
    d.p("A proposta de Data Mart para análise da demanda hospitalar, da capacidade cadastral de leitos e da população da Paraíba integrou três tipos de dados heterogêneos em um modelo dimensional com três fatos e oito dimensões, preservando a granularidade e os papéis municipais de cada processo. O período descritivo adotado foi 2017–2019.")
    d.p("A interface experimental QlikView 12 reuniu nove visualizações em três folhas. Foram demonstradas, em cenários delimitados, séries de novas internações, distribuição de leitos SUS e existentes por competência, observabilidade das células município–competência, fluxo entre residência e atendimento e estimativas municipais anuais de população. O refinamento de M2-03 resolveu a sobreposição dos códigos técnicos na apresentação, mantendo a informação de que ausência de registro não equivale a zero.")
    d.p("Os valores empregados nos oráculos e nos exemplos do relatório permanecem aqueles reportados nos ensaios do projeto: 555.089 novas internações administrativas em 2017–2019, 7.140 leitos SUS observados no recorte de dezembro de 2019 e soma das estimativas municipais do IBGE em 2019 de 4.018.127 habitantes. Não houve, no DOC-R3, recálculo ou auditoria independente de cada registro.")
    d.p("O desenvolvimento também explicitou limites interpretativos: AIHs não são pacientes únicos; leitos mensais são retratos cadastrais e semi-aditivos no tempo; população municipal anual não admite acumulação entre anos como habitantes distintos; o papel RES difere de SERV; e sem observação não é sinônimo de zero. Nenhuma visualização apresentada demonstra taxa de ocupação hospitalar ou relação causal entre resultados.")
    d.p("Os avisos de incompatibilidade contextual, especialmente no gráfico fixo de dezembro de 2019 e na população anual sob seleção mensal, tiveram persistência e legibilidade observadas em cenários específicos. A conferência visual local não substitui ensaio de compartilhamento de tela, revisão global de propriedades, aceite científico do recorte histórico de leitos ou os contratos físicos C2/C3/C4.")
    d.p("Assim, a contribuição comprovada é a <b>viabilidade técnica e a capacidade de comunicação de um protótipo acadêmico descritivo</b>. Os painéis formais, os indicadores cruzados e a homologação para uso operacional permanecem fora deste aceite. Essa distinção delimita o alcance das conclusões e preserva a rastreabilidade das evidências.")

    d.new("5 REFERÊNCIAS BIBLIOGRÁFICAS")
    refs = [
      "BRASIL. Ministério da Saúde. Departamento de Informação e Informática do SUS (DATASUS). <b>Informações de Saúde (TABNET)</b>. Disponível em: https://datasus.saude.gov.br/informacoes-de-saude-tabnet/. Acesso em: 9 nov. 2026.",
      "BRASIL. Ministério da Saúde. Departamento de Informação e Informática do SUS. <b>Sistema de Informações Hospitalares do SUS (SIH/SUS): documentação</b>. Disponível em: https://wiki.saude.gov.br/sih/index.php/P%C3%A1gina_principal. Acesso em: 9 nov. 2026.",
      "BRASIL. Ministério da Saúde. <b>Como acessar o Cadastro Nacional de Estabelecimentos de Saúde (CNES)?</b> 2021. Disponível em: https://www.gov.br/saude/pt-br/acesso-a-informacao/faq/estabelecimentos-de-saude/como-acessar-o-cadastro-nacional. Acesso em: 9 nov. 2026.",
      "IBGE. Instituto Brasileiro de Geografia e Estatística. <b>Estimativas da população residente para os municípios e para as unidades da federação</b>. Disponível em: https://www.ibge.gov.br/estatisticas/sociais/populacao/9103. Acesso em: 9 nov. 2026.",
      "IBGE. Instituto Brasileiro de Geografia e Estatística. <b>IBGE divulga as estimativas da população dos municípios para 2019</b>. 28 ago. 2019. Disponível em: https://agenciadenoticias.ibge.gov.br/agencia-sala-de-imprensa/2013-agencia-de-noticias/releases/25278-ibge-divulga-as-estimativas-da-populacao-dos-municipios-para-2019. Acesso em: 9 nov. 2026.",
      "QLIK. <b>Arquivos QVD</b>. Ajuda do QlikView, versão setembro de 2026. Disponível em: https://help.qlik.com/pt-BR/qlikview/September2026/Subsystems/Client/Content/QV_QlikView/QVD_files.htm. Acesso em: 9 nov. 2026.",
      "UNIESP. MEDEIROS, Fábio Nicácio de. <b>Roteiro para o projeto: Sistemas de Apoio à Decisão</b>. Sistemas de Informação, semestre 2026.2. Material didático fornecido aos estudantes.",
    ]
    for ref in refs:
        d.p(ref, d.small, after=15)
    d.p("<b>Nota editorial.</b> Esta seção reproduz o conjunto de referências bibliográficas informado no R2; não registra novas consultas externas. A montagem do PDF integral exige conferência das páginas 1–20 e 29–98 do arquivo R2 original, mantidas sem alteração.", d.note, after=1)
    d.done()
    record={
       "status":"DOC_R3_REPLACEMENT_PAGES_ONLY_NOT_FINAL_REPORT",
       "source":"SAD_A4_Relatorio_Consolidado_R2_Editorial.pdf, 98 pages, extracted-text review",
       "replacement_original_pdf_pages":[21,22,23,24,25,26,27,28],
       "produced_pdf_sha256":digest(a.output),
       "produced_pdf":str(a.output),
       "image_inputs":{key:{"file":name,"sha256":digest(a.images/name)} for key,name in FILENAMES.items()},
       "limitations":["R2 raw PDF inaccessible in this environment; no physical splice","chapters 1–2 and appendices not re-rendered or altered","VIS-03 visual gate restricted; global C2/C3/C4 not approved"]
    }
    meta=a.output.with_suffix(".manifest.json")
    with open(meta,"w",encoding="utf-8") as fd: json.dump(record,fd,ensure_ascii=False,indent=2)
    print("VERDICT=REPLACEMENT_8_PAGES_GENERATED_NOT_FINAL_98_PAGES")
    print("OUTPUT="+str(a.output))
    print("OUTPUT_SHA256="+digest(a.output))
    print("MANIFEST="+str(meta))

if __name__=="__main__":
    main()
