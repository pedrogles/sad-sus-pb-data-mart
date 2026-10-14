#!/usr/bin/env python3
r"""F3 — referências independentes de população IBGE por papel municipal e ano.

Executar na raiz do projeto, após instalar xlrd==2.0.2:
  py -3 .\tools\preflight_f3_denominadores_ibge.py --root . \
      --f1f2 "$env:TEMP\sad-f1-f2-20261014-191743" --out "$env:TEMP\sad-f3-01"

Somente leitura de XLS IBGE, referência municipal C5.2 e CSV/manifesto F1/F2.
Escreve apenas num novo diretório FORA do repositório, publicado após PASS.
Não implementa fatos, QVD, QVW, QlikView, indicadores T24-T26 ou contratos.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import shutil
import sys
import tempfile
from collections import Counter, defaultdict
from datetime import datetime, timezone
from pathlib import Path

from audit_municipal_pb_crosswalk import COLUMNS, rows_from_csv, validate_pairs

YEARS = ("2017", "2018", "2019")
SOURCE = {
    "2017": "estimativa_dou_2017.xls",
    "2018": "estimativa_dou_2018_20181019.xls",
    "2019": "estimativa_dou_2019.xls",
}
PB_TOTAL = {"2017": 4025558, "2018": 3996496, "2019": 4018127}
KNOWN = {
    ("2017", "250750"): 811598, ("2018", "250750"): 800323,
    ("2019", "250750"): 809015, ("2017", "250400"): 410332,
    ("2018", "250400"): 407472, ("2019", "250400"): 409731,
}
F1F2_NAMES = (
    "F1_fluxo_ano.csv", "F1_fluxo_competencia.csv",
    "F1_residencia_ano.csv", "F1_residencia_competencia.csv",
    "F1_servico_ano.csv", "F1_servico_competencia.csv",
    "F2_lt_municipio_ano_cobertura_candidata.csv",
    "F2_lt_municipio_competencia_observado.csv",
)
HEADERS = ("UF", "COD. UF", "COD. MUNIC", "NOME DO MUNICÍPIO", "POPULAÇÃO ESTIMADA")


def check(ok: bool, msg: str) -> None:
    if not ok:
        raise ValueError(msg)


def digest(path: Path) -> str:
    check(path.is_file(), f"Arquivo obrigatório ausente: {path}")
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def integer(value: str, label: str) -> int:
    check(bool(re.fullmatch(r"[0-9]+", value)), f"Inteiro inválido {label}: {value!r}")
    return int(value)


def cell_text(value: object) -> str:
    if isinstance(value, float):
        check(value.is_integer(), f"Célula numérica não integral: {value!r}")
        return str(int(value))
    return str(value).strip()


def pop_integer(value: object) -> int:
    main = cell_text(value).split("(", 1)[0]
    check(bool(main.strip()), "Célula POP vazia")
    stripped = "".join(c for c in main if "0" <= c <= "9")
    check(bool(stripped), f"POP sem dígitos: {value!r}")
    n = int(stripped)
    check(n > 0, f"POP não positiva: {value!r}")
    return n


def load_ibge(root: Path, bridge: dict[str, str]) -> tuple[dict[tuple[str, str], int], dict]:
    try:
        import xlrd
    except ImportError as exc:
        raise ValueError("Dependência xlrd ausente: instale xlrd==2.0.2") from exc
    population: dict[tuple[str, str], int] = {}
    hashes = {}
    for year, filename in SOURCE.items():
        path = root / "BASE" / "IBGE" / filename
        hashes[filename] = digest(path)
        workbook = xlrd.open_workbook(str(path), on_demand=True)
        try:
            sheet = workbook.sheet_by_name("Municípios")
            check(sheet.nrows >= 225 and sheet.ncols >= 5, f"Planilha IBGE incompleta: {filename}")
            actual = tuple(cell_text(sheet.cell_value(1, c)).strip() for c in range(5))
            check(actual == HEADERS, f"Cabeçalho IBGE não confirmado: {filename}: {actual}")
            for r in range(2, sheet.nrows):
                if cell_text(sheet.cell_value(r, 0)).upper() != "PB":
                    continue
                uf = cell_text(sheet.cell_value(r, 1)).zfill(2)
                municipal = cell_text(sheet.cell_value(r, 2)).zfill(5)
                check(bool(re.fullmatch(r"25[0-9]{5}", uf + municipal)),
                      f"IBGE município inválido {filename}:{r+1}")
                ibge7 = uf + municipal
                datasus6 = ibge7[:6]
                check(bridge.get(datasus6) == ibge7, f"IBGE sem par C5.2: {ibge7}/{year}")
                key = (year, datasus6)
                check(key not in population, f"IBGE município×ano duplicado: {key}")
                population[key] = pop_integer(sheet.cell_value(r, 4))
        finally:
            workbook.release_resources()
        year_keys = {m for y, m in population if y == year}
        check(year_keys == set(bridge), f"IBGE cobertura 223 municípios divergente: {year}")
        check(sum(population[(year, m)] for m in bridge) == PB_TOTAL[year],
              f"IBGE total anual divergente: {year}")
    check(len(population) == 669, "IBGE 669 município×ano não confirmado")
    for key, expected in KNOWN.items():
        check(population[key] == expected, f"Referência conhecida divergente: {key}")
    return population, hashes


def read_csv(path: Path, columns: tuple[str, ...]) -> list[dict[str, str]]:
    check(path.is_file(), f"CSV F1/F2 ausente: {path.name}")
    with path.open(encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh, delimiter=";")
        check(tuple(reader.fieldnames or ()) == columns,
              f"Colunas F1/F2 divergentes: {path.name}")
        records = list(reader)
    check(bool(records), f"CSV F1/F2 vazio: {path.name}")
    check(all(None not in r and all(v is not None for v in r.values()) for r in records),
          f"CSV F1/F2 malformado: {path.name}")
    return records


def read_f1f2(folder: Path, c5_sha: str) -> tuple[dict, dict, dict]:
    path = folder / "manifest_F1_F2.json"
    manifest = json.loads(path.read_text(encoding="utf-8"))
    hashes = manifest.get("output_sha256")
    check(isinstance(hashes, dict) and set(hashes) == set(F1F2_NAMES),
          "Manifesto F1/F2: conjunto de oito CSV inválido")
    for name in F1F2_NAMES:
        check(digest(folder / name) == hashes[name], f"SHA F1/F2 divergente: {name}")
    check(manifest.get("source_sha256", {}).get("MUNICIPAL_C5_2", {}).get("sha256") == c5_sha,
          "Referência C5.2 não é a mesma do F1/F2")
    check(manifest.get("rd", {}).get("counts", {}).get("eligible") == 555089,
          "Manifesto F1/F2: universo RD divergente")
    check(manifest.get("lt", {}).get("counts", {}).get("rows") == 35518,
          "Manifesto F1/F2: universo LT divergente")
    annual = {}
    for role, filename, field in (
        ("RES", "F1_residencia_ano.csv", "municipio_residencia"),
        ("SERV", "F1_servico_ano.csv", "municipio_servico"),
    ):
        fields = ("ano", field, "registros_rd", "internacoes_elegiveis", "continuidades_ident5")
        rows = read_csv(folder / filename, fields)
        counts = Counter()
        for row in rows:
            year, municipal = row["ano"], row[field]
            check(year in YEARS and bool(re.fullmatch(r"[0-9]{6}", municipal)),
                  f"F1 {role}: ano/código municipal inválido")
            key = (role, year, municipal)
            check(key not in annual, f"F1 {role}: grão duplicado {key}")
            n = integer(row["internacoes_elegiveis"], "internações")
            total = integer(row["registros_rd"], "linhas RD")
            cont = integer(row["continuidades_ident5"], "continuidades")
            check(total == n + cont, f"F1 {role}: decomposição inválida {key}")
            annual[key] = {"internacoes": n, "registros": total, "continuidades": cont}
            counts[year] += n
        check(dict(counts) == {"2017": 183532, "2018": 183311, "2019": 188246},
              f"F1 {role}: controle anual divergente")
    lt_month = {}
    for row in read_csv(folder / "F2_lt_municipio_competencia_observado.csv",
                        ("ano", "competencia", "municipio_servico", "linhas_lt", "qt_sus", "qt_exist", "qt_nsus", "estado", "universo")):
        year, month, mun = row["ano"], row["competencia"], row["municipio_servico"]
        check(year in YEARS and bool(re.fullmatch(r"20(17|18|19)(0[1-9]|1[0-2])", month))
              and month[:4] == year and bool(re.fullmatch(r"25[0-9]{4}", mun)),
              "F2: coordenada mês/município inválida")
        k = (year, month, mun)
        check(k not in lt_month, f"F2: grão mensal duplicado {k}")
        n = integer(row["linhas_lt"], "linhas LT")
        check(n > 0, "F2: grupo observado sem linhas")
        sus, exist, nsus = (integer(row[x], x) for x in ("qt_sus", "qt_exist", "qt_nsus"))
        check(exist == sus + nsus, "F2: identidade QT_* divergente")
        lt_month[k] = sus
    check(len(lt_month) == 3561, "F2: 3.561 grupos municipais/mensais esperados")
    return annual, lt_month, {"manifest_sha256": digest(path), "csv_sha256": hashes}


def write_csv(path: Path, columns: tuple[str, ...], rows: list[dict]) -> None:
    with path.open("x", encoding="utf-8", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=columns, delimiter=";", lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def compute(pop: dict, bridge: dict, annual: dict, lt_month: dict) -> dict[str, list[dict]]:
    keys = [(y, m) for y in YEARS for m in sorted(bridge)]
    rows_pop, rows_res, rows_serv, rows_ext = [], [], [], []
    for year, mun in keys:
        people = pop[(year, mun)]
        ibge7 = bridge[mun]
        res = annual.get(("RES", year, mun), {"internacoes": 0, "registros": 0})
        serv = annual.get(("SERV", year, mun), {"internacoes": 0, "registros": 0})
        observed = [f"{year}{mo:02d}" for mo in range(1, 13)
                    if (year, f"{year}{mo:02d}", mun) in lt_month]
        sus = sum(lt_month[(year, month, mun)] for month in observed)
        rows_pop.append(dict(ano=year, cod_datasus_6=mun, cod_ibge_7=ibge7,
                             populacao_estimada=people))
        rows_res.append(dict(ano=year, municipio_residencia=mun,
                             internacoes_elegiveis=res["internacoes"],
                             registros_rd=res["registros"], denominador_populacao=people,
                             estado="POP_PB_ANUAL_VALIDA_COMPONENTE_SEM_RAZAO"))
        rows_serv.append(dict(ano=year, municipio_servico=mun,
                              internacoes_elegiveis=serv["internacoes"],
                              denominador_populacao=people, meses_lt_com_linhas=len(observed),
                              soma_qt_sus_snapshots_auditoria=sus if observed else "",
                              media_qt_sus_numerador_candidato=sus if len(observed) == 12 else "",
                              media_qt_sus_divisor_candidato=12 if len(observed) == 12 else "",
                              estado_capacidade="12_MESES_LINHAS_ESCOPO_NAO_VERIFICADO"
                              if len(observed) == 12 else "COBERTURA_AUSENTE_NAO_ZERO"))
    for (role, year, mun), vals in sorted(annual.items()):
        if role == "RES" and mun not in bridge:
            rows_ext.append(dict(ano=year, municipio_residencia=mun,
                                 internacoes_elegiveis=vals["internacoes"],
                                 registros_rd=vals["registros"],
                                 denominador_populacao="",
                                 estado="FORA_DA_REFERENCIA_PB_INDISPONIVEL"))
    check(sum(int(r["internacoes_elegiveis"]) for r in rows_ext) == 5067,
          "Elegíveis residentes externos: 5.067 não reconciliados")
    check(sum(int(r["internacoes_elegiveis"]) for r in rows_res) == 550022,
          "Internações residentes PB: 550.022 não reconciliadas")
    scenarios = []
    for year in YEARS:
        for role, selection, members in (
            ("RES", "PB_223", sorted(bridge)),
            ("RES", "JP_CG_2", ["250400", "250750"]),
            ("SERV", "PB_223", sorted(bridge)),
            ("SERV", "JP_CG_2", ["250400", "250750"]),
        ):
            unique = sorted(set(members))
            denom = sum(pop[(year, m)] for m in unique)
            numerator = sum(annual.get((role, year, m), {}).get("internacoes", 0) for m in unique)
            months = [f"{year}{n:02d}" for n in range(1, 13)]
            complete = (role == "SERV" and all((year, month, mun) in lt_month
                        for mun in unique for month in months))
            mean_num = sum(lt_month[(year, month, mun)] for mun in unique for month in months) if complete else ""
            scenarios.append(dict(ano=year, papel=role, selecao=selection,
                                  municipios_distintos=len(unique),
                                  codigos_municipios=",".join(unique),
                                  denominador_pop_somado_uma_vez=denom,
                                  numerador_internacoes_elegiveis=numerator,
                                  capacidade_media_sus_numerador_candidato=mean_num,
                                  capacidade_media_sus_divisor_candidato=12 if complete else "",
                                  capacidade_estado="CANDIDATO_RN21_SEM_ESCOPO_HOSPITALAR"
                                  if complete else "NAO_APLICAVEL_OU_COBERTURA_INCOMPLETA"))
            if selection == "PB_223":
                check(denom == PB_TOTAL[year], f"Pop total PB multi município divergente {year}")
    return {
        "F3_pop_municipio_ano.csv": rows_pop,
        "F3_componentes_residencia_ano.csv": rows_res,
        "F3_componentes_servico_ano.csv": rows_serv,
        "F3_residentes_externos_ano.csv": rows_ext,
        "F3_cenarios_multimunicipais.csv": scenarios,
    }


COLUMNS_OUT = {
    "F3_pop_municipio_ano.csv": ("ano", "cod_datasus_6", "cod_ibge_7", "populacao_estimada"),
    "F3_componentes_residencia_ano.csv": ("ano", "municipio_residencia", "internacoes_elegiveis", "registros_rd", "denominador_populacao", "estado"),
    "F3_componentes_servico_ano.csv": ("ano", "municipio_servico", "internacoes_elegiveis", "denominador_populacao", "meses_lt_com_linhas", "soma_qt_sus_snapshots_auditoria", "media_qt_sus_numerador_candidato", "media_qt_sus_divisor_candidato", "estado_capacidade"),
    "F3_residentes_externos_ano.csv": ("ano", "municipio_residencia", "internacoes_elegiveis", "registros_rd", "denominador_populacao", "estado"),
    "F3_cenarios_multimunicipais.csv": ("ano", "papel", "selecao", "municipios_distintos", "codigos_municipios", "denominador_pop_somado_uma_vez", "numerador_internacoes_elegiveis", "capacidade_media_sus_numerador_candidato", "capacidade_media_sus_divisor_candidato", "capacidade_estado"),
}


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--root", type=Path, required=True)
    p.add_argument("--f1f2", type=Path, required=True, help="Pasta dos nove artefatos F1/F2 auditados")
    p.add_argument("--out", type=Path, required=True, help="Diretório de saída NOVO, fora da raiz Git")
    args = p.parse_args()
    root = args.root.expanduser().resolve(strict=True)
    inputs = args.f1f2.expanduser().resolve(strict=True)
    out = args.out.expanduser().resolve(strict=False)
    check(out != root and root not in out.parents and not out.exists(),
          "Saída não pode existir nem ficar no repositório")
    check(inputs != out and inputs not in out.parents and out not in inputs.parents,
          "Entradas e saída não podem se sobrepor")
    check(out.parent.is_dir(), "Diretório pai de saída não existe")
    print("MODE=F3_IBGE_ANNUAL_POP_DENOMINATOR_REFERENCE_READ_ONLY")
    print("SOURCE_FILES_WRITTEN=0 QVD_WRITES=0 QLIKVIEW_RUN=False")
    bridge_path = root / "EXTRACAO" / "QVD" / "REF_MUNICIPIO_PB_DERIVADA.csv"
    bridge_rows = rows_from_csv(bridge_path, COLUMNS)
    validate_pairs(bridge_rows)
    bridge = {r["COD_DATASUS_6"]: r["COD_IBGE_7"] for r in bridge_rows}
    check(len(bridge) == 223, "C5.2 223 pares inválidos")
    source_hashes = {"C5_2": digest(bridge_path)}
    annual, lt_month, f1_meta = read_f1f2(inputs, source_hashes["C5_2"])
    print("F1_F2_HASHES_PASS=8/8 MUNICIPAL_C5_2_MATCH=True")
    population, xls_hashes = load_ibge(root, bridge)
    source_hashes["IBGE_XLS"] = xls_hashes
    print("IBGE_SOURCE_PASS ROWS=669 MUNICIPIOS=223 ANOS=3 TOTALS=4025558/3996496/4018127")
    results = compute(population, bridge, annual, lt_month)
    check(len(results["F3_pop_municipio_ano.csv"]) == 669
          and len(results["F3_componentes_residencia_ano.csv"]) == 669
          and len(results["F3_componentes_servico_ano.csv"]) == 669
          and len(results["F3_cenarios_multimunicipais.csv"]) == 12,
          "Contagem de saídas F3 inesperada")
    print("F3_ROLE_AND_MULTI_MUNICIPAL_COMPONENTS_PASS EXTERNAL_NO_PB_DENOM=5067")
    originals = {str(root / "BASE" / "IBGE" / name): h for name, h in xls_hashes.items()}
    originals[str(bridge_path)] = source_hashes["C5_2"]
    originals[str(inputs / "manifest_F1_F2.json")] = f1_meta["manifest_sha256"]
    originals.update({str(inputs / name): h for name, h in f1_meta["csv_sha256"].items()})
    for path, h in originals.items():
        check(digest(Path(path)) == h, f"Entrada alterada: {path}")
    staging = Path(tempfile.mkdtemp(prefix=f".{out.name}-stage-", dir=out.parent))
    published = False
    try:
        for filename, rows in results.items():
            write_csv(staging / filename, COLUMNS_OUT[filename], rows)
        manifest = {
            "mode": "F3_IBGE_ANNUAL_POP_DENOMINATOR_REFERENCE_READ_ONLY",
            "verdict_scope": "F3_SOURCE_COMPONENTS_ONLY_QV_AND_T24_T26_NOT_APPROVED",
            "created_utc": datetime.now(timezone.utc).isoformat(),
            "script_sha256": digest(Path(__file__).resolve()),
            "input_sha256": originals,
            "output_sha256": {name: digest(staging / name) for name in results},
            "source": "IBGE XLS PB 2017-2019, 223x3; crosswalk C5.2 derived project; F1/F2 verified CSV",
            "limits": ["No QlikView selection test", "No fact QVD or Link Table", "No T24-T26 final ratios",
                       "No POP for residents outside PB", "No hospital-scoped capacity proof",
                       "No multi-year single KPI", "No implicit zero for missing LT rows",
                       "T29_HISTORICAL=NOT_APPROVED"],
        }
        with (staging / "manifest_F3.json").open("x", encoding="utf-8") as fh:
            json.dump(manifest, fh, sort_keys=True, ensure_ascii=False, indent=2)
            fh.write("\n")
        for path, h in originals.items():
            check(digest(Path(path)) == h, f"Entrada alterada durante escrita: {path}")
        check(not out.exists(), "Destino surgiu durante execução")
        os.rename(staging, out)
        published = True
    finally:
        if not published:
            shutil.rmtree(staging, ignore_errors=True)
    print("SOURCE_SHA256_BEFORE_AFTER_UNCHANGED=True")
    print("OUTPUT_FILES_COUNT=6")
    print("VERDICT=PASS_F3_SOURCE_COMPONENTS_ONLY_CONTRACT_NOT_APPROVED")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, UnicodeError, csv.Error, json.JSONDecodeError, KeyError) as exc:
        print(f"VERDICT=BLOCKED_F3 {type(exc).__name__}: {exc}", file=sys.stderr)
        raise SystemExit(1)
