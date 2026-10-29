# P3.1 — matriz completa observada RES→SERV, competência 2018

## Contrato e roteamento antes da execução

- Gate: `SAD-P31-SIH-RES-SERV-MATRIX-2018-READONLY-01`. Objetivo único: validar todos os pares observados de E1 em 2018; STOP ao concluir ou bloquear P3.1.
- Fonte de verdade: `origin/main@6f35f86b1d672949d9921cb948463000e02aacdd`, correspondente à main remota consultada. PR #189 confirmado merged pelo conector GitHub, merge SHA idêntico, em 29/10/2026. A referência local `main` estava atrasada; não foi usada como baseline.
- Leituras na main: AGENTS, current-state, requirements, escopo analítico aprovado e matriz de fontes; política `docs/project/agent-model-routing.md` integrada e consultada.
- Agente primário: Codex Local, Windows/PowerShell, Python 3.14.8. Modelo específico e esforço efetivo não expostos de forma verificável; Medium solicitado, não confirmado/não selecionável nesta sessão. Sem subagentes.
- Escopo tocável: novo validador Python, este relatório e current-state, somente na branch `test/sad-p31-sih-res-serv-matrix-2018-readonly-01`. Evidências derivadas na pasta persistente `.p31-evidence/20261029-01/` do projeto, excluída localmente do Git. RUNTIME_TEMP não aplicável.
- Fonte original somente leitura: `C:/Users/pedro/SAD_EVIDENCIAS/AE01_20261027_02/sih_fluxo_competencia.csv`; SHA pinado `F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615`.
- Reuso: constantes de schema, SHA, períodos e controle anual e funções `require`, `uint`, `sha256` do validador P1.3; não chamar seu ranking nem repetir P1/P2. A0 R1 fornece somente testemunhos 250180→250750=3806 e 250750→250750=39060.
- Invariantes: direção RES→SERV, códigos sem nomes, ano de competência, medidas distintas e registros=novas+continuidades; IDENT=5 não conta nova. A origem agregada não permite nova auditoria do IDENT individual. Nenhuma alteração acadêmica, QVS/QVD/QVW, COM, cross-fact, Link Key ou produção.
- PASS_RESTRICTED: pin/schema/grão íntegros; 12 competências coerentes; cobertura de todos os pares observados, inclusive soma zero; soma de novas=183311; dois testemunhos; readback integral do CSV; cópia adulterada rejeitada; original preservado; scripts commitados antes da execução; evidências persistidas.
- BLOCKED: fonte/ambiente/prova indisponível. INCONCLUSIVE/HARD_STOP: divergência de semântica, schema, grão, somas ou SHA. Não corrigir fonte para obter PASS.
- Orçamento: uma execução positiva e um negativo de integridade sobre cópia (LF adicional); não atribuir a esse negativo cobertura dos validadores semânticos internos. Sem nova tentativa automática após falha.
- Fallback/handoff: operador com Python e bytes pinados, apenas se ambiente insuficiente; escalonar ao responsável somente diante de divergência concreta preservada em log. Sem troca de modelo alegada.
- Evidência: execução local Python e leitura de arquivos/logs, não auditoria independente/CI nem aceite visual. Publicação remota depende de confirmação específica; nenhum merge autorizado.
- Próximo candidato após encerramento: P3.2, sem execução neste gate.

## Resultado

Pendente da execução a partir do commit versionado. `GATE_PASS=False`, `PR_MERGED=False`, `PRODUCTION_APPROVED=False`.
