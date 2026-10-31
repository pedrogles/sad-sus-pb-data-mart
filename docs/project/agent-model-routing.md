# Política de roteamento de agentes, modelos e ambientes — SAD SUS PB

**Versão:** 0.2 · 20/10/2026  
**Vigência:** **CANÔNICA NA MAIN** desde a integração confirmada do [PR #126](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/126) em 20/10/2026. Este ajuste corrige apenas o cabeçalho histórico; não altera as permissões, a matriz de roteamento nem a arquitetura.  
**Autoridade:** complemento operacional de `AGENTS.md`; subordinada aos requisitos acadêmicos, fontes oficiais, contratos físicos e decisões aprovadas.  
**Responsável pela aprovação:** mantenedor do projeto.

## 1. Finalidade e princípios

Padronizar os **próximos bootstraps** para que toda tarefa declare agente, modelo e esforço *efetivamente disponíveis*, ambiente, permissões, fontes, critérios de prova, custo relativo, fallback, escalonamento, condição de parada e handoff.

1. **Leitura obrigatória antes de tarefa estrutural:** `AGENTS.md` → `docs/project/current-state.md` → `docs/academic/requirements.md` → documentação específica. Registrar `main@SHA`, distinguir Draft de main e, em teste físico, o commit real dos scripts executados.
2. **Menor privilégio:** começar em `READ-ONLY`. Alteração documental em branch, QVW TEMP, execução COM/GUI, alteração de dados, merge e produção são permissões *diferentes*. Um bootstrap **não concede** nenhuma delas.
3. **Prova graduada:** `SCRIPT_VERSIONED` ≠ `PASS_LOCAL_REPORTED` ≠ `ORACLE_RECONCILED` ≠ `PNG_CAPTURED` ≠ `VISUAL_ACCEPTED` ≠ `PROD_APPROVED`. Usar `FATO_VERIFICADO`, `RELATO_LOCAL_NAO_AUDITADO`, `HIPOTESE` ou `DECISAO_PENDENTE`.
4. **Preservar contrato científico:** QlikView 12, fluxo BASE→EXTRACAO→QVD→TRANSFORMACAO→QVD→PAINEL, constelação Star (3 fatos/8 dimensões), regras SIH/RD, CNES/LT, IBGE e ordens do Boundary 7. Nunca aprovar índices, universos ou chaves por conveniência.
5. **Economia controlada:** um agente primário e um gate por vez; reutilizar fontes, scripts e provas anteriores; escalonar só com dificuldade material documentada. Não gastar capacidade Work/Codex/alto raciocínio sem ganho demonstrável.

## 2. Matriz de escolha padrão

| Tarefa | Agente e ambiente preferidos | Esforço inicial | Escalar somente quando | Evidência mínima |
| --- | --- | --- | --- | --- |
| Triagem do estado, PRs, docs e bootstrap | ChatGPT + GitHub, leitura | Instant simples; Medium padrão onde disponível | Divergência relevante entre fontes → High | `main@SHA`, links, diferença main×Draft |
| Inventário longo, múltiplos arquivos/sites | Work Cloud **ou** ChatGPT + conectores | Medium disponível | Limitação real de navegação/complexidade → High ou Work | Inventário delimitado, referências |
| Python, PowerShell, QVS, correção de runner | Codex Local; Cloud apenas se dispensar Windows | Medium disponível no Codex | Erro de parser/runtime com log e causa não resolvida → High | branch, commit, diff, parser e revisão |
| QlikView 12, COM, recarga ou QVW descartável | Codex Local **no Windows autorizado**; alternativa operador humano | Medium disponível | Falha COM persistente e reproduzível → High/revisão | hash QVD/QVW pré/pós, stdout, log, oráculo |
| GUI QlikView, painéis, screenshots | Work Local *se interação demonstrada*; fallback humano | Medium disponível | Contradição visual concreta → High | cenário, screenshot, revisão humana |
| CNES histórico, P5, D2, temporalidade, denominadores | ChatGPT + fontes oficiais e repositório | Medium triagem; High para risco semântico real | Evidência conflitante sem resolução → revisão independente | hipótese, fonte, contrato, decisão formal |
| Relatório acadêmico/painéis finais | ChatGPT/Work (documento); Codex Local (scripts) | Medium disponível | Inconsistência acadêmica/semântica específica → High | QlikView real, prints, anexos e revisão |

**Modelo:** registrar o nome **exibido no ambiente usado** e seu nível real (`Instant`, `Medium`, `High`, `Extra High` ou equivalente). GPT-6/Medium é uma preferência ilustrativa, não uma garantia de acesso; Work e Codex podem ter seletores diferentes. Não exigir nomes como `Sol`, `Luna`, `GPT-6.1` ou `Astra High` que talvez não existam no ambiente do executor. Não inventar preço, cota, economia percentual nem disponibilidade de um plano.

### Distinção dos ambientes

- **ChatGPT + GitHub:** leitura, síntese, proposta e PR documental explicitamente autorizado; o conector GitHub não dá acesso ao Windows local.
- **Work Cloud:** computador/navegador gerenciado; **não** pressupõe pastas Windows nem COM do usuário.
- **Work Local:** arquivos/interface somente quando o recurso estiver disponível e com acesso autorizado; não pressupor clique, estabilidade de controle UI ou COM.
- **Codex Cloud:** alteração e análise de código em ambiente remoto, sem presumir QlikView Desktop local.
- **Codex Local:** terminal e repositório em host autorizado; QlikView 12 requer Windows/Qv.exe/COM ou operação GUI comprovados separadamente.
- **Pessoa operadora:** fallback padrão quando automação de GUI falhar ou não oferecer identificação segura dos controles.

## 3. Permissões e classes de parada

Cada bootstrap deve definir **leituras, escritas permitidas e proibições**. Usar categorias operacionais:

| Estado | Interpretação | Resposta |
| --- | --- | --- |
| `HARD_STOP` | Integridade/SHAs divergentes, escrita indevida em QVD/QVW, violação semântica, falta de autorização | Parar; preservar evidência; pedir decisão específica |
| `RECOVERABLE_BLOCK` | Checkout divergente, arquivo temporário ausente, caminho inválido, pré-requisito ambiental verificável | Encerrar gate atual; propor subgate ambiental não mutante, **sem** executar novo teste por conta própria |
| `INCONCLUSIVE` | Log ausente, QlikView/GUI inacessível, fonte não comprovada, revisão visual insuficiente | Declarar o limite; nunca promover a PASS |
| `ADVISORY` | Documentação desatualizada, custo relativo, nomenclatura e redundância de PR | Registrar melhoria sem bloquear operação segura automaticamente |

**Invariantes:** scripts executáveis usados para sustentar gate devem estar commitados antes da execução; comparar SHA de fontes e artefatos protegidos antes/depois; manter QVD/QVW originais e evidência fora de Git. Nunca usar `git clean`, `reset --hard`, `stash -u` ou exclusão de artefatos não rastreados como atalho. Checkout e worktree com acesso a QVDs exigem inventário de colisões e permissão própria.

**Persistência:** `RUNTIME_TEMP` é o local para cópias QVW descartáveis. `EVIDENCE_ROOT` é a raiz **persistente** de stdout/logs/CSV/PNG/manifestos/SHA, fora de Git e de TEMP volátil, com acesso/retomada verificados no ambiente Windows antes de qualquer gate que dependa dela.

**Reexecução:** contrato inicial de *uma tentativa por gate*, análise da primeira falha e STOP. Repetir somente com erro concreto, correção versionada e nova autorização. Não repetir PASSs restritos já encerrados nem transformar descoberta colateral em novo escopo automaticamente.

## 4. Template obrigatório para todo novo bootstrap

O bloco abaixo deve estar **preenchido**, exceto itens inaplicáveis explicitamente marcados. Reusar links desta política em vez de copiar toda a matriz.

```markdown
### Roteamento operacional do gate
- ID / objetivo único / condição de parada:
- Fonte de verdade: main@SHA; AGENTS; current-state; requirements; docs do gate
- Estado de integração: main vs PR Draft@HEAD; commit executado (se houver)
- Agente primário: ChatGPT | Work Cloud | Work Local | Codex Cloud | Codex Local | humano
- Modelo e esforço efetivos: [nome visível e nível] ou [não selecionável / não aplicável]
- Fallback e escalonamento: [quem assume]; disparar somente com [evidência concreta]
- Ambiente confirmado: [cloud / Windows local / QlikView 12 COM / GUI], capacidades verificadas
- Permissões: leituras ...; escritas autorizadas ...; ações proibidas ...
- Insumos e invariantes: [script/QVS commitado, SHA, QVD/QVW, oráculos, contrato semântico]
- RUNTIME_TEMP: [caminho / não aplicável]; EVIDENCE_ROOT: [caminho persistente / não aplicável]
- Orçamento do gate: [levantamentos, tentativas, limite de exploração e justificativa de recursos]
- PASS: ...; HARD_STOP: ...; RECOVERABLE_BLOCK: ...; INCONCLUSIVE: ...
- Evidências e níveis: [stdout, hash, log, CSV, screenshot, auditoria independente, aceite humano]
- Handoff: feito / não feito / próximo passo mínimo / agente e ambiente de destino
```

Quando um modelo ou ferramenta não estiver disponível, registrar **fallback real**, sem fingir alteração de configuração. Para auditoria documental, `RUNTIME_TEMP`, `EVIDENCE_ROOT` e COM podem ser `não aplicável`. O template é regra de *descrição*, não permissão automática para rodar ou modificar.

## 5. Adoção, revisão e manutenção

1. **G0 (histórico, encerrado):** institucionalização ocorreu no PR #126, integrado à `main` em 20/10/2026. A aprovação daquele merge não aprovou outros gates, scripts, QVW/QVD ou produção.
2. **Vigente:** cada bootstrap deve referenciar esta política em `main` e preencher o bloco, sem transportar resumos de versões antigas como fonte de verdade.
3. **Semântica e dados:** alterações da política não mudam grãos, fatos, dimensões, regras de indicadores, QVS, runners, QVD, QVW nem autorização das Fases VIII/IX.
4. **Medição:** observar 3–5 gates comparáveis antes de revisar a matriz: agente/modelo/esforço real, duração, tentativas, causa de bloqueio, consumo qualitativo de recurso e suficiência da evidência. Nenhum ganho financeiro é presumido.
5. **Governança:** revisão pelo responsável via PR. Se produto/modelos mudarem, alterar **somente** a matriz canônica, preservando o template e a fonte de verdade.

**Efeito da publicação:** o documento já orienta os novos bootstraps na `main`; não concede novos acessos, não homologa QlikView, não inicia G1 e não aprova produção.
