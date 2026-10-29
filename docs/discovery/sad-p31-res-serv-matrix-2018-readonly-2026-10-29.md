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

**FATO VERIFICADO — execução local Python, 29/10/2026 às 15:26:31 America/Sao_Paulo (18:26:31 UTC): `PASS_RESTRICTED`, exit=0.** Commit executado: `51c55d8e5576ad665b6ba91fe2811cb268e022e8`, criado antes da execução. O runner verificou presença dos dois scripts nesse commit e ausência de diferenças contra as cópias locais antes de processar a fonte.

- E1: 1.016.979 bytes; SHA antes/depois e após negativo idêntico ao pin; schema exato, 30.255 grãos únicos no original, zero duplicações, medidas inteiras não negativas e decomposição consistente. Validações estruturais abrangem o arquivo; não reexecutam os produtos P1/P2.
- Recorte 2018: 10.078 linhas mensais, 12 competências coerentes; **1.944 pares direcionados observados**, incluindo **2 pares com zero internações novas**. Não materializa produto cartesiano nem imputa zero a pares ausentes.
- Totais: **187.293 registros AIH = 183.311 internações novas + 3.982 continuidades**. Somas por par, mês e anual coincidem nas três medidas. Readback do CSV integral coincide com os 1.944 registros calculados, campo a campo.
- Testemunhos: `250180→250750=3.806`; `250750→250750=39.060`. Ambos coincidem; não substituíram a validação integral.
- Negativo: cópia `negative_e1_altered.csv` com LF adicional rejeitada pela mesma função de validação, com `E1_SHA256_MISMATCH`. Rejeição capturada no audit/log; não houve processo separado com exit=2. O processo completo retornou 0 porque o negativo foi rejeitado como esperado. Este teste cobre integridade, não constitui bateria de mutações de schema/medidas.
- Divergências: nenhuma. Nenhuma hipótese adicional de modelagem adotada. `GATE_PASS=True`, **`PR_MERGED=False`**, **`PRODUCTION_APPROVED=False`**. Sem aceite visual ou independente/CI.

## Evidências persistentes e SHA-256

Raiz absoluta: `C:/Users/pedro/Documents/programming/sad-sus-pb-data-mart/.p31-evidence/20261029-01/`. Arquivos derivados permanecem fora do índice Git, excluídos por `.git/info/exclude`, sem cópia para a fonte original.

| Artefato | SHA-256 |
| --- | --- |
| `p31_matrix_2018.csv` | `0BB265A52B097E3FC77B800BA546432423C1EE5D7A11440957D3B2894CF9EE19` |
| `p31_audit.json` | `91F5D0DA85E577329F84DE0C72182A50678EE5CE551EF998C9C66761E3BB327F` |
| `execution.log` (mesmo relatório estruturado) | `91F5D0DA85E577329F84DE0C72182A50678EE5CE551EF998C9C66761E3BB327F` |
| `negative_e1_altered.csv` | `A09E49472C4A42D8E41DEE264EBD9C201575B69EB82E6C1DCAE4163F74906514` |
| `sha256_manifest.json` | `277933D1129B9DA3E26D3E8371EF5F7C967D99978E5EE90FCDA63B78F7572331` |
| Script P3.1 executado | `AD1C2E005BE463F2106A6ACA68FDE8E9FE5236F5E869528A6ECF2900200EF7E5` |
| Módulo P1.3 reutilizado | `80B18B9C58EB1AB8DF3EDFD651A78D0DFB90934082281E33CE754CDB300C9CD5` |

Comando executado no checkout da branch:

```powershell
python -B tools/validate_sad_p31_res_serv_matrix01.py --e1 C:/Users/pedro/SAD_EVIDENCIAS/AE01_20261027_02/sih_fluxo_competencia.csv --output-dir .p31-evidence/20261029-01 --source-commit 51c55d8e5576ad665b6ba91fe2811cb268e022e8
```

Não repetir a execução encerrada. O runner recusa diretório de saída preexistente. Hashes dos scripts referem-se aos bytes locais efetivamente executados; checkout com conversão LF/CRLF pode ter hash de arquivo distinto, embora o blob Git seja equivalente.

## Fechamento e handoff

P3.1 numérico concluído. **DECISÃO PENDENTE:** confirmação específica para push desta branch e criação do PR Draft, exigida pelas regras globais fornecidas no bootstrap. Nenhuma publicação remota realizada neste fechamento; o estado de integração deve ser consultado novamente após eventual publicação. Merge não autorizado.

Sem bloqueio técnico remanescente de P3.1. Próximo gate candidato **P3.2**, não executado. Restrições de QlikView/COM, visual, associações globais, Fase IX e produção continuam vigentes. O histórico operacional permanece em Discovery e Git; current-state recebe somente o snapshot atual.
