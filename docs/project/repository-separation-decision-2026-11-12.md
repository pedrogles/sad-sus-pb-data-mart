# SAD — Revisão da estratégia de separação de testes, implementação e artefatos

**Data:** 12/11/2026. **Status:** PROPOSAL / READ-ONLY INVENTORY. **Baseline remota:** `main@e3255b3bfdab9a5335228d71e27a3cdf58bc5fd9`.  
**Inventário de todos os arquivos versionados:** [JSON com 329 arquivos e Git blob SHA](repository-file-classification-inventory-2026-11-12.json).

## 1. Objetivo, escopo e evidência

**Objetivo:** obter separação inteligível entre scripts de implementação acadêmica, pré-verificações/experimentos e arquivos finais, sem regressão no QlikView 12 e sem confundir versão de código com preservação de artefatos.

**Fontes examinadas na main, nesta ordem:** `AGENTS.md`, `docs/project/current-state.md`, `docs/academic/requirements.md`; depois `README.md`, `.gitignore`, `.gitattributes`, `docs/project/artifact-recovery-policy.md`, `docs/academic/final-delivery-record-2026-11-10.md`, `docs/project/qlikview-powershell-automation.md` e alguns scripts QVS/PowerShell. A classificação individual dos demais arquivos baseia-se em **nome/caminho**, NÃO em leitura semântica integral.

**Escopo deste gate:** adicionar SOMENTE este plano e o inventário JSON em branch independente. Não mover/renomear scripts, não alterar entrypoints, `.gitignore`, QVD/QVW, dados, `current-state.md` ou a `main`. Não executar QlikView/COM, criar dados, excluir branches nem mesclar PRs.

**Invariantes:** `BASE → EXTRACAO/EXT.qvw → QVD → TRANSFORMACAO/TRANSF.qvw → QVD → PAINEL/PAINEL.qvw`; três fatos, oito dimensões, Star/constelação e granularidades aprovadas. A primeira entrega e o MVP acadêmico de 3 folhas / 9 objetos não são alterados. Nenhuma aprovação de produção é inferida.

## 2. Revisão crítica da decisão anterior

A decisão anterior de colocar indiscriminadamente todos os testes em `tests/` **não é segura**: os entrypoints QVS contêm includes com resolução relativa à pasta de QVW, e scripts PowerShell/Python usam caminhos fixos. Separar **por função/estado** é desejável, mas requer análise de dependências e migração por lotes pequenos.

### Achados confirmados por inspeção estática

- `EXTRACAO/ext_main.qvs` está versionado e implementa staging, `STORE` de QVD e includes `ext_c4_cnes_leitos.qvs`, `ext_c5_municipal_preflight.qvs`, `ext_c5_2_municipio_pb.qvs` e `ext_phase3_final_gate.qvs`. **Não mover nenhum include sem ajustar/validar a resolução**.
- `TRANSFORMACAO/transf_main.qvs` é entrypoint parcial: contém `DIM_TEMPO`, inclui sete módulos `transf_dim_*.qvs` e mantém `transf_fato_internacao.qvs` opt-in com modo `OFF` por padrão. A presença do arquivo não prova execução ponta a ponta nem aprovação das três fatos.
- `PAINEL/painel_main.qvs` é um entrypoint mínimo inicial, **não** a fonte integral da QVW VIS-04 final.
- `tools/Build-SadMvpThreeSheetsTemp.ps1` depende de caminhos `PAINEL/*.qvs` e QVW experimental. `tools/Invoke-SadVis04FinalPolish.ps1` referencia QVWs TEMP e não demonstra reconstrução completa independente.
- `.gitignore` exclui `*.qvd`, `*.qvw` e dados brutos; `.gitattributes` fixa finais de linha LF para três scripts de teste sensíveis a hash. Uma migração descuidada pode invalidar SHA-256 mesmo sem alteração lógica.
- O registro acadêmico declara QVW VIS-04 final com SHA-256 **reportado localmente** `BE8CB39B59F92F2F173DB309A60EA5FF373CDF87CBFCBC333F5583A21FF539C6` e PDF DOC-R3 com SHA-256 **reportado** `BB7A6A6D7C2ADC3BE80831F4F8E98642D7CE9D07A25B7F03000A9DF2E8071302`. **A disponibilidade e os hashes atuais desses binários não foram revalidados aqui.**

### Composição do inventário da main

| Classificação preliminar | Arquivos | Próximo tratamento |
| --- | ---: | --- |
| Documentação | 167 | Preservar; não tratar históricos como política vigente |
| Ferramentas de validação/diagnóstico candidatas | 67 | Rever individualmente; algumas podem escrever dados |
| Executores e utilitários candidatos | 51 | Manter em `tools/` até mapear dependências |
| Extração: entrypoint + módulos/gates | 5 | **Manter em `EXTRACAO/`** por enquanto |
| Transformação: entrypoint, sete módulos de dimensão, três de fato e 15 scripts de análise/teste | 26 | Diferenciar fonte, gate experimental e contrato real; não classificar por prefixo apenas |
| Painel: entrypoint + protótipos/contratos | 7 | Preservar a QVW binária externamente; não chamar `painel_main.qvs` de final |
| Controles da raiz + placeholders `.gitkeep` | 6 | Manter |
| **Total** | **329** | **Nenhuma movimentação neste gate** |

A contagem acima é de arquivos rastreados no Git, **não** dos DBCs/QVDs/QVWs locais. Categorias terminadas em `REVIEW` indicam **classificação provisória**, não aceite.

## 3. Estrutura-alvo revisada (sem execução)

Preservar `BASE/`, `EXTRACAO/`, `TRANSFORMACAO/`, `PAINEL/`, `tools/` e `docs/`. Propor `tests/` **somente** para testes automatizados e `experiments/` **somente** para protótipos que não sejam dependências diretas do pipeline. O nome `tests/` não torna um script seguro de executar, e `experiments/` não implica descarte. Manter os três entrypoints no lugar.

```text
BASE/                   # fontes locais ignoradas
EXTRACAO/               # EXT.qvw local, ext_main.qvs e includes operacionais
EXTRACAO/QVD/           # artefatos locais ignorados
TRANSFORMACAO/          # TRANSF.qvw local, transf_main.qvs e componentes
TRANSFORMACAO/QVD/      # artefatos locais ignorados
PAINEL/                 # PAINEL.qvw local, painel_main.qvs e contratos QVS
tools/                  # executores e utilitários versionados
tests/                  # apenas alvos cuja execução e caminhos foram auditados
experiments/            # protótipos isolados com proveniência preservada
docs/                   # fontes, decisões e história sem perda de contexto
docs/project/...json    # inventário auditável dos arquivos Git
```

**Não adicionar `artifacts/` à raiz ainda:** primeiro escolher repositório de artefatos, método de backup e esquema de manifesto. O inventário de artefatos externos pode ficar em `docs/project/` com schema simples e hashes, sem transportar binários para o Git.

## 4. Política sugerida para arquivos finais

| Tipo | Decisão recomendada | Bloqueio de publicação |
| --- | --- | --- |
| `.qvs`, `.ps1`, `.py`, contratos e scripts finais | Git em commit imutável, com status/escopo explicitados | Depende de revisão do script e origem de sua execução |
| QVW VIS-04 e PDF DOC-R3 de entrega | **Backup externo independente e versionado**, manifesto Git contendo SHA-256, nome, commit produtor quando conhecido e localização lógica | Existência e integridade atuais não verificadas; backup no mesmo disco não é recuperação independente |
| QVDs, DBCs e derivados grandes | Local/armazenamento externo + contagem, origem e hash; não no histórico Git | Licença, tamanho, divulgação de dados e integridade |
| GitHub Release anexando QVW/PDF | Opção futura **somente se licença, tamanho e visibilidade permitirem**; não substitui backup separado | Repositório público expõe assets; não fazer upload neste gate |

O Git blob SHA no inventário identifica o **conteúdo versionado**. Não equivale ao SHA-256 do arquivo local e não prova que um script foi incorporado a um QVW específico. Em caso de status desconhecido, registrar `UNKNOWN`, nunca `FINAL_APPROVED`.

## 5. Gates subsequentes, aprovação e STOP

1. **GATE 0 — INVENTORY (esta PR):** 329/329 caminhos com Git blob SHA e classificação preliminar; revisão da decisão publicada em branch. **PASS estático** se o inventário corresponder à baseline e o diff contiver apenas dois documentos novos. **STOP** após PR Draft; não mover nada.
2. **GATE 1 — SOURCE MAPPING:** ler conteúdo dos candidatos e mapear `Must_Include`, paths de PowerShell/Python, `STORE`, QVW real de origem e documentação dependente. Gerar matriz `KEEP/MOVE/ARCHIVE/UNKNOWN` e evidências; resolver `UNKNOWN` por inspeção, não por nome.
3. **GATE 2 — SAFE MIGRATION:** com autorização específica, mover lote pequeno, preservar `git mv`/conteúdo byte a byte, atualizar referências, executar apenas validações apropriadas e registrar rollback. Sem `Reload/STORE` produtivo por padrão.
4. **GATE 3 — ARTIFACT RETENTION:** escolher localização de backup, verificar os hashes reais dos binários existentes e registrar manifesto; testar recuperação em diretório vazio, sem sobrescrever originais. Decidir publicação pública/privada separadamente.

**Critérios BLOCKED:** falta de arquivos locais relevantes, referência circular/partida, script sem origem versionada, hash divergente, PRs/branches de higiene em mudança ou autorização ausente. **Condição de parada:** GATE 0 documentado e PR Draft disponível. Não converter automaticamente esta iniciativa em retomada do desenvolvimento QlikView.

## 6. Drift documental observado — tarefa separada

A `main@e3255b3b` já incorporou a [PR #238](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/238) (11/11/2026). No momento da consulta (12/11), havia **uma** PR aberta, [#239](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/239), Draft de backup/limpeza. `docs/project/current-state.md` ainda descreve **oito** PRs acadêmicos Draft e a proposta de preservação como não integrada. Isso é **drift comprovado**; requer reconciliação específica com nova evidência, sem edição oportunista neste PR de classificação. Não fechar nem excluir refs aqui.

---

**Resultado:** decisão revisada, inventário por Git SHA em branch; nenhum arquivo de produção, QVD, QVW, `.gitignore` ou entrypoint alterado. **PASS documental não equivale a PASS físico.**
