#!/usr/bin/env python3
"""A0 P1.2/P2.2/P3.1: independent E1/E4 oracle. No Qlik or QVD access.

Only existing AE01 CSVs are read. A new JSON file is written exclusively
when invoked by a separately authorized future gate. Not an execution permit.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

E1_SHA = "F14BC0C5C2A35F584EF15117C88D97B9A54C9CFFCFE0DB0E7194DDA5A391B615"
E4_SHA = "BE07644115D16F10A6E6084991CB42C01C4FD5F12C2A831AC36B843CE445BB88"
E1_FIELDS = ("competencia", "ano", "municipio_res", "municipio_serv",
             "qtd_registro_aih", "qtd_internacao", "qtd_continuidade")
E4_FIELDS = ("competencia", "municipio_serv", "cnes", "tp_leito", "codleito",
             "linhas_lt", "qt_exist", "qt_sus", "qt_nsus")
MONTHS = tuple(f"{y}{m:02d}" for y in (2017, 2018, 2019) for m in range(1, 13))
YEAR_NEW = {"2017": 183532, "2018": 183311, "2019": 188246}
PAIRS = (("250180", "250750", 3806), ("250750", "250750", 39060))


def require(test: bool, message: str) -> None:
    if not test:
        raise ValueError(message)


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest().upper()


def uint(value: str, label: str) -> int:
    require(bool(re.fullmatch(r"0|[1-9][0-9]*", value)), f"{label}: inteiro invalido")
    return int(value)


def read_rows(path: Path, fields: tuple[str, ...]):
    require(path.is_file() and path.stat().st_size > 0, f"Arquivo ausente/vazio: {path}")
    with path.open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream, delimiter=";")
        require(tuple(reader.fieldnames or ()) == fields, f"Cabecalho incorreto: {path.name}")
        for n, row in enumerate(reader, 2):
            require(None not in row and all(v is not None for v in row.values()),
                    f"Linha invalida: {path.name}:{n}")
            yield n, row


def validate_month(value: str) -> bool:
    return value in MONTHS


def build(e1_path: Path, e4_path: Path) -> dict:
    require(sha256(e1_path) == E1_SHA, "E1 SHA-256 difere do AE01 auditado")
    require(sha256(e4_path) == E4_SHA, "E4 SHA-256 difere do AE01 auditado")
    monthly_new = Counter()
    annual_new = Counter()
    pair_new = Counter()
    total_e1 = Counter()
    seen_e1 = set()
    for n, r in read_rows(e1_path, E1_FIELDS):
        m, y = r["competencia"], r["ano"]
        res, serv = r["municipio_res"], r["municipio_serv"]
        require(validate_month(m) and y == m[:4], f"E1 competencia/ano: {n}")
        require(bool(re.fullmatch(r"[0-9]{6}", res)) and
                bool(re.fullmatch(r"25[0-9]{4}", serv)), f"E1 RES/SERV: {n}")
        key = (m, res, serv)
        require(key not in seen_e1, f"E1 duplicado: {n}")
        seen_e1.add(key)
        count = uint(r["qtd_registro_aih"], "RD rows")
        new = uint(r["qtd_internacao"], "RD new")
        continued = uint(r["qtd_continuidade"], "RD continued")
        require(count > 0 and new + continued == count, f"E1 decomposicao: {n}")
        monthly_new[m] += new
        annual_new[y] += new
        if y == "2018":
            pair_new[(res, serv)] += new
        total_e1.update({"rd": count, "new": new, "continued": continued})
    require(len(seen_e1) == 30255, "E1 grupos esperados: 30255")
    require(set(monthly_new) == set(MONTHS), "E1 36 competencias ausentes")
    require(dict(annual_new) == YEAR_NEW, "E1 controle anual divergente")
    require(tuple(total_e1[x] for x in ("rd", "new", "continued"))
            == (566672, 555089, 11583), "E1 controle global divergente")
    for res, serv, expected in PAIRS:
        require(pair_new[(res, serv)] == expected, f"E1 par 2018 diverge: {res}/{serv}")

    lt_month = defaultdict(Counter)
    lt_total = Counter()
    seen_e4 = set()
    for n, r in read_rows(e4_path, E4_FIELDS):
        m, serv = r["competencia"], r["municipio_serv"]
        require(validate_month(m), f"E4 competencia: {n}")
        require(bool(re.fullmatch(r"25[0-9]{4}", serv)), f"E4 SERV: {n}")
        key = (m, serv, r["cnes"], r["tp_leito"], r["codleito"])
        require(key not in seen_e4, f"E4 duplicado: {n}")
        seen_e4.add(key)
        require(bool(r["cnes"]) and
                bool(re.fullmatch(r"[1-7]", r["tp_leito"])) and
                bool(re.fullmatch(r"[0-9]{2}", r["codleito"])),
                f"E4 codigo: {n}")
        count, exist, sus, nsus = (uint(r[x], f"E4 {x}:{n}") for x in
                                   ("linhas_lt", "qt_exist", "qt_sus", "qt_nsus"))
        require(count > 0 and exist == sus + nsus, f"E4 consistencia: {n}")
        lt_month[m].update({"exist": exist, "sus": sus, "nsus": nsus})
        lt_total.update({"rows": count, "exist": exist, "sus": sus, "nsus": nsus})
    require(len(seen_e4) == 35518, "E4 grupos esperados: 35518")
    require(set(lt_month) == set(MONTHS), "E4 36 competencias ausentes")
    require(tuple(lt_total[k] for k in ("rows", "exist", "sus", "nsus"))
            == (35518, 337147, 270076, 67071), "E4 controle global divergente")

    return {
        "gate": "SAD-A0-CONSUMPTION-VALIDATION-01",
        "status": "ORACLE_READY_NOT_QLIK_PASS",
        "source_sha256": {"E1": E1_SHA, "E4": E4_SHA},
        "p1_2": {m: monthly_new[m] for m in MONTHS},
        "p2_2": {m: dict(lt_month[m]) for m in MONTHS},
        "p3_1": [{"ano": "2018", "res": res, "serv": serv,
                   "qtd_internacao": expected} for res, serv, expected in PAIRS],
        "scope": {"p1_2_months": 36, "p2_2_months": 36,
                  "p3_1_pairs_tested": 2, "p3_1_complete_matrix": False,
                  "g1_issue_157": "OPEN_UNRESOLVED",
                  "phase_ix": "NOT_AUTHORIZED"},
    }


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--ae01-dir", type=Path, required=True)
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    e1 = args.ae01_dir / "sih_fluxo_competencia.csv"
    e4 = args.ae01_dir / "lt_cnes_leito_competencia.csv"
    data = build(e1, e4)
    require(args.output.parent.is_dir(), "Diretorio de saida deve existir")
    # Fail-closed, exclusive create: never overwrite an existing evidence record.
    with args.output.open("x", encoding="utf-8") as stream:
        json.dump(data, stream, indent=2, ensure_ascii=False, sort_keys=True)
        stream.write("\n")
    print("VERDICT=ORACLE_READY_NOT_QLIK_PASS")
    print(f"ORACLE_PATH={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
