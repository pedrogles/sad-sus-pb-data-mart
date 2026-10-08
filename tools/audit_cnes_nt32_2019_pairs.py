#!/usr/bin/env python3
"""III-C4.2c.2e: confronta LT/PB com transcricao da Nota Tecnica MS 32/2019.

Somente leitura de PDF, perfil LT e referencia textual versionada.
A tabela do anexo refere-se a SETEMBRO/2019. Mesmo cobertura total NAO
demonstra vigencia normativa para todas as competencias de 2017-2019.
Nao altera LT, modelo, Qlik ou QVD. Requer apenas biblioteca padrao.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

PDF_SHA = "43de32e91b9ed2611bacde8f4cea60576cb162017fa4db69797dd177c4f7632e"
REF_SHA = "c44d1075ed4b628106587f11cb38eab794d3573986e2079844738ad8c4b3f2c6"
PROFILE_SHA = "4afe0741b1bf43434192e467a043a0bcb7f2a96e25214f92f47557531e238449"
GROUP_LABELS = {
    "1": "Cirúrgico", "2": "Clinico", "3": "Complementar",
    "4": "Obstétrico", "5": "Pediátrico", "6": "Outras Especialidades",
    "7": "Hospital-Dia",
}
EXPECTED_GROUP_SIZES = {"1": 17, "2": 15, "3": 18, "4": 2, "5": 2, "6": 5, "7": 6}


def verified_bytes(path: Path, expected_hash: str) -> bytes:
    if not path.is_file():
        raise RuntimeError(f"Arquivo de entrada ausente: {path}")
    data = path.read_bytes()
    actual = hashlib.sha256(data).hexdigest()
    if actual != expected_hash:
        raise RuntimeError(
            f"SHA-256 divergente: {path}; esperado={expected_hash}; obtido={actual}"
        )
    return data


def read_csv(data: bytes, columns: set[str]) -> list[dict[str, str]]:
    from io import StringIO
    reader = csv.DictReader(StringIO(data.decode("utf-8-sig"), newline=""), delimiter=";")
    if not reader.fieldnames or set(reader.fieldnames) != columns:
        raise RuntimeError(f"Cabecalho CSV inesperado: {reader.fieldnames}")
    result = list(reader)
    if any(None in row for row in result):
        raise RuntimeError("CSV possui colunas extras inesperadas")
    return result


def run(pdf: Path, reference: Path, profile: Path, output: Path) -> int:
    verified_bytes(pdf, PDF_SHA)  # confere bytes originais; nao interpreta PDF na auditoria
    reference_rows = read_csv(
        verified_bytes(reference, REF_SHA),
        {"codleito", "tp_leito", "nome_cnes", "tipo_cnes", "status", "pdf_page"},
    )
    profile_rows = read_csv(
        verified_bytes(profile, PROFILE_SHA),
        {
            "tp_leito_raw", "codleito_raw", "occurrences", "first_competence",
            "last_competence", "competences_observed", "tp_leito_length",
            "codleito_length", "tp_leito_shape", "codleito_shape",
        },
    )
    index: dict[tuple[str, str], dict] = {}
    code_set: set[str] = set()
    counter: Counter[str] = Counter()
    for r in reference_rows:
        code, kind = r["codleito"], r["tp_leito"]
        key = (kind, code)
        if (
            not re.fullmatch(r"[0-9]{2}", code)
            or kind not in GROUP_LABELS
            or r["tipo_cnes"] != GROUP_LABELS[kind]
            or r["status"] != "Ativo"
            or not r["nome_cnes"]
            or r["pdf_page"] not in ("2", "3", "4", "5", "6", "7")
            or code in code_set or key in index
        ):
            raise RuntimeError(f"Referencia derivada inconsistente: {r}")
        code_set.add(code)
        counter[kind] += 1
        index[key] = r
    if len(index) != 65 or dict(counter) != EXPECTED_GROUP_SIZES:
        raise RuntimeError(f"Distribuicao inesperada da Nota Tecnica: {dict(counter)}")
    if (
        index[("3", "66")]["nome_cnes"] != "UNIDADE ISOLAMENTO"
        or index[("7", "70")]["nome_cnes"] != "FIBROSE CISTICA"
    ):
        raise RuntimeError("Associacoes de controle 66/70 nao conferem")

    observed: dict[tuple[str, str], int] = {}
    for r in profile_rows:
        raw, code = r["tp_leito_raw"], r["codleito_raw"]
        if not re.fullmatch(r"[1-7] ", raw) or not re.fullmatch(r"[0-9]{2}", code):
            raise RuntimeError(f"Codigo bruto LT fora do formato validado: {r}")
        key = (raw[0], code)
        if key in observed:
            raise RuntimeError(f"Par LT repetido no perfil: {key}")
        observed[key] = int(r["occurrences"])
    if len(observed) != 57 or sum(observed.values()) != 35518:
        raise RuntimeError("Quantitativos do perfil LT nao conferem com C4.1")

    missing = []
    matched_rows = 0
    for (kind, code), occurrences in sorted(observed.items()):
        if (kind, code) in index:
            matched_rows += occurrences
            continue
        alternative_types = sorted(k for k, c in index if c == code)
        missing.append({
            "tp_leito": kind, "codleito": code, "occurrences": occurrences,
            "note_types_for_same_code": alternative_types,
        })
    good = not missing
    status = "PASS_201909_SNAPSHOT_PAIR_COVERAGE_ONLY" if good else "REVIEW_REQUIRED"
    report = {
        "checkpoint": "III-C4.2c.2e",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "status": status,
        "official_document": "Nota Tecnica 32/2019-CGSI/DRAC/SAES/MS, Anexo Setembro/2019",
        "pdf_sha256": PDF_SHA,
        "reference_path": str(reference),
        "derived_transcription_sha256": REF_SHA,
        "profile_sha256": PROFILE_SHA,
        "snapshot_reference_pairs": len(index),
        "snapshot_reference_distinct_codes": len(code_set),
        "snapshot_reference_types": dict(sorted(counter.items())),
        "pb_observed_pairs": len(observed),
        "pb_matched_pairs": len(observed) - len(missing),
        "pb_observed_lt_rows": sum(observed.values()),
        "pb_matched_lt_rows": matched_rows,
        "pb_unmatched_lt_rows": sum(observed.values()) - matched_rows,
        "unmatched_pairs": missing,
        "limits": {
            "this_is_a_transcription_not_original_normative_dataset": True,
            "reference_is_snapshot_201909": True,
            "complete_validity_across_201701_201912_verified": False,
            "t29_full_approved": False,
            "new_qvd_created": False,
            "source_files_modified": False,
        },
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("PDF_INTEGRITY=PASS")
    print("TRANSCRIPTION_INTEGRITY=PASS")
    print("PROFILE_INTEGRITY=PASS")
    print(f"NOTE_SNAPSHOT_PAIRS={len(index)}")
    print(f"PB_MATCHED_PAIRS={len(observed)-len(missing)}/{len(observed)}")
    print(f"PB_MATCHED_ROWS={matched_rows}/{sum(observed.values())}")
    print(f"UNMATCHED_PAIRS={len(missing)}")
    print(f"AUDIT_REPORT={output}")
    print(f"VERDICT={status}")
    print("T29_FULL=NOT_APPROVED")
    return 0 if good else 2


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pdf", type=Path, default=Path("BASE/REFERENCIAS/Nota Técnica  32-2019 Leitos.pdf"))
    parser.add_argument("--referencia", type=Path, default=Path("docs/discovery/cnes-nt32-2019-codigos-leito.csv"))
    parser.add_argument("--perfil", type=Path, default=Path("BASE/REFERENCIAS/cnes_lt_bed_code_pair_profile.csv"))
    parser.add_argument("--saida", type=Path, default=Path("BASE/REFERENCIAS/cnes_nt32_201909_pair_audit.json"))
    args = parser.parse_args()
    try:
        return run(args.pdf, args.referencia, args.perfil, args.saida)
    except (RuntimeError, ValueError, OSError, UnicodeError) as exc:
        print(f"AUDIT_INPUT_ERROR={exc}")
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
