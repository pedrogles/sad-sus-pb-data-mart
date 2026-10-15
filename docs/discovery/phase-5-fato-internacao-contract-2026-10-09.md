# Fase V — Consolidação das evidências SIH/RD da FATO_INTERNACAO

**Checkpoint:** 15/10/2026 — salvamento seletivo do PR [#83](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/83).  
**Origem imutável consultada:** [commit `26369052bd3f96de5f3eccf873c390053c20b561`](https://github.com/pedrogles/sad-sus-pb-data-mart/commit/26369052bd3f96de5f3eccf873c390053c20b561).  
**Alcance:** scripts de pré-validação e resultados locais reportados; **não** implementação factual, autorização de merge de feature ou aprovação do modelo associativo.

## Escopo preservado

A modelagem acadêmica e as decisões anteriores permanecem inalteradas: 3 fatos e 8 dimensões, Star Schema por fato com dimensões conformadas, QlikView 12, fonte SIH/RD de 2017–2019 congelada e regras de `IDENT`. A chave de registro da internação foi aprovada com restrições no PR [#82](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/82), fora do escopo desta extração.

Cinco arquivos de pré-validação são transportados **sem alterações ao conteúdo do commit de origem**:

- `tools/preflight_fato_internacao_medidas.py`: leitura Python/Decimal dos CSVs fonte (depende de `tools/preflight_fase_v_fato_internacao.py`, presente na `main`).
- `TRANSFORMACAO/phase_v_fato_internacao_qlik_measures_preflight.qvs` e `tools/validar_fato_internacao_medidas_qlik.ps1`: reconciliação isolada de medidas SIH/RD; a interpretação monetária usa `Num#` em pré-validação, **não** na transformação oficial.
- `TRANSFORMACAO/phase_v_fato_internacao_qlik_dim_roles_preflight_r3.qvs` e `tools/validar_fato_internacao_dim_roles_r3_qlik.ps1`: cobertura isolada das 11 associações dimensionais por SK no RD, sem criar fatos ou Link Table.

Os detalhes completos de tentativas R1/R2/R3, logs relatados, causas conhecidas e ensaios posteriores continuam no [documento integral original](https://github.com/pedrogles/sad-sus-pb-data-mart/blob/26369052bd3f96de5f3eccf873c390053c20b561/docs/discovery/phase-5-fato-internacao-contract-2026-10-09.md). Scripts diagnósticos anteriores e protótipos Fase VI permanecem na branch original; não são copiados para a `main` por esta entrega.

## Evidências da fonte e staging — PASS local reportado

Período: 36 competências SIH/RD, 2017–2019; **566.672 linhas** de registros administrativos. Totais medidos e reconciliados por ano e agregado na execução local Windows/QlikView 12 de 09/10/2026:

| Ano | Registros administrativos | Internações (`IDENT=1`) | Continuidade (`IDENT=5`) | Óbitos (`MORTE=1`) | Dias | Valor total (R$) |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| 2017 | 187.726 | 183.532 | 4.194 | 8.626 | 1.039.396 | 208.882.120,74 |
| 2018 | 187.293 | 183.311 | 3.982 | 8.649 | 1.038.921 | 218.267.536,76 |
| 2019 | 191.653 | 188.246 | 3.407 | 9.336 | 1.055.261 | 232.234.991,55 |
| **Total** | **566.672** | **555.089** | **11.583** | **26.611** | **3.133.578** | **659.384.649,05** |

**Gate documentado:** `FIVE_MEASURES_CSV=PASS`, `FIVE_MEASURES_QVD=PASS`. O R3 monetário retornou `VALUE_CENTS=65938464905`, `INVALID=0`, `PARSE_BAD=0`, `RAW_BLANK=0`; QVD de staging preservado (SHA-256 local reportado como inalterado). As 5.202 linhas RD com residência externa não recebem automaticamente população PB. `N_AIH` não é chave única.

**Onze papéis dimensionais:** R3 QlikView/COM teve duas recargas consecutivas em 10/10/2026, às 00:21:17 e 00:24:41; a segunda reutilizou o QVW. Em ambas, `ROWS=566672`, `MONTHS=36`, `EXTERNAL=5202`, **11/11 contagens `MISS_*=0`**; oito QVDs de entrada preservados, sem QVD factual. Gate local restrito: `DIMENSION_ROLE_COVERAGE_11_OF_11=PASS_REPRODUCED`. A exceção `MISS_MOT=1` observada no antigo R1 tem **causa raiz desconhecida**; não inferir correção dos dados.

## Limites permanentes

- `SK_REGISTRO_INTERNACAO=APPROVED_WITH_RESTRICTIONS`: assinatura de conteúdo+arquivo para fonte histórica congelada, não identidade persistente sob correções.
- Resultados acima são evidências **locais reportadas e documentadas**; esta extração não reexecutou Python, PowerShell COM ou QlikView 12 e não substitui teste físico independente nem CI.
- **`FATO_INTERNACAO.qvd=NOT_STARTED`**, demais fatos não iniciadas, `LINK_ANALISE.qvd=NOT_STARTED`, `PAINEL=NOT_STARTED`.
- `LINK_KEY_CONTRACT=NOT_APPROVED`; aliases role-playing, seleções cruzadas, modelo associativo físico e indicadores finais requerem gates próprios.
- `T29_HISTORICAL=NOT_APPROVED`; referência CNES de setembro/2019 não demonstra vigência mensal retroativa.
- Não modificar `TRANSFORMACAO/transf_main.qvs`, QVDs, QVWs de produção, material acadêmico entregue ou regras de negócio por causa deste salvamento.

**Veredito de consolidação:** evidência de **Fase V para o snapshot testado** preservada para revisão e possível merge documental/técnico isolado; **não** constitui aprovação da implementação multífato ou encerramento automático do PR #83.
