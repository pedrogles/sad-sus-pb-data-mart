# Artefatos locais e recuperação operacional

SAD-STABILIZATION-01, 20/10/2026. Aplica a política existente de AGENTS.md; não altera arquitetura, modelagem ou autorização de execução.

| Classe | Tratamento |
| --- | --- |
| CANONICAL_QVW | EXTRACAO/EXT.qvw, TRANSFORMACAO/TRANSF.qvw, PAINEL/PAINEL.qvw: originais locais, fora do Git; não abrir/salvar como parte da recuperação |
| CANONICAL_QVD | 10 arquivos em EXTRACAO/QVD e 12 em TRANSFORMACAO/QVD no inventário desta execução; preservar sem Reload/STORE |
| TEST_QVW | Cópias e protótipos locais, também ignorados pelo Git; não promover a canônicos |
| RUNTIME_TEMP | Área efêmera de ensaios; não constitui backup ou evidência persistente |
| EVIDENCE_ROOT | Diretório privado persistente fora do Git, escolhido pelo responsável; preserva inventários, hashes e resultados |

## Cópia preservada

Raiz privada desta execução: `SAD_STABILIZATION_01_20261020`, em local autorizado pelo responsável e registrado no handoff local. Subdiretório `backup`, com caminhos relativos originais. Manifesto: `artifact-manifest-2026-10-20.csv`.

Os 25 arquivos foram copiados sem sobrescrita. SHA-256 de cada origem antes/depois, cópia e referência G1 coincidiram. Evidência: comandos locais de cópia/hash, sem execução do runner G1 ou QlikView; não é repetição nem aprovação de gate físico. Total: 96.708.026 bytes. Retenção: até autorização explícita de descarte.

Classificação: `LOCAL_COPY_ONLY`, pois origem e cópia estão no mesmo disco. Não há prova de `DISASTER_RECOVERY_VERIFIED`. Perda desse disco pode afetar ambas.

## Restauração

1. Localizar o manifesto privado e conferir a existência das 25 cópias.
2. Conferir SHA-256 de cada cópia contra o manifesto antes de usar.
3. Com autorização específica de destino, copiar para uma pasta nova e vazia, preservando caminhos relativos; jamais restaurar sobre os originais.
4. Conferir SHA-256 do destino contra o manifesto. Divergência interrompe a restauração afetada.
5. Reposição de canônicos, abertura/salvamento QlikView e recarga requerem autorização própria.

A integridade de todas as cópias foi conferida; não houve restauração sobre os originais nem teste funcional do conteúdo em QlikView.

## Limite de reprodutibilidade

EXT.qvw corresponde ao papel de extração (`EXTRACAO/ext_main.qvs`); TRANSF.qvw ao de transformação (`TRANSFORMACAO/transf_main.qvs`); PAINEL.qvw ao de apresentação (`PAINEL/painel_main.qvs`). Essa associação é funcional, não prova de igualdade do script embutido ou do commit produtor.

O commit produtor dos binários não foi comprovado. Os entrypoints de transformação e painel não reproduzem integralmente os protótipos. QVS não preserva sozinho objetos, layout e propriedades visuais de QVW. A recuperação byte a byte usa as cópias verificadas, sem alegar reconstrução visual a partir dos scripts.

Git LFS, armazenamento independente e publicação remota permanecem decisões separadas. Nenhum binário, dado bruto, log privado ou caminho pessoal deve entrar no commit documental.
