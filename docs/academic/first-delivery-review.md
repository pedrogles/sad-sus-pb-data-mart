# Revisão da Primeira Entrega — Capítulos 1 e 2

## Status

**PRONTO PARA FINALIZAÇÃO EDITORIAL E IMPRESSÃO, COM DADOS DE CAPA PENDENTES**

A modelagem e a redação foram consolidadas a partir de:

- material oficial da disciplina;
- documentação oficial das fontes;
- dados reais inspecionados;
- `docs/discovery/dataset-validation.md`;
- `docs/academic/chapter-1-2-modeling.md`;
- `docs/academic/chapter-1-draft.md`;
- `docs/academic/chapter-2-draft.md`.

---

## Checklist do roteiro do professor

| Requisito | Status | Evidência no projeto |
|---|---|---|
| Capa com título “Proposta de um Data Mart na área de ...” | OK | Relatório consolidado usa “Saúde Pública” |
| Sumário | OK | Montado no relatório |
| Cap. 1 — descrição detalhada das regras de negócio | OK | 21 regras consolidadas |
| Entidades | OK | 13 entidades conceituais |
| Relacionamentos | OK | Matriz de relacionamentos documentada |
| Cardinalidades mínima e máxima | OK | `(0,n)`, `(1,n)`, `(1,1)` explicitadas |
| Modelo conceitual / DER | OK | Diagramado e revisado |
| Modelo lógico relacional normalizado | OK | Diagramado com PKs, FKs e cardinalidades |
| Cap. 2 — escolha Star x Snowflake | OK | Star Schema aprovado e justificado |
| Modelo dimensional | OK | Três estrelas + constelação |
| Mínimo de 6 dimensões | OK | 8 dimensões justificadas |
| Mínimo de 1 fato | OK | 3 fatos com granularidades próprias |
| Primeira entrega até Capítulo 2 | OK | Documento termina nas considerações do Capítulo 2 |

---

## Diagramas incluídos no relatório

1. Modelo Conceitual — DER;
2. Modelo Lógico Relacional Normalizado;
3. Esquema Estrela — Internação;
4. Esquema Estrela — Capacidade de Leitos;
5. Esquema Estrela — População;
6. Modelo Dimensional completo — constelação de esquemas estrela.

---

## Formatação adotada no artefato de impressão

- papel A4;
- margens acadêmicas de referência: 3 cm superior/esquerda e 2 cm inferior/direita;
- fonte Times New Roman;
- corpo 12;
- espaçamento 1,5 no texto;
- páginas de diagramas conceitual/lógico em orientação paisagem quando necessário;
- numeração iniciada no Capítulo 1;
- figuras e tabelas numeradas e acompanhadas de fonte;
- sumário com paginação revisada.

A disciplina não forneceu, nos materiais inspecionados, um template tipográfico específico além do roteiro estrutural. Por isso, a formatação acima é uma escolha editorial acadêmica e não deve ser tratada como exigência expressa do professor.

---

## Pendências antes da impressão

### Dados de capa

Substituir:

`[PREENCHER NOMES DO GRUPO]`

pelos integrantes definitivos.

### Conferência humana final

Antes da impressão:

1. confirmar os nomes dos integrantes;
2. confirmar “João Pessoa - PB” como local de apresentação, se aplicável;
3. abrir o PDF final e conferir a impressora selecionada em orientação automática/retrato-paisagem;
4. imprimir preferencialmente em escala 100% ou “tamanho real” para preservar a legibilidade dos diagramas.

---

## Não bloqueia a primeira entrega

Permanecem para a etapa de implementação:

- aquisição/carga integral dos 36 meses;
- materialização das tabelas de referência por competência;
- historização física de `DIM_ESTABELECIMENTO`;
- scripts QlikView/QVD/QVW;
- dashboards;
- validação integral dos indicadores.

Esses itens não alteram a suficiência acadêmica atual dos Capítulos 1 e 2.
