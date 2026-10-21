# Fase VIII — C4-B1 | Readback de oráculos F2/F3 regionais, READ-ONLY (20/10/2026)

**Veredito limitado:** `C4_B1_REFERENCE_PREFLIGHT=PASS_EXPORTED_REFERENCE_READBACK_C4B1_NO_QLIK`. Isto **não é** execução QlikView, aprovação física de T25, validação de cobertura hospitalar nem aceite de `MEASURES_AND_DENOMINATOR_CONTRACT`.

## Proveniência / material auditado

- **Base de branch:** `main@949e6e96b6e0f4e530672d52808ad178080bce28`; readiness [PR #139](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/139) e triagem C4-A [PR #140](https://github.com/pedrogles/sad-sus-pb-data-mart/pull/140) continuam **Draft, fora da main**.
- **Objetivo único:** auditar o cenário `ano=2018`, `papel=SERV`, `selecao=JP_CG_2` (municípios de serviço `250400` Campina Grande e `250750` João Pessoa), conferindo 24 pares município×competência e o agregado regional T25 observacional, **sem executar COM**.
- **Código versionado antes da execução:** `tools/validate_sad_c4b1_regional_f2f3.py`, commit de criação `6647f35447152d0a7505d0949805e760ece76fb2`, Git blob `2db8557ae35a0decbde27985f0d1c0caeab32da0`, SHA-256 dos bytes executados `E2EF48CC3288DAC5BF43597F2E77CB31B6F6FA78367972234CA8477240572F1C`. Uma cópia **byte a byte idêntica** foi executada no ambiente isolado Linux/Python do ChatGPT contra os três anexos enviados nesta conversa; `git hash-object` dessa cópia coincidiu com o blob do repositório antes de executar. **Não** alegar execução Windows/QlikView.
- **Oráculos (3 CSVs anexados):**
  - `F2_lt_municipio_competencia_observado.csv`: 3.561 registros, SHA-256 `DC0FAE8646F6570F5DEEAF8A1597EA5ED90A5BD9A881A40B4DCA0E30380E953D`;
  - `F2_lt_municipio_ano_cobertura_candidata.csv`: 669 registros, SHA-256 `97EB032F3A7E444B436349608A2B73F61D597E83DBB7576E47BB5ABBCC82512D`;
  - `F3_cenarios_multimunicipais.csv`: 12 registros, SHA-256 `3B7315A564666D43A43E60700B5ACC4E255FEF6535F53219EC3D8A08C74CBFF9`.
- Os três hashes coincidem com os `output_sha256` já auditados dos manifestos F1/F2 e F3 no pacote C3-B2; os próprios manifestos **não foram reenviados neste turno**, e não foi necessário regenerá-los. Scripts dos geradores e schema foram lidos na versão histórica congelada `26369052bd3f96de5f3eccf873c390053c20b561`.
- Evidência derivada local fora do Git: `c4b1_reference_readback_20261020.json`, SHA-256 `DEDF51028258E958ADE1A44AA345D75E8C8E85B2D8A9B35311A43057635830C0`. Contém 12 totais regionais mensais, contagens e estados. O próprio artefato JSON não é versionado.
- **Guarda observada:** na primeira chamada, o validador retornou `BLOCKED: output must be outside input directory` **antes de ler e processar CSVs**; não foi criado JSON. Em seguida, foram criadas **cópias isoladas** dos três CSVs em diretório de entrada separado e o arquivo de saída permaneceu fora desse diretório. Não houve mudança no código versionado, correção semântica, repetição COM, nem escrita de dados de produção. Os três hashes dos originais permaneceram iguais após a auditoria.

## Reconciliação física de arquivos CSV (não do modelo Qlik)

| Condição verificada | Resultado |
| --- | --- |
| SHA-256 de três fontes contra pins previamente congelados | 3/3 PASS |
| Cabeçalhos CSV exatos dos geradores históricos | 3/3 PASS |
| Chaves sem duplicação nos 3.561 meses-município F2, 669 municípios-ano F2 e 12 cenários F3 | PASS |
| `2018/SERV/JP_CG_2`: único cenário F3 | 1 linha |
| `2018/250400` e `2018/250750`, `201801..201812` | **24/24 linhas presentes**, 12/12 competências por cidade |
| Identidades mensais `QT_EXIST=QT_SUS+QT_NSUS`, contagens LT positivas, valores não negativos | PASS nos 24 pares |
| Status de mês e universo | `LINHAS_OBSERVADAS_NUMEROS_RECONCILIADOS`; `LT_TODOS_REGISTROS_VALIDOS_RN21` |
| F2 controle anual, meses observados/divisor e cobertura | 2/2 PASS: `12_OF_12_ROWS_OBSERVED_NOT_FINAL_SCOPE_VALIDATED` |
| F2 `hospitalar_historico_validado` | **`NAO`** em ambas as cidades |
| F3 cenário regional × F2 totais/POP e elegíveis | PASS, no **universo observacional** |

### Valores verificados

| Município | Soma de `QT_SUS` dos 12 snapshots mensais (apenas auditoria) |
| --- | ---: |
| Campina Grande (`250400`) | 16.592 |
| João Pessoa (`250750`) | 28.106 |
| **Regional** | **44.698** |

- **Média mensal regional observada:** `44.698/12=3.724,833333…`; não são 44.698 leitos simultâneos/anuais.
- **População F3 regional, somada uma vez por município/ano:** `1.207.795`.
- **Internações de serviço F3 elegíveis, controle auxiliar não usado na razão T25:** `119.857`.
- **T25 regional candidato:** `1000×(44.698/12)/1.207.795 = 3,083994662449615483863845547740579596151` leitos SUS médios observados/1.000 habitantes.
- **Soma de linhas LT físicas observadas nos 24 pares:** 5.299; essa contagem é distinta dos quantitativos `QT_SUS`, não prova cadastro hospitalar integral.

**Agregação correta:** cada competência regional contém a soma dos dois municípios no mesmo mês; `44.698` é a soma posterior desses 12 totais para formar **média ÷12**, nunca uma capacidade de estoque anual. Uma média simples das razões municipais não é a taxa regional.

## Conclusão e bloqueios

**`C4_B1_REFERENCE_PREFLIGHT=PASS_EXPORTED_REFERENCE_READBACK_C4B1_NO_QLIK`** fecha **somente** a reconciliação de oráculos CSV do recorte proposto em C4-A. Permanece necessário, em gate **futuro e separadamente autorizado**, avaliar se a seleção simultânea de dois municípios de **serviço** no QVW TEMP produz exatamente o denominador populacional anual não duplicado, a soma F2 e a razão candidata, com integridade dos 22 QVDs e três QVWs. **Nenhum runner COM C4-B1 foi criado, commitado ou executado neste gate.**

O **próximo passo admissível** é revisar este relatório e decidir explicitamente se autoriza **preparar** um executor físico versionado para C4-B1 (aprovação distinta de **executar** `-RunQlik`). Não iniciar outros municípios ou T26 regional por inferência.

**Estados preservados:** `C4_B1_PHYSICAL=NOT_RUN_NOT_AUTHORIZED`; `C4_PHYSICAL=NOT_RUN_NOT_AUTHORIZED`; `LINK_KEY_CONTRACT=NOT_APPROVED`; `MEASURES_AND_DENOMINATOR_CONTRACT=NOT_APPROVED`; `C2_FULL=NO_GO_NOT_APPROVED`; `F4_P5_PHYSICAL_FILTERS=NOT_TESTED_FULLY`; `P5_D2_UI=NOT_TESTED`; `CNES_HOSPITAL_SCOPE_COVERAGE=NOT_VERIFIED`; `T29_HISTORICAL=NOT_APPROVED`; `PHASE_IX=NOT_AUTHORIZED`; `PRODUCTION_APPROVED=False`.

**STOP:** auditoria e documento versionados em PR Draft específico. Sem merge, exclusão de branches, mudança estrutural, original QVD/QVW, dados brutos, SIH/CNES/IBGE originais ou dashboard.
