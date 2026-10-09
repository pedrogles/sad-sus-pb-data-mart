#!/usr/bin/env python3
"""IV-DIAGNOSTICO: preflight READ-ONLY da referência CID-10 e DIAG_PRINC.

Valida arquivos originais SIGTAP 201912, CSV derivado C2.7, QVDs QlikView
por cabecalho XML, checkpoint C2.8d e os 36 CSVs RD locais. Prova a
cobertura apenas para lookup descritivo estatico (NÃO vigencia mensal).
Nenhum arquivo, QVD, manifesto, staging ou checkpoint eh criado/modificado.
"""
from __future__ import annotations

import csv
import glob
import hashlib
import json
import xml.etree.ElementTree as ET
from collections import Counter
from itertools import zip_longest
from pathlib import Path

ROOT = Path("BASE/REFERENCIAS")
CSV = ROOT / "cid10_referencia.csv"
MANIFEST = ROOT / "cid10_referencia_manifest.json"
SAMPLE_MANIFEST = ROOT / "cid10_sigtap_sample_manifest.json"
RAW = ROOT / "SIGTAP/CID10/201912/tb_cid.txt"
LAYOUT = ROOT / "SIGTAP/CID10/201912/tb_cid_layout.txt"
QVD = Path("EXTRACAO/QVD/REF_CID10.qvd")
RD_QVD = Path("EXTRACAO/QVD/SRC_SIH_RD.qvd")
CHECKPOINT = Path("EXTRACAO/QVD/_CHECKPOINT_EXTRACAO_CID10.csv")
RD_FILES = r"BASE\CONVERTIDA\RD\RDPB*.csv"
EXPECTED_REF_SHA = "da541adc1efbdb4ac04c555cf1e008967fd053fb6368ff443fb10a476757025f"
EXPECTED_CSV_FIELDS = [
    "codigo_cid10", "descricao", "competencia_referencia", "fonte_arquivo",
]
EXPECTED_QVD_FIELDS = [
    "CID10_CODIGO", "CID10_DESCRICAO", "CID10_COMPETENCIA_REFERENCIA",
    "CID10_FONTE_ARQUIVO", "_META_SOURCE_FILE", "_META_SOURCE_FAMILY",
    "_META_SOURCE_PATH",
]
CHECKPOINT_FIELDS = {
    "stage": "EXTRACAO_CID10",
    "status": "PASS_PARTIAL",
    "cid10_rows": "14230",
    "cid10_distinct_codes": "14230",
    "cid10_length_3": "2042",
    "cid10_length_4": "12188",
    "rd_rows": "566672",
    "cid10_unmatched_rd_rows": "0",
}
EXPECTED_MONTHS = {
    f"{year}{month:02d}" for year in range(2017, 2020)
    for month in range(1, 13)
}


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def json_doc(path: Path) -> dict:
    if not path.is_file():
        raise RuntimeError(f"Manifesto ausente: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def qvd_header(path: Path) -> tuple[int, list[str]]:
    # Apenas cabecalho XML: corpo QVD binario nao eh decodificado.
    with path.open("rb") as f:
        buffer = bytearray()
        ending = b"</QvdTableHeader>"
        while ending not in buffer:
            data = f.read(65536)
            if not data:
                raise RuntimeError(f"Cabecalho QVD ausente: {path}")
            buffer.extend(data)
            if len(buffer) > 2 * 1024 * 1024:
                raise RuntimeError(f"Cabecalho QVD excedeu limite: {path}")
    root = ET.fromstring(buffer[:buffer.index(ending) + len(ending)])
    def nodes(name: str) -> list[str]:
        return [
            element.text or "" for element in root.iter()
            if element.tag.rsplit("}", 1)[-1] == name
        ]
    counts = nodes("NoOfRecords")
    if len(counts) != 1 or not counts[0].isdigit():
        raise RuntimeError(f"Contagem QVD inesperada: {path}/{counts}")
    return int(counts[0]), nodes("FieldName")


def source_manifest_gate() -> dict:
    manifest = json_doc(MANIFEST)
    sample = json_doc(SAMPLE_MANIFEST)
    if (
        manifest.get("stage") != "PHASE_III_C2_CID10_FINAL_MATERIALIZATION"
        or manifest.get("status") != "PASS"
        or manifest.get("decision", {}).get("type") != "STATIC_DESCRIPTIVE_SUPERSET"
        or manifest.get("decision", {}).get("reference_competence") != "201912"
        or manifest.get("output", {}).get("rows") != 14230
        or manifest.get("output", {}).get("distinct_codes") != 14230
        or manifest.get("output", {}).get("normalized_code_length_counts")
            != {"3": 2042, "4": 12188}
        or manifest.get("output", {}).get("sha256") != EXPECTED_REF_SHA
        or sample.get("status") != "PASS"
    ):
        raise RuntimeError("Manifesto C2.7 ou C2.4 mudou ou nao tem PASS")
    if sha256(CSV) != EXPECTED_REF_SHA:
        raise RuntimeError("CSV CID-10 nao confere com SHA C2.7")
    s = manifest.get("source", {})
    if (
        s.get("competence") != "201912"
        or s.get("encoding") != "cp1252"
        or s.get("line_length") != 111
        or s.get("code_field", {}).get("name") != "CO_CID"
        or s.get("description_field", {}).get("name") != "NO_CID"
        or sha256(RAW) != s.get("tb_cid_sha256")
        or sha256(LAYOUT) != s.get("tb_cid_layout_sha256")
    ):
        raise RuntimeError("Arquivo original CID-10 ou layout nao confere com manifesto")
    materialized = {
        row["competence"]: row for row in sample.get("materialized", [])
    }
    if "201912" not in materialized:
        raise RuntimeError("Amostra oficial de 201912 nao esta documentada")
    if (
        materialized["201912"]["tb_cid"]["sha256"] != sha256(RAW)
        or materialized["201912"]["tb_cid_layout"]["sha256"] != sha256(LAYOUT)
    ):
        raise RuntimeError("Integridade C2.4 e C2.7 divergente")
    return manifest


def reference_gate() -> set[str]:
    codes: set[str] = set()
    sizes = Counter()
    with CSV.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f, delimiter=";")
        if reader.fieldnames != EXPECTED_CSV_FIELDS:
            raise RuntimeError(f"Schema CSV divergente: {reader.fieldnames}")
        with RAW.open("r", encoding="cp1252", newline="") as raw:
            for line_no, (row, rawline) in enumerate(zip_longest(reader, raw), 2):
                if row is None or rawline is None:
                    raise RuntimeError("CSV e origem fisica com contagens diferentes")
                if None in row or any(value is None for value in row.values()):
                    raise RuntimeError(f"CSV malformado na linha {line_no}")
                source = rawline.rstrip("\r\n")
                if len(source) != 111:
                    raise RuntimeError(f"Largura CID-10 invalida na linha {line_no}")
                code = source[:4].rstrip(" ")
                description = source[4:104].rstrip(" ")
                if (
                    row["codigo_cid10"] != code
                    or row["descricao"] != description
                    or row["competencia_referencia"] != "201912"
                    or row["fonte_arquivo"] != "tb_cid.txt"
                    or len(code) not in (3, 4)
                    or not code.isalnum() or code.upper() != code
                    or not description
                    or code in codes
                ):
                    raise RuntimeError(f"Dado CID-10 nao reconciliado na linha {line_no}")
                codes.add(code)
                sizes[len(code)] += 1
    if len(codes) != 14230 or sizes != {3: 2042, 4: 12188}:
        raise RuntimeError(f"Cobertura codigos CID ou distribuicao alterada: {sizes}")
    print("CID_REFERENCE_ROWS=14230")
    print("CID_DISTINCT_CODES=14230")
    print("CID_CODE_LENGTH_3=2042")
    print("CID_CODE_LENGTH_4=12188")
    print("CID_SOURCE_CSV_SHA256=" + sha256(CSV))
    return codes


def qvd_gate() -> None:
    count, fields = qvd_header(QVD)
    if count != 14230 or fields != EXPECTED_QVD_FIELDS:
        raise RuntimeError(f"REF_CID10.qvd divergente: {count}/{fields}")
    rd_count, rd_fields = qvd_header(RD_QVD)
    if rd_count != 566672 or "DIAG_PRINC" not in rd_fields:
        raise RuntimeError(f"SRC_SIH_RD.qvd divergente: {rd_count}")
    with CHECKPOINT.open("r", encoding="utf-8-sig", newline="") as f:
        reader = csv.DictReader(f, delimiter=";")
        rows = list(reader)
        if len(rows) != 1:
            raise RuntimeError("Checkpoint CID-10 exige exatamente uma linha")
        for field, expected in CHECKPOINT_FIELDS.items():
            if rows[0].get(field) != expected:
                raise RuntimeError(f"Checkpoint CID-10 diverge em {field}")
    print("REF_CID10_QVD_ROWS=14230")
    print("REF_CID10_QVD_FIELDS=7")
    print("SRC_SIH_RD_QVD_ROWS=566672")
    print("CHECKPOINT_C2_8D=PASS_PARTIAL_0_UNMATCHED")


def rd_gate(codes: set[str]) -> None:
    paths = sorted(Path(p) for p in glob.glob(RD_FILES))
    months = set()
    rows = 0
    matched = 0
    unmatched = Counter()
    raw_codes = set()
    normalized = set()
    padded_rows = 0
    for path in paths:
        stem = path.stem
        if (
            len(stem) != 8 or not stem.startswith("RDPB")
            or not stem[4:].isdigit()
        ):
            raise RuntimeError(f"RD com nome inesperado: {path}")
        month = "20" + stem[4:]
        if month not in EXPECTED_MONTHS or month in months:
            raise RuntimeError(f"Competencia RD inesperada/duplicada: {month}")
        months.add(month)
        monthly_rows = 0
        with path.open("r", encoding="utf-8", newline="") as f:
            reader = csv.DictReader(f, delimiter=";")
            if reader.fieldnames is None or "DIAG_PRINC" not in reader.fieldnames:
                raise RuntimeError(f"DIAG_PRINC ausente: {path}")
            for row in reader:
                raw = row["DIAG_PRINC"]
                if raw is None or len(raw) != 4 or raw != raw.lstrip(" "):
                    raise RuntimeError(f"DIAG_PRINC estruturalmente invalido: {path}")
                if " " in raw[:-1]:
                    raise RuntimeError(f"Whitespace nao trailing no CID: {path}")
                code = raw.rstrip(" ")
                if len(code) not in (3, 4) or not code.isalnum() or code.upper() != code:
                    raise RuntimeError(f"Chave CID RD nao admissivel: {path}/{raw!r}")
                if raw.endswith(" "):
                    padded_rows += 1
                rows += 1
                monthly_rows += 1
                raw_codes.add(raw)
                normalized.add(code)
                if code in codes:
                    matched += 1
                else:
                    unmatched[code] += 1
        if not monthly_rows:
            raise RuntimeError(f"RD sem linhas: {month}")
    if months != EXPECTED_MONTHS:
        raise RuntimeError(f"Competencias RD incompletas: {sorted(months)}")
    if (rows != 566672 or matched != rows or unmatched
        or len(raw_codes) != 5480 or len(normalized) != 5480
        or padded_rows != 60423):
        raise RuntimeError(
            f"Cobertura CID RD divergente: RD={rows}, MATCH={matched}, "
            f"NOT_FOUND={dict(unmatched.most_common(5))}, "
            f"RAW_CODES={len(raw_codes)}, NORM_CODES={len(normalized)}, "
            f"PADDED={padded_rows}"
        )
    print("RD_FILES=36")
    print("RD_ROWS=566672")
    print("RD_RAW_DISTINCT=5480")
    print("RD_NORM_DISTINCT=5480")
    print("TRAILING_SPACE_ROWS=60423")
    print("RD_MATCHED=566672")
    print("RD_UNMATCHED=0")


def main() -> int:
    print("MODE=IV_DIM_DIAGNOSTICO_CID10_READ_ONLY_PREFLIGHT")
    print("PERSISTENT_OUTPUTS=NONE")
    print("QVD_CREATED=False")
    print("T28=PREVIOUS_QV_PASS_TO_BE_RECONCILED")
    source_manifest_gate()
    codes = reference_gate()
    qvd_gate()
    rd_gate(codes)
    print("REFERENCE_POLICY=STATIC_DESCRIPTIVE_SUPERSET_201912_NO_MONTHLY_VALIDITY")
    print("NORMALIZATION=ASCII_TRAILING_SPACE_REMOVAL_ONLY")
    print("SK_RULE_CANDIDATE=Hash128_CID10_NORMALIZED_CODE")
    print("VERDICT=PASS_CID10_DIM_DIAGNOSTICO_PHYSICAL_PREFLIGHT_ONLY")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
