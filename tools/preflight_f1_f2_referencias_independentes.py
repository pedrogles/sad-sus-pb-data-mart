#!/usr/bin/env python3
r"""SAD/SUS-PB — F1/F2: referências independentes de SIH/RD e CNES/LT.

READ-ONLY nas fontes: lê CSVs originais, jamais altera arquivos existentes.
Não usa QVDs, QlikView, SKs, LINK_KEY ou scripts factuais.
Grava apenas CSV/JSON em DIRETÓRIO NOVO, fora da raiz do repositório.
Os outputs são referências candidatas, NÃO aprovação física de indicadores.

Windows (na raiz do repo):
    py -3 sad_f1_f2_referencias_independentes.py --root . --out "%TEMP%\\sad-f1-f2-referencias-01"
PowerShell:
    py -3 .\sad_f1_f2_referencias_independentes.py --root . --out "$env:TEMP\sad-f1-f2-referencias-01"
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
from decimal import Decimal, InvalidOperation
from pathlib import Path

from audit_municipal_pb_crosswalk import COLUMNS, rows_from_csv, validate_pairs
from preflight_fato_internacao_medidas import (
    EXPECTED_BY_YEAR, EXPECTED_EXTERNAL, EXPECTED_IDENT1, EXPECTED_IDENT5,
)

PERIOD = {f"{y}{m:02d}" for y in (2017, 2018, 2019) for m in range(1, 13)}
RD_PATTERN = re.compile(r"RDPB(17|18|19)(0[1-9]|1[0-2])\.csv\Z", re.I)
LT_PATTERN = re.compile(r"LTPB(17|18|19)(0[1-9]|1[0-2])\.csv\Z", re.I)
RD_REQUIRED = ("ANO_CMPT", "MES_CMPT", "IDENT", "MUNIC_RES", "MUNIC_MOV")
LT_REQUIRED = ("CNES", "COMPETEN", "CODLEITO", "CODUFMUN", "QT_EXIST", "QT_SUS", "QT_NSUS")
RD_EXPECTED_BY_YEAR = EXPECTED_BY_YEAR
RD_EXPECTED_NEW = {"2017": 183532, "2018": 183311, "2019": 188246}
RD_EXPECTED_CONT = {"2017": 4194, "2018": 3982, "2019": 3407}


def fail(message: str) -> None:
    raise ValueError(message)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def discover(folder: Path, pattern: re.Pattern[str]) -> dict[str, Path]:
    if not folder.is_dir():
        fail(f"Pasta de origem ausente: {folder}")
    found: dict[str, Path] = {}
    for path in sorted(folder.glob("*.csv")):
        if not path.name.upper().startswith(("RDPB", "LTPB")):
            continue
        match = pattern.fullmatch(path.name)
        if match is None:
            fail(f"Nome fora do recorte 2017-2019: {path}")
        month = "20" + match.group(1) + match.group(2)
        if month in found:
            fail(f"Competência duplicada {month}: {path}")
        found[month] = path
    if set(found) != PERIOD:
        fail(f"Esperadas 36 competências em {folder}; presentes={len(found)}, "
             f"ausentes={sorted(PERIOD-set(found))}, inesperadas={sorted(set(found)-PERIOD)}")
    return found


def rows_of(path: Path, required: tuple[str, ...]):
    with path.open("r", encoding="utf-8-sig", newline="") as fh:
        reader = csv.DictReader(fh, delimiter=";")
        fields = reader.fieldnames
        if fields is None or len(set(fields)) != len(fields) or any(x not in fields for x in required):
            fail(f"Cabeçalho inválido/incompleto: {path.name}")
        for line_no, row in enumerate(reader, start=2):
            if None in row or any(row.get(field) is None for field in required):
                fail(f"CSV malformado: {path.name}:{line_no}")
            yield line_no, row


def nonnegative_integer(value: str, name: str, path: Path, line_no: int) -> int:
    try:
        n = Decimal(value.strip())
    except (InvalidOperation, ValueError):
        fail(f"{path.name}:{line_no}: {name} não numérico")
    if not n.is_finite() or n < 0 or n != int(n):
        fail(f"{path.name}:{line_no}: {name} não é inteiro não-negativo")
    return int(n)


def add_counter(target: dict[tuple, Counter], key: tuple, identity: str) -> None:
    target[key]["rd_rows"] += 1
    if identity == "1":
        target[key]["eligible_internacoes"] += 1
    else:
        target[key]["continuidades_ident5"] += 1


def reference_rd(files: dict[str, Path], municipalities: set[str]) -> dict:
    by_res = defaultdict(Counter)
    by_service = defaultdict(Counter)
    by_flow = defaultdict(Counter)
    overall = Counter()
    rows_year = Counter()
    news_year = Counter()
    conts_year = Counter()
    distinct_pb_residences = set()
    months = Counter()
    for month, path in sorted(files.items()):
        year = month[:4]
        for line, row in rows_of(path, RD_REQUIRED):
            if row["ANO_CMPT"].strip() != year or row["MES_CMPT"].strip().zfill(2) != month[-2:]:
                fail(f"Competência RD incompatível com arquivo {path.name}:{line}")
            identity = row["IDENT"].strip()
            if identity not in ("1", "5"):
                fail(f"IDENT não esperado {path.name}:{line}: {identity!r}")
            res = row["MUNIC_RES"].strip()
            serv = row["MUNIC_MOV"].strip()
            if not (len(res) == 6 and res.isdigit() and len(serv) == 6 and serv.isdigit()):
                fail(f"Código municipal RD inválido {path.name}:{line}")
            if serv not in municipalities or (res.startswith("25") and res not in municipalities):
                fail(f"Município PB ausente da referência C5.2: {path.name}:{line}")
            if res in municipalities:
                distinct_pb_residences.add(res)
            else:
                overall["external_residence_rows"] += 1
            overall["rows"] += 1
            rows_year[year] += 1
            months[month] += 1
            if identity == "1":
                overall["eligible"] += 1
                news_year[year] += 1
            else:
                overall["continuities"] += 1
                conts_year[year] += 1
            add_counter(by_res, (year, month, res), identity)
            add_counter(by_service, (year, month, serv), identity)
            add_counter(by_flow, (year, month, res, serv), identity)
    if (dict(rows_year) != RD_EXPECTED_BY_YEAR
            or dict(news_year) != RD_EXPECTED_NEW
            or dict(conts_year) != RD_EXPECTED_CONT
            or overall["rows"] != 566672 or overall["eligible"] != EXPECTED_IDENT1
            or overall["continuities"] != EXPECTED_IDENT5
            or overall["external_residence_rows"] != EXPECTED_EXTERNAL
            or distinct_pb_residences != municipalities):
        fail("SIH/RD difere do controle canônico 2017–2019; nenhuma saída produzida")
    for items in (by_res, by_service, by_flow):
        if sum(x["rd_rows"] for x in items.values()) != overall["rows"]:
            fail("Reconciliação RD: linhas não preservadas em um agrupamento")
        if sum(x["eligible_internacoes"] for x in items.values()) != overall["eligible"]:
            fail("Reconciliação RD: internações elegíveis divergentes")
    return {"by_res": by_res, "by_service": by_service, "by_flow": by_flow,
            "overall": dict(overall), "months": dict(months),
            "rows_year": dict(rows_year), "news_year": dict(news_year),
            "conts_year": dict(conts_year), "pb_res": distinct_pb_residences}


def reference_lt(files: dict[str, Path], municipalities: set[str]) -> dict:
    monthly = defaultdict(Counter)
    totals = Counter()
    year_rows = Counter()
    month_rows = Counter()
    grains: set[tuple[str, str, str]] = set()
    distinct_lt_municipalities = set()
    for month, path in sorted(files.items()):
        for line, row in rows_of(path, LT_REQUIRED):
            comp = row["COMPETEN"].strip().zfill(6)
            if comp != month:
                fail(f"LT COMPETEN diverge de arquivo {path.name}:{line}: {comp}")
            cnes = row["CNES"].strip()
            codleito = row["CODLEITO"].strip()
            mun = row["CODUFMUN"].strip()
            if not cnes or not codleito or len(mun) != 6 or not mun.isdigit():
                fail(f"Chave/grupo LT ausente ou inválido: {path.name}:{line}")
            grain = (cnes, comp, codleito)
            if grain in grains:
                fail(f"LT grão duplicado: {grain}")
            grains.add(grain)
            q_exist = nonnegative_integer(row["QT_EXIST"], "QT_EXIST", path, line)
            q_sus = nonnegative_integer(row["QT_SUS"], "QT_SUS", path, line)
            q_nsus = nonnegative_integer(row["QT_NSUS"], "QT_NSUS", path, line)
            if q_nsus != q_exist - q_sus:
                fail(f"QT_NSUS != QT_EXIST - QT_SUS: {path.name}:{line}")
            distinct_lt_municipalities.add(mun)
            k = (month[:4], month, mun)
            monthly[k]["lt_rows"] += 1
            monthly[k]["qt_sus"] += q_sus
            monthly[k]["qt_exist"] += q_exist
            monthly[k]["qt_nsus"] += q_nsus
            totals["rows"] += 1
            totals["qt_sus_snapshots_sum_audit_only"] += q_sus
            totals["qt_exist_snapshots_sum_audit_only"] += q_exist
            month_rows[month] += 1
            year_rows[month[:4]] += 1
    if len(grains) != 35518 or totals["rows"] != 35518 or len(month_rows) != 36:
        fail("LT difere do controle canônico 35.518/36/zero duplicidades")
    if sum(x["lt_rows"] for x in monthly.values()) != 35518:
        fail("Reconciliação LT municipal diverge das 35.518 linhas")
    unknown_municipalities = distinct_lt_municipalities - municipalities
    if unknown_municipalities:
        fail(f"Municípios LT fora da referência municipal PB C5.2: {sorted(unknown_municipalities)}")
    grid = []
    years = ("2017", "2018", "2019")
    for year in years:
        for mun in sorted(municipalities):
            observations = [(month, monthly.get((year, month, mun)))
                            for month in sorted(PERIOD) if month.startswith(year)]
            observed = [(month, val) for month, val in observations if val]
            k = len(observed)
            total_sus = sum(val["qt_sus"] for _month, val in observed)
            missing = [month for month, val in observations if val is None]
            grid.append({"ano": year, "municipio_servico": mun,
                         "meses_observados": k, "meses_esperados": 12,
                         "competencias_sem_linhas_lt": ",".join(missing),
                         "qt_sus_soma_snapshots_auditoria": total_sus,
                         "media_sus_numerador_exato": total_sus if k == 12 else "",
                         "media_sus_divisor_exato": 12 if k == 12 else "",
                         "cobertura_presenca_linhas": "12_OF_12_ROWS_OBSERVED_NOT_FINAL_SCOPE_VALIDATED"
                         if k == 12 else "MISSING_MONTH_ROWS_ZERO_NOT_PROVEN",
                         "universo": "LT_TODOS_REGISTROS_VALIDOS_RN21",
                         "hospitalar_historico_validado": "NAO"})
    return {"monthly": monthly, "totals": dict(totals), "year_rows": dict(year_rows),
            "month_rows": dict(month_rows), "grid": grid,
            "lt_municipalities": len(distinct_lt_municipalities)}


def rolled(entries: dict[tuple, Counter], level: str) -> dict[tuple, Counter]:
    out = defaultdict(Counter)
    for key, cnt in entries.items():
        if level == "annual":
            projected = (key[0],) + key[2:]
        else:
            projected = key
        out[projected].update(cnt)
    return out


def write_csv(path: Path, fields: list[str], rows: list[dict]) -> None:
    with path.open("x", encoding="utf-8", newline="") as stream:
        w = csv.DictWriter(stream, fieldnames=fields, delimiter=";", lineterminator="\n")
        w.writeheader()
        w.writerows(rows)


def counter_to_rows(items: dict, kind: str, annual: bool) -> tuple[list[str], list[dict]]:
    role_fields = {"res": ["municipio_residencia"],
                   "service": ["municipio_servico"],
                   "flow": ["municipio_residencia", "municipio_servico"]}[kind]
    fields = ["ano"] + ([] if annual else ["competencia"]) + role_fields + [
        "registros_rd", "internacoes_elegiveis", "continuidades_ident5"]
    result = []
    for key, v in sorted(items.items()):
        values = list(key)
        row = dict(zip(fields[:len(values)], values))
        row.update({"registros_rd": v["rd_rows"],
                    "internacoes_elegiveis": v["eligible_internacoes"],
                    "continuidades_ident5": v["continuidades_ident5"]})
        result.append(row)
    return fields, result


def write_reference(root: Path, target: Path, rd: dict, lt: dict,
                    source_sha: dict[str, dict]) -> list[str]:
    # target é staging descartável criado pelo chamador, nunca a saída pública.
    produced = []
    for key, kind, prefix in [("by_res", "res", "residencia"),
                              ("by_service", "service", "servico"),
                              ("by_flow", "flow", "fluxo")]:
        for annual in (False, True):
            data = rd[key] if not annual else rolled(rd[key], "annual")
            fields, rows = counter_to_rows(data, kind, annual)
            name = f"F1_{prefix}_{'ano' if annual else 'competencia'}.csv"
            write_csv(target / name, fields, rows)
            produced.append(name)
    lt_monthly = []
    for (year, month, mun), val in sorted(lt["monthly"].items()):
        lt_monthly.append({"ano": year, "competencia": month, "municipio_servico": mun,
                           "linhas_lt": val["lt_rows"], "qt_sus": val["qt_sus"],
                           "qt_exist": val["qt_exist"], "qt_nsus": val["qt_nsus"],
                           "estado": "LINHAS_OBSERVADAS_NUMEROS_RECONCILIADOS",
                           "universo": "LT_TODOS_REGISTROS_VALIDOS_RN21"})
    name = "F2_lt_municipio_competencia_observado.csv"
    write_csv(target / name, ["ano", "competencia", "municipio_servico",
                              "linhas_lt", "qt_sus", "qt_exist", "qt_nsus", "estado", "universo"], lt_monthly)
    produced.append(name)
    name = "F2_lt_municipio_ano_cobertura_candidata.csv"
    write_csv(target / name, list(lt["grid"][0]), lt["grid"])
    produced.append(name)
    manifest = {
        "mode": "PHYSICAL_MEASURES_F1_F2_REFERENCE_PY_READ_ORIGINAL_CSV",
        "status": "SOURCE_AGGREGATES_CREATED_PENDING_INDEPENDENT_AUDIT_AND_QV_VALIDATION",
        "script_sha256": sha256_file(Path(__file__).resolve()),
        "municipal_reference": "III-C5.2_PROJECT_DERIVED_FROM_OFFICIAL_IBGE",
        "methodology": "Monthly CNES snapshots are never summed across time as capacity; LT rows missing are not zeros; hospital status unvalidated",
        "timestamp_utc": datetime.now(timezone.utc).isoformat(),
        "rd": {"counts": rd["overall"], "year_rows": rd["rows_year"],
               "year_new": rd["news_year"], "year_cont": rd["conts_year"],
               "monthly_rows": rd["months"], "pb_distinct_residences": len(rd["pb_res"])},
        "lt": {"counts": lt["totals"], "year_rows": lt["year_rows"],
               "monthly_rows": lt["month_rows"], "distinct_service_municipalities": lt["lt_municipalities"]},
        "source_sha256": source_sha,
        "output_sha256": {name: sha256_file(target / name) for name in produced},
        "limits": ["No QlikView execution", "No factual QVD or LINK_ANALISE generated",
                   "No source file modified", "Municipal LT coverage not approved",
                   "Hospital classification not verified", "T24-T26 not approved", "T29_HISTORICAL=NOT_APPROVED"]
    }
    with (target / "manifest_F1_F2.json").open("x", encoding="utf-8") as stream:
        json.dump(manifest, stream, ensure_ascii=False, indent=2, sort_keys=True)
        stream.write("\n")
    produced.append("manifest_F1_F2.json")
    return produced


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--root", type=Path, required=True, help="Raiz do repositório com BASE/CONVERTIDA/RD e LT")
    parser.add_argument("--out", type=Path, required=True, help="Novo diretório de saída FORA do repositório; não pode existir")
    args = parser.parse_args()
    root = args.root.expanduser().resolve(strict=True)
    target = args.out.expanduser().resolve(strict=False)
    if not (root / "BASE" / "CONVERTIDA").is_dir():
        fail("Raiz não contém BASE/CONVERTIDA")
    if target.exists() or target == root or root in target.parents:
        fail("Saída não pode existir nem ficar dentro do repositório")
    print("MODE=F1_F2_INDEPENDENT_SOURCE_READ_ONLY")
    print("SOURCE_FILES_WRITTEN=0 QVD_WRITES=0 QLIKVIEW_RUN=False")
    rd_files = discover(root / "BASE" / "CONVERTIDA" / "RD", RD_PATTERN)
    lt_files = discover(root / "BASE" / "CONVERTIDA" / "LT", LT_PATTERN)
    bridge = root / "EXTRACAO" / "QVD" / "REF_MUNICIPIO_PB_DERIVADA.csv"
    municipal_rows = rows_from_csv(bridge, COLUMNS)
    validate_pairs(municipal_rows)
    municipalities = {r["COD_DATASUS_6"] for r in municipal_rows}
    print("PREFLIGHT_FILES_RD=36 LT=36 MUNICIPAL_C5_2=223")
    source_files = {"RD": rd_files, "LT": lt_files}
    before_hashes = {kind: {month: {"filename": path.name, "sha256": sha256_file(path)}
                            for month, path in sorted(files.items())}
                     for kind, files in source_files.items()}
    before_hashes["MUNICIPAL_C5_2"] = {"filename": bridge.name, "sha256": sha256_file(bridge)}
    rd = reference_rd(rd_files, municipalities)
    print(f"F1_SOURCE_PASS RD_ROWS={rd['overall']['rows']} ELIGIBLE={rd['overall']['eligible']} IDENT5={rd['overall']['continuities']}")
    lt = reference_lt(lt_files, municipalities)
    print(f"F2_SOURCE_PASS LT_ROWS={lt['totals']['rows']} LT_COMPETENCES={len(lt['month_rows'])} GRAIN_DUPLICATES=0")
    for kind, files in source_files.items():
        for month, path in files.items():
            if sha256_file(path) != before_hashes[kind][month]["sha256"]:
                fail(f"Fonte mudou durante a leitura: {kind}/{month}; nenhuma saída produzida")
    if sha256_file(bridge) != before_hashes["MUNICIPAL_C5_2"]["sha256"]:
        fail("Referência municipal C5.2 alterada durante leitura")
    print("SOURCE_SHA256_BEFORE_AFTER_UNCHANGED=True")
    # Staging na mesma unidade permite publicação por rename apenas depois do PASS.
    staging = Path(tempfile.mkdtemp(prefix=f".{target.name}-staging-", dir=target.parent))
    published = False
    try:
        produced = write_reference(root, staging, rd, lt, before_hashes)
        for kind, files in source_files.items():
            for month, path in files.items():
                if sha256_file(path) != before_hashes[kind][month]["sha256"]:
                    fail(f"Fonte alterada durante gravação: {kind}/{month}")
        if sha256_file(bridge) != before_hashes["MUNICIPAL_C5_2"]["sha256"]:
            fail("Referência municipal C5.2 alterada durante gravação")
        if target.exists():
            fail(f"Destino surgiu durante execução: {target}")
        os.rename(staging, target)
        published = True
    finally:
        if not published:
            shutil.rmtree(staging, ignore_errors=True)
    print(f"OUTPUT_DIRECTORY={target}")
    print(f"OUTPUT_FILES_COUNT={len(produced)}")
    print("VERDICT=PASS_SOURCE_REFERENCE_F1_F2_ONLY_CONTRACT_NOT_APPROVED")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, UnicodeError, csv.Error) as err:
        print(f"VERDICT=BLOCKED_SOURCE_OR_OUTPUT {type(err).__name__}: {err}", file=sys.stderr)
        raise SystemExit(1)
