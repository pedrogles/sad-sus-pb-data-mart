# AGENTS.md — SAD Data Mart SUS PB

## Finalidade e leitura obrigatória

Este arquivo contém **regras duradouras para agentes**, não o log operacional. Antes de tarefas estruturais, consultar nesta ordem:

1. `AGENTS.md`;
2. `docs/project/current-state.md` (snapshot operacional vigente);
3. `docs/academic/requirements.md`;
4. documentação específica da tarefa, incluindo decisões em `docs/academic/` e `docs/discovery/`.

Revalidar a fonte de verdade de código/dados no repositório e nos arquivos efetivamente inspecionados. **PRs Draft não fazem parte da `main`** até integração confirmada; sempre distinguir evidência em branch de decisão versionada na main.

## Hierarquia das fontes e evidências

1. Material oficial da disciplina/professor;
2. Documentação oficial DATASUS, Ministério da Saúde, CNES e IBGE;
3. Dados reais e artefatos inspecionados;
4. Documentação canônica versionada;
5. Chats/memória apenas como contexto auxiliar.

Distinguir explicitamente **FATO VERIFICADO**, **HIPÓTESE DE MODELAGEM** e **DECISÃO PENDENTE**. Qualificar evidência por origem: execução local reportada, arquivo/log conferido independentemente, inspeção estática, teste automatizado/CI ou aprovação formal. Não converter PASS de protótipo em aprovação de produção.

Não inventar campos, chaves, granularidades, medidas, entidades, cardinalidades, regras de negócio, compatibilidade entre fontes ou vigência normativa.

## Decisões acadêmicas que devem ser preservadas

- **QlikView 12 obrigatório.** Fluxo acadêmico: `BASE → EXTRACAO/EXT.qvw → QVD → TRANSFORMACAO/TRANSF.qvw → QVD → PAINEL/PAINEL.qvw`. Scripts externos `.qvs` versionáveis são complementares; o `.qvw` não é única fonte de verdade.
- Primeira entrega impressa dos Capítulos 1 e 2 **informada como realizada em 13/10/2026**; avaliação do professor ainda não confirmada. Não reabrir modelagem silenciosamente.
- Esquema **Star por processo factual**, compondo constelação de estrelas com dimensões conformadas, sem Snowflake dimensional.
- **Três fatos:** `FATO_INTERNACAO`, `FATO_CAPACIDADE_LEITO`, `FATO_POPULACAO`.
- **Oito dimensões:** `DIM_TEMPO`, `DIM_MUNICIPIO`, `DIM_ESTABELECIMENTO`, `DIM_PROCEDIMENTO`, `DIM_DIAGNOSTICO`, `DIM_CARATER_ATENDIMENTO`, `DIM_MOTIVO_SAIDA_PERMANENCIA`, `DIM_TIPO_LEITO`.
- Grãos: registro administrativo SIH/RD; capacidade CNES por estabelecimento × competência × código de leito; população por município × ano. `IDENT=5` não representa internação nova; `N_AIH` não é PK.
- Leitos e população são semi-aditivos no tempo; não somar snapshots mensais de capacidade para obter capacidade anual. Não chamar `internações/leito` de taxa de ocupação.
- Preservar todos os registros LT válidos; recorte estritamente hospitalar é analítico e exige classificação histórica defensável. Município de residência e de atendimento são papéis distintos; residentes fora da PB não recebem população municipal PB artificial.
- `T29_HISTORICAL=NOT_APPROVED`: legenda CNES de setembro/2019 é apenas descritiva e datada, sem aplicação retroativa automática; manter aviso metodológico futuro. Não preencher coordenadas fisicamente inaplicáveis com valores inventados.

Regras completas: `docs/academic/chapter-1-2-modeling.md`, `docs/discovery/boundary-5-historization-role-playing.md`, `boundary-6-qlikview-physical-architecture.md` e `boundary-7-implementation-plan.md` no mesmo diretório. **A ordem de implementação aprovada nos Boundaries não deve ser alterada silenciosamente.**

## Contrato mínimo de execução e encerramento

Antes de executar, registrar **objetivo**, **fontes**, **escopo tocável**, **invariantes**, **critérios PASS/BLOCKED**, **evidências** e **condição de parada**. Trabalhar com PRs de objetivo único. Mudança material de arquitetura ou semântica requer evidência e aprovação explícita do responsável.

- Ao atingir o gate contratado, **encerrar esse gate** mesmo que outras frentes permaneçam pendentes. Separar `GATE_PASS`, `PR_MERGED` e `PROD_APPROVED`.
- Nova questão independente vira **decisão pendente/novo escopo proposto**; não estender o PR atual automaticamente com novas fases, testes de interface ou exploração normativa.
- Após falha, obter causa/log antes de alterar código. Não criar sequências R2/R3/R4 sem limite de investigação e justificativa.
- O `current-state.md` contém apenas **estado atual, impedimentos e próximo passo**, com links para provas; histórico cronológico, contadores, hashes e tentativas permanecem em Discovery/Git.
- Preserve invariantes, evite regressões e mantenha distinção entre revisão estática, teste local Windows/QlikView, CI e validação independente. Não alegar execução que não ocorreu.
- **Nenhum merge, exclusão de branch, force push, mudança estrutural ou geração de dado de produção sem autorização específica.** Higiene de branches: inventário + dry-run + confirmação HEAD/PR + rollback rastreável.

## Dados, segurança e operações

Não versionar QVDs, QVWs binários, datasets grandes, dados brutos, saídas locais e artefatos derivados automaticamente. Antes de publicar qualquer dado, conferir licença, tamanho, proveniência e finalidade. Para testes locais, usar QVW/QVD de origem somente leitura quando essa for a fronteira aprovada, verificando preservação por hash quando necessário.

**Roteamento operacional vigente:** `docs/project/current-state.md`. Não reconstruir a situação presente a partir de seções cronológicas antigas, descrição acumulativa do PR #83 ou memória.

## Versionamento obrigatorio dos scripts de implementacao e validacao

Todo script executavel PowerShell, Python ou QVS utilizado para implementar, recarregar, auditar ou fundamentar um gate do SAD deve estar **commitado em branch do repositorio canonico antes da execucao local**. O executor deve informar o commit de origem e, para scripts criticos, conferir SHA-256 dos QVS/insumos. Correcao posterior requer novo commit e nova evidencia: nao herdar PASS automaticamente de uma revisao anterior.

Pacotes ZIP podem apenas distribuir copias de scripts ja versionados, identificando branch e commit; **nao sao fonte de verdade do codigo**. Manter logs brutos, QVDs, QVWs de teste, dados e exportacoes locais fora do Git, registrando caminhos, hashes e resultados relevantes em documento de Discovery. Testes exploratorios descartaveis nao versionados sao permitidos apenas quando explicitamente rotulados `EXPERIMENTAL_NOT_GATE_EVIDENCE`; antes de sustentar PASS ou implantacao devem ser regularizados no Git e executados a partir do commit versionado. Nenhum merge ou alteracao estrutural e autorizado por esta regra.
