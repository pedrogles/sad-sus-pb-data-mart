# SAD SUS PB — M0: proposta de rebaseline para MVP acadêmico

**Data:** 07/11/2026  
**Status:** PROPOSTA DOCUMENTAL PARA DECISÃO — NÃO APROVADA NEM VIGENTE NA MAIN  
**Baseline consultada:** main@0549e1dba71aaa8bbab9d6755aecb8465f8bea83 (último commit encontrado em 07/11/2026)  
**Natureza:** auditoria de viabilidade, redução de escopo de consumo, não implementação  
**Autorização desta etapa:** solicitação de prosseguimento da auditoria e preparação do rebaseline. Não equivale a aprovação da alteração material dos contratos previamente aceitos.

## 1. Problema e resultado esperado

O objetivo acadêmico é apresentar um Data Mart **funcional, compreensível e reproduzível no QlikView 12**, com pelo menos três painéis e as evidências e scripts descritos no roteiro do professor. A execução atual acumulou contratos físicos/semânticos, QVWs TEMP, runners e PRs de C2 sem conclusão do painel final.

A decisão M0 é escolher se continuaremos com:
- **Opção B — recomendada:** preservar as três fatos, oito dimensões, fontes e QVDs; simplificar apenas o **consumo e a aceitação**, com análises independentes, sem indicadores cross-fact no MVP;
- **Opção A:** preservar todos os 14 visuais/contratos atuais e continuar C2→C3→C4→IX;
- **Opção C:** propor ao professor substituição do escopo acadêmico por uma única fato/fonte e novo projeto, somente se a recuperação controlada da opção B falhar ou houver decisão explícita de revisão acadêmica.

**Nenhuma opção altera automaticamente o modelo entregue ou a main.**

## 2. Fontes de verdade e evidência

Leitura obrigatória feita na main: AGENTS.md → docs/project/current-state.md → docs/academic/requirements.md. Consultados também Boundary 7, blueprint de três painéis, inventário analítico, closeout 14/14 e scripts QVS existentes. O roteiro oficial DescricaoProjetoSAD.pdf exige conceitual/lógico/dimensional, no mínimo 6 dimensões, 1 fato e 3 painéis. Para arquivos de origem, a suficiência é analisada caso a caso pelo professor. A primeira entrega (Capítulos 1–2) foi reportada como realizada em 13/10/2026 e seu parecer ainda não foi confirmado.

**FATO VERIFICADO POR INSPEÇÃO ESTÁTICA:** PAINEL/painel_main.qvs ainda é esqueleto e não carrega o painel final; TRANSFORMACAO/transf_main.qvs é entrypoint parcial com carga de dimensões e geração de FATO_INTERNACAO desativada por padrão. Os executores/PoCs isolados não provam recarga ponta a ponta pelo entrypoint canônico.

**EVIDÊNCIA LOCAL REPORTADA (não auditada em bytes nesta etapa):** 108/108 DBCs convertidos; 10 QVDs extração, 12 QVDs transformação, três QVWs canônicos; SIH/RD 566.672 registros administrativos, 555.089 novas internações; CNES/LT 35.518; CNES/ST 220.390; IBGE 669 município×ano; 36 competências 2017–2019; resultados independentes P1–P3 com oráculos arquivados.

**FATO VERIFICADO NO GITHUB:** 21 PRs abertos em 07/11/2026, muitos de C2; #223 tem aceite visual restrito de F1/F2, #224 ensaio de Clear e #225 plano de recuperação de persistência do TX17. São evidências de branch/execução local, não estado aprovado da main. Issues #196 (C2) e #157 (suficiência científica T25/T26) permanecem abertas.

**NÃO VERIFICADO AQUI:** existência física atual, integridade binária ou carga real dos QVDs/QVWs no Windows, compatibilidade integral de associações, comportamento final de filtros/seleções ou aceitação docente.

## 3. Invariantes da opção B

1. QlikView 12 e fluxo BASE → EXTRACAO/EXT.qvw → QVD → TRANSFORMACAO/TRANSF.qvw → QVD → PAINEL/PAINEL.qvw.
2. Modelo Star/constelação entregue: FATO_INTERNACAO, FATO_CAPACIDADE_LEITO e FATO_POPULACAO; oito dimensões acadêmicas existentes. Não apagar fatos ou dimensões para disfarçar complexidade.
3. Período e granularidades de 2017–2019; IDENT=5 não conta como nova internação; N_AIH não é PK; papéis de residência e serviço distintos.
4. População e leitos são semi-aditivos no tempo. Não somar snapshots anuais de capacidade nem população em anos distintos; ausência de LT não equivale a zero.
5. Não alegar cobertura hospitalar integral por CNES/LT, validade histórica T29, ocupação por internações/leito, ou integração municipal IBGE sem validação.
6. Manter provas, códigos, QVDs, QVWs e documentos existentes intactos. Nada de merge, exclusão de branch, alterações nos artefatos originais ou descarte de modelagem impressa por esta proposta.

## 4. MVP de consumo — proposta de nove visuais e três folhas

A apresentação final é **uma QVW com três folhas**, sujeita a prova de comportamento associativo. Cada folha tem contexto de tempo/território explícito. O recorte operacional é somente o suportado pelos QVDs e oráculos existentes. A maioria dos visuais é derivada dos 14 já especificados; o POP descritivo demanda confronto físico adicional.

| Folha | Visual | Fato e regra | Critério mínimo |
|---|---|---|---|
| P1 Produção | 1. Total de novas internações por ano | FI.QTD_INTERNACAO, competência administrativa; IDENT=5=0 | 2017=183.532, 2018=183.311, 2019=188.246 conforme oráculo arquivado |
| P1 Produção | 2. Série mensal | FI.QTD_INTERNACAO por 36 competências | Paridade de valores na janela escolhida; distinguir histórico trienal de seleção de ano |
| P1 Produção | 3. Ranking município de atendimento | FI, papel SERV, sem confundir RES | Comparar ranking e total com extrato P1.3 |
| P2 Leitos observados | 4. Série de leitos SUS/existentes | FL por competência mensal, snapshots | Cada ponto é uma competência; nenhum somatório entre meses |
| P2 Leitos observados | 5. Distribuição municipal por competência | FL, município de localização, competência **única** | Paridade com P2.4/recorte reconciliado; sem linha não vira zero |
| P2 Leitos observados | 6. Observabilidade | Município × competência, positivos/zeros observados/sem linha, usando evidência P2.3 | Distinguir os três estados; ilha A1 somente se indispensável e autorizada |
| P3 Fluxo e contexto territorial | 7. R=S versus R≠S | FI, comparar códigos RES/SERV por registro | Paridade com P3.2 e universos |
| P3 Fluxo e contexto territorial | 8. Pares RES→SERV | FI, agregação por origem e destino dirigidos | Paridade com P3.1/P3.3; externos identificados sem imputação POP |
| P3 Fluxo e contexto territorial | 9. População anual municipal | FP, município × ano, somente descrição e filtro local validado | 669 linhas de base e valores por município/ano conferidos contra QVD/origem; não multiplicar em 12 competências |

**Importante:** visuais e nomes acima são proposta, não reclassificação do blueprint PR #209 como obsoleto. Se o uso da população em P3 conflitar com a ergonomia ou modelo de seleção, ela pode ficar em uma seção visível separada dentro da terceira folha, mas NÃO será vinculada por inferência à fato SIH.

**Fora do MVP (adiado, não reprovado):** T24/T25/T26 e outras razões cross-fact, taxa de ocupação, descrição histórica CNES sem referência, modos guiados redundantes, 14/14 visuais simultâneos e cobertura de todo atalho nativo. Os indicadores de uma fato permanecem obrigados a refletir o estado real de seleção; nunca mostrar número obsoleto como atual.

## 5. Proposta arquitetural de consumo — decisão pendente

**Não substituir a LINK_ANALISE aprovada silenciosamente.** Duas alternativas físicas, a testar em cópia somente se autorizadas:
- **B1 — reuso controlado (padrão):** carregar estruturas canônicas no modelo de consumo e restringir campos/expressões e interações aos nove visuais. Validar somente associações e filtros efetivamente expostos, sem promover o contrato global de Link Key.
- **B2 — consumo em ilhas/visões independentes:** separar fisicamente campos/filtros de cada processo (inclusive POP) dentro da QVW, sem associations acidentais. Esta opção **pode alterar** o contrato de Link Key/blueprint; somente após decisão arquitetural explícita e teste de carga/seleções.

**Gate de escolha:** em Windows/QlikView 12, avaliar uma única cópia TEMP com nomes reais de campos, tabela de associações e dois casos representativos (fato única e contexto POP). Se B1 produzir resultado enganoso ou acoplamento imprevisto, registrar BLOCKED_B1; B2 é proposta subsequente, nunca fallback automático. Não inferir que diferentes folhas isolam o modelo associativo por si só.

## 6. Política temporal simplificada proposta

Preferir filtros nativos explícitos por competência/ano e visuais que respeitam a natureza mensal (FI/FL) e anual (FP). Evitar modo guiado adicional ANUAL/MENSAL/EVOLUCAO se a análise puder funcionar sem ele.

**D2-R2 V3 permanece vigente na main.** Eliminar ou reduzir os botões/variáveis guiados exige adendo semântico do responsável. Enquanto houver controle guiado, manter prevenção antes do despacho. Nas operações nativas, reavaliar contexto real por indicador, exibir indisponibilidade explicada em ambiguidades e evitar números incorretos/stale. Não prometer prevenção global antes de ações nativas.

Mínimo de testes para cada grupo de visuais: (i) contexto basal reconciliado; (ii) um filtro relevante; (iii) um estado de tempo/filtro ambíguo ou indisponível representativo. Um erro material encerra a rodada; a correção precisa de causa comprovada. Não testar indiscriminadamente menus/atalhos sem risco demonstrado.

## 7. Plano de execução e critérios de STOP — substituição proposta, não vigente

| Marco | Deliverable | PASS | BLOCKED/STOP |
|---|---|---|---|
| M0 Decisão e inventário | Este documento com escopo, dependências e deltas; classificação de Drafts relevantes | Responsável decide B1 ou alternativa; identifica revisão formal de Boundary 7, D2-R2, P5 e blueprint | Sem decisão, parar em PROPOSTA; não implementar |
| M1 Recuperação de pipeline | Inventário físico read-only dos 22 QVDs/3 QVWs e hashes + manifesto de execução de scripts; entrypoints/sources rastreáveis | Carga de referência reproduzível em cópia sem sobrescrever fontes, tot/contagens preservados | Falta de arquivo, deriva de schema ou integridade: STOP e causa; não reprocessar tudo por padrão |
| M2 Consumo e três folhas | PAINEL.qvw isolado, 9 visuais e evidências reais | 3 folhas legíveis, números cruzados com oráculos existentes, filtro/tempo por uso, ausência tratada, nenhuma associação enganosa | Erro de medida/associação/seleção: STOP por caso, não novo runner genérico |
| M3 Entrega acadêmica | Capítulos 3–5, anexos I/II, prints QlikView, referências e arquivos exigidos | Conferência contra roteiro oficial e data da segunda avaliação confirmada | Escopo incompatível com Cap. 1–2 ou exigência docente: consulta/revisão explícita |

**Ordem vigente até aprovação material:** C2 → C3 → C4 → autorização IX; M1–M3 são roteiro candidato e **não dão acesso antecipado à IX**. A revisão formal deve declarar exatamente quais subgates/garantias deixam de ser aplicáveis, em vez de declarar PASS retroativo.

**Limite anti-loop proposto:** um diagnóstico com evidência por falha e no máximo duas correções dentro do objetivo; persistindo a falha, BLOCKED e decisão de produto (reduzir, mudar apresentação, aceitar limitação explicitada ou adiar). Nunca criar automaticamente R2/R3/R4 ou uma nova PR para cada objeto Qlik. Consolidar execução em um PR de objetivo funcional, reutilizando runners já aprovados; provas descartáveis ficam em evidências locais.

## 8. Inventário de PRs C2 — triagem sem alterar branches

Em 07/11/2026, GitHub retornou 21 PRs abertos (principalmente Drafts); #223 contém prova visual F1/F2 restrita, #224 contém experimento Clear/TX17 e #225 trata apenas persistência TX17. Antes de reabrir qualquer teste, classificar cada Draft em REUSE_EVIDENCE / RELEVANT_TO_MVP / DEFERRED / SUPERSEDED após leitura do conteúdo, sem merge em lote. Manter Issue #196 aberta como status histórico do C2 vigente; Issue #157 permanece bloqueio científico de T25/T26 (fora do MVP).

## 9. Matriz de revisão das decisões aprovadas

| Fonte | Tratamento na opção B | Necessita nova aprovação? |
|---|---|---|
| Capítulos 1–2, 3 fatos/8 dimensões, grãos | PRESERVAR | Não para simples reuso; sim para alteração |
| Boundary 7, sequência física C2→C3→C4→IX | PRESERVAR até adendo delimitado | SIM para mudança na precedência ou gates |
| D2-R2 V3, proteção guiada e revalidação nativa | PRESERVAR até adendo | SIM para simplificação de garantia e interface |
| P5 V2, política C/R/I/B | PRESERVAR até adendo | SIM para alterar compatibilidade/escopo de filtros |
| Blueprint PR #209, 14 visuais | REFERÊNCIA histórica; propor 9 visuais MVP | SIM para substituir como escopo final |
| Link Table Boundary 6 | PRESERVAR ou experimentar B1 em TEMP | SIM para substituição por B2/ilhas |
| T24/T25/T26 e T29 históricos | Fora do MVP enquanto não sustentados; ressalvas mantidas | SIM se alterar compromisso acadêmico ou apresentar razões |
| Evidência local de QVDs e PoCs | REUTILIZAR, não homologar retroativamente | Revisão física somente quando necessária |

## 10. Decisões M0 aguardadas e condição de encerramento

1. **Escopo:** aprovar o conceito da opção B com nove visuais e população anual descritiva, sem abandonar as três fatos?
2. **Implementação:** autorizar o desenho de um adendo CONTROLADO ao Boundary 7/D2/P5/blueprint, sem tocar main ou QVW/QVD antes da revisão?
3. **Critério de redução:** aceitar que contratos globais/cross-fact não são bloqueio de visuais independentes, preservando teste físico dos filtros/associações expostos?

**STATUS DESTE DOCUMENTO = M0_PROPOSAL_WRITTEN / CONTRACT_CHANGE_NOT_APPROVED / PHYSICAL_EXECUTION_NOT_AUTHORIZED.** Encerrar após a publicação da proposta e revisão; não abrir automaticamente outro gate, não criar novo runner e não promover qualquer evidência a aceite.
