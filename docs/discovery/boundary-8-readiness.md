# BOUNDARY 8 — Readiness

**Projeto:** SAD — Data Mart SUS PB  
**Fase:** DATA ACQUISITION / QLIKVIEW IMPLEMENTATION DISCOVERY  
**Data de abertura:** 07/10/2026  
**Status:** IN PROGRESS — CONTROLLED NO-GO  
**Implementação definitiva:** BLOQUEADA

## 1. Objetivo

Executar o último gate antes da implementação definitiva.

O Boundary 8 deve comprovar, no ambiente Windows que executará o projeto:

1. QlikView 12 instalado e executável;
2. Python 3 disponível;
3. ambiente virtual reproduzível;
4. toolchain DBC funcional;
5. DBC → CSV reproduzindo contagem/schema conhecidos;
6. CSV legível pelo QlikView;
7. `Must_Include` funcional com caminhos do projeto;
8. reload por `Qv.exe /r` funcional;
9. tratamento de erro de batch sem interação;
10. fontes locais disponíveis;
11. proteção contra versionamento de dados/QVD;
12. protótipo mínimo da Link Table sem synthetic keys/circular references.

Somente depois desses controles o boundary poderá emitir **GO**.

---

## 2. Fontes consultadas

Repositório canônico:

- `AGENTS.md`;
- `docs/project/current-state.md`;
- `docs/academic/requirements.md`;
- `docs/discovery/boundary-3-full-dataset-validation.md`;
- `docs/discovery/boundary-4-auxiliary-references.md`;
- `docs/discovery/boundary-5-historization-role-playing.md`;
- `docs/discovery/boundary-6-qlikview-physical-architecture.md`;
- `docs/discovery/boundary-7-implementation-plan.md`.

Referências externas verificadas:

- PyPI — `dbc-to-dbf==1.0.1`;
- PyPI — `dbfread==2.0.7`;
- QlikView Help — command line `Qv.exe /r`;
- QlikView Help — `Must_Include`;
- QlikView Help — `ErrorMode` e variáveis de erro.

---

# 3. Preflight documental

| Item | Status | Evidência |
|---|---|---|
| Boundary 3 concluído | PASS | 108/108 DBCs validados |
| Boundary 4 concluído | PASS COM AJUSTES | referências oficiais fechadas; materializações ainda pendentes |
| Boundary 5 concluído | PASS | historização/role-playing definidos |
| Boundary 6 concluído | PASS | arquitetura física Link Table definida |
| Boundary 7 concluído | PASS | plano executável definido |
| Primeira entrega preservada | PASS | nenhum modelo acadêmico foi reaberto |
| Blocker acadêmico novo | NÃO IDENTIFICADO | nenhuma evidência nova exige alterar a modelagem |

---

# 4. Validação externa da toolchain Python

## 4.1 `dbc-to-dbf==1.0.1`

### FATO VERIFICADO

A versão 1.0.1 está publicada no PyPI.

Propriedades relevantes:

- Python >= 3.7;
- wheel `py3-none-any`;
- sistema operacional independente;
- implementação baseada no algoritmo BLAST;
- fornece `DBCDecompress`.

Status:

**PASS — disponibilidade do pacote.**

Isso não prova ainda funcionamento no ambiente local do projeto.

## 4.2 `dbfread==2.0.7`

### FATO VERIFICADO

A versão 2.0.7 está publicada no PyPI e possui wheel Python 2/3 independente de plataforma.

Status:

**PASS — disponibilidade do pacote.**

A compatibilidade operacional com a versão concreta de Python instalada deve ser validada pelo smoke test local.

---

# 5. Ajuste encontrado no Boundary 7 — ErrorMode

### FATO VERIFICADO

A documentação oficial de inicialização do QlikView indica `Qv.exe /r` para abrir, recarregar e fechar o documento.

A mesma documentação recomenda `ErrorMode=0` para execução em batch a fim de evitar mensagens de erro interativas.

A documentação de `ErrorMode` define:

- `0`: continua após falha;
- `1`: padrão interativo, solicita ação;
- `2`: dispara imediatamente a mensagem de falha.

### DECISÃO CORRIGIDA

O baseline automatizado não será `ErrorMode=2`.

Para batch:

```text
SET ErrorMode=0;
```

com inspeção explícita de:

- `ScriptError`;
- `ScriptErrorCount`;
- `ScriptErrorList`;

e interrupção controlada quando uma operação crítica falhar.

O marcador de sucesso só pode ser gerado no final de uma execução sem erro crítico.

A correção foi aplicada ao documento do Boundary 7.

### Gate local

Ainda é obrigatório testar esse comportamento no QlikView 12 do ambiente real.

---

# 6. Artefatos de readiness adicionados

## `tools/readiness_check.ps1`

Checker read-only para o ambiente local.

Valida:

- Windows;
- Python 3 >= 3.7;
- `.venv`;
- `dbc-to-dbf==1.0.1`;
- `dbfread==2.0.7`;
- imports das bibliotecas;
- localização do `Qv.exe`;
- diretório BASE;
- 36 RD;
- 36 LT;
- 36 ST;
- arquivos IBGE 2017–2019;
- espaço livre informativo;
- proteção mínima no `.gitignore`.

Não instala, baixa ou altera dependências.

## `tools/readiness_smoke.qvs`

Script mínimo para validar no QlikView:

- `Must_Include`;
- Inline LOAD;
- STORE em QVD;
- STORE de marcador CSV;
- variáveis de erro;
- execução sem prompt usando `ErrorMode=0`.

Não contém regra de negócio do Data Mart.

---

# 7. Proteção do repositório

### CORRIGIDO

O `.gitignore` foi alinhado à arquitetura física planejada para impedir versionamento acidental de:

- `BASE/DBC/`;
- `BASE/IBGE/`;
- `BASE/REFERENCIAS/`;
- `BASE/CONVERTIDA/`;
- `EXTRACAO/QVD/`;
- `TRANSFORMACAO/QVD/`;
- `*.qvd`;
- artefatos do smoke test.

Status:

**PASS.**

---

# 8. Readiness do ambiente local

Não existe evidência persistida suficiente para afirmar que o ambiente Windows de execução já possui:

- QlikView 12 executável;
- caminho de `Qv.exe`;
- Python 3 instalado;
- `.venv` criado;
- dependências Python instaladas;
- BASE extraída na estrutura planejada;
- smoke test DBC executado;
- smoke test QlikView executado.

Esses itens não podem ser inferidos a partir da existência dos arquivos no Project/Library.

Status:

**BLOCKED — LOCAL EXECUTION REQUIRED.**

---

# 9. Disponibilidade dos dados

### Evidência canônica

O Boundary 3 comprovou:

- RD: 36/36;
- LT: 36/36;
- ST: 36/36;
- total: 108/108;
- RD: 566.672 registros;
- LT: 35.518 registros;
- ST: 220.390 registros.

### Evidência disponível no Project/Library

Existem artefatos `BASE.zip` / `BASE(1).zip` e checkpoints individuais relacionados ao projeto.

### Limitação desta execução

Os bytes brutos desses arquivos não estão autorizados para materialização no runtime atual do agente.

Portanto, não foi possível executar neste ambiente um novo smoke test byte a byte usando `dbc-to-dbf`.

Isso não invalida o Boundary 3; apenas impede usar este runtime como substituto do ambiente local de implementação.

### Gate

No ambiente local, o checker deverá encontrar exatamente:

- 36 RD;
- 36 LT;
- 36 ST.

Depois, o smoke/inventário de conversão deverá reconciliar as contagens do Boundary 3.

---

# 10. IBGE

A validação acadêmica/dataset já utilizou as estimativas anuais 2017–2019.

Para readiness de implementação, os três arquivos devem estar fisicamente disponíveis na BASE local.

Status atual do ambiente local:

**UNVERIFIED.**

---

# 11. Referências auxiliares

O Boundary 4 fechou semanticamente as fontes, mas ainda existem materializações/testes pendentes:

- `PROC_REA × SIGTAP`;
- `DIAG_PRINC × CID-10`;
- `TP_LEITO/CODLEITO × referência oficial`.

### Classificação

Esses pontos não reabrem a modelagem.

Entretanto, antes de uma implementação integral das dimensões correspondentes, as referências precisam estar materializadas ou as lacunas precisam ser explicitamente tratadas.

Status:

**PARTIAL — implementação integral ainda não pronta.**

---

# 12. Nome histórico de estabelecimento

Regra já aprovada:

- não aplicar nome atual ao passado;
- não fazer forward fill/backfill sem evidência;
- manter ausência explícita em 2017-01 a 2017-05 se a fonte oficial não for comprovada.

Status:

**PASS — política definida; não é blocker estrutural.**

---

# 13. Link Table

A arquitetura está documentalmente fechada, mas o readiness exige uma validação mínima no QlikView real.

O protótipo deverá comprovar:

- três fatos de teste associadas somente por `%LINK_KEY`;
- dimensões compartilhadas ligadas à `LINK_ANALISE`;
- 0 synthetic keys não justificadas;
- 0 circular references;
- nenhum campo descritivo compartilhado acidentalmente.

Status:

**UNVERIFIED — QLIKVIEW LOCAL REQUIRED.**

---

# 14. Classificação dos testes T01–T29

## Pré-implementação / readiness

Devem ser executados antes do GO ou em smoke equivalente:

- T01 — 108 DBCs;
- T02 — hashes de entrada;
- T03 — total RD;
- T04 — total LT;
- T05 — total ST;
- T06 — schema ST 2019-12;
- T07 — 36 competências por família;
- T08 — presença dos campos obrigatórios;
- T20 — synthetic keys no protótipo mínimo;
- T21 — circular references no protótipo mínimo.

## Implementação — extração/transformação

Executados depois do GO, durante a implementação:

- T09–T19;
- T22–T23.

## Implementação — indicadores/referências

Executados antes de considerar os painéis prontos:

- T24–T29.

A classificação não reduz nenhum critério; apenas define em qual gate ele é executado.

---

# 15. Checklist atual

| Check | Status |
|---|---|
| QlikView 12 instalado/executável | UNVERIFIED |
| caminho de `Qv.exe` | UNVERIFIED |
| Python 3 >= 3.7 | UNVERIFIED |
| `.venv` | UNVERIFIED |
| pacote `dbc-to-dbf==1.0.1` existe | PASS |
| pacote `dbfread==2.0.7` existe | PASS |
| pacotes instalados localmente | UNVERIFIED |
| imports Python | UNVERIFIED |
| 108 DBCs no workspace local | UNVERIFIED |
| hashes reconciliados | UNVERIFIED |
| DBC smoke conversion | UNVERIFIED |
| CSV legível pelo QlikView | UNVERIFIED |
| `Must_Include` local | UNVERIFIED |
| `Qv.exe /r` local | UNVERIFIED |
| ErrorMode batch controlado | PLANEJADO / UNVERIFIED |
| IBGE 2017–2019 local | UNVERIFIED |
| referências auxiliares materializadas | PARTIAL |
| política de nome histórico | PASS |
| `.gitignore` seguro | PASS |
| espaço em disco | UNVERIFIED |
| Link Table smoke | UNVERIFIED |
| blocker acadêmico novo | NÃO |

---

# 16. Procedimento local para desbloqueio

Na raiz do repositório:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\readiness_check.ps1
```

Caso a BASE esteja fora da raiz:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\readiness_check.ps1 -DataRoot "C:\CAMINHO\PARA\BASE"
```

Para salvar evidência:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\readiness_check.ps1 -OutputPath ".\readiness-report.json"
```

Depois do preflight passar:

1. abrir QlikView 12;
2. criar temporariamente `tools\READINESS.qvw`;
3. deixar o script do QVW contendo apenas:

```text
$(Must_Include=readiness_smoke.qvs);
```

4. salvar o QVW na pasta `tools`;
5. fechar QlikView;
6. executar:

```cmd
"%QLIKVIEW_EXE%" /r "tools\READINESS.qvw"
```

7. confirmar a criação de:
   - `tools\readiness_smoke.qvd`;
   - `tools\readiness_smoke_success.csv`;
8. abrir o QVW e conferir o Table Viewer;
9. executar o protótipo mínimo de Link Table definido para o fechamento deste boundary.

Os artefatos do smoke não devem ser commitados.

---

# 17. Critério de GO

Emitir **GO** somente quando:

1. `readiness_check.ps1` retornar `LOCAL_PREFLIGHT_PASS`;
2. toolchain DBC reproduzir os checkpoints sem divergência;
3. inventário integral reconciliar 108/108 e contagens;
4. smoke QlikView gerar o marcador de sucesso;
5. reload `/r` não depender de interação;
6. Link Table mínima não gerar synthetic key/circular reference;
7. referências necessárias para a primeira implementação estiverem disponíveis ou com tratamento explícito aprovado;
8. nenhum novo blocker acadêmico existir.

---

# 18. Veredito atual

## `NO-GO — CONTROLADO`

Motivo:

**faltam evidências do ambiente local e smoke tests obrigatórios.**

Não é falha da arquitetura ou dos datasets.

É o comportamento correto do readiness gate: impedir que a implementação definitiva comece antes de comprovar que a toolchain local funciona.

O Boundary 8 permanece **IN PROGRESS**.

Próxima ação:

executar `tools/readiness_check.ps1` no ambiente Windows que executará o QlikView e incorporar o relatório resultante nesta documentação.
