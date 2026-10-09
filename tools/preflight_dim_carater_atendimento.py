#!/usr/bin/env python3
"""IV-CARATER_ATENDIMENTO: preflight somente leitura da referência SIH/SIA C1.

Revalida CSV/manifesto C1 contra os rótulos normativos já aprovados,
QVD de referência e checkpoint III-C1, e 36 CSVs SIH/RD contra CAR_INT.
Não escreve CSV, QVD, checkpoint, manifesto nem baixa dados.
O cabeçalho QVD é inspecionado; seu corpo binário não é decodificado.
"""
from __future__ import annotations

import csv
import glob
import hashlib
import json
from collections import Counter
from pathlib import Path

from materialize_normative_references import CARATER_ATENDIMENTO, PORTARIA_719
from preflight_dim_diagnostico_cid10 import qvd_header

ROOT = Path("BASE/REFERENCIAS")
REF = ROOT / "carater_atendimento.csv"
MANIFEST = ROOT / "manifesto_referencias_normativas.json"
QVD = Path("EXTRACAO/QVD/REF_CARATER_ATENDIMENTO.qvd")
RD_QVD = Path("EXTRACAO/QVD/SRC_SIH_RD.qvd")
CHECKPOINT = Path("EXTRACAO/QVD/_CHECKPOINT_EXTRACAO_REFERENCIAS_NORMATIVAS.csv")
RD_GLOB = r"BASE\CONVERTIDA\RD\RDPB*.csv"
EXPECTED_CSV_SHA = "3e40a9b2a4d0e1e65df8a9000f55af6fd24880468c12faaa24384f4722330ea8"
EXPECTED_CODES = tuple(f"{i:02d}" for i in range(1, 7))
EXPECTED_REF_FIELDS = ["codigo_fonte", "descricao", "fonte_oficial"]
EXPECTED_QVD_FIELDS = [
    "CAR_INT", "CARATER_DESCRICAO", "CARATER_FONTE_OFICIAL",
    "_META_SOURCE_FILE", "_META_SOURCE_FAMILY", "_META_SOURCE_PATH",
]
EXPECTED_CHECKPOINT = {
    "stage": "EXTRACAO_REFERENCIAS_NORMATIVAS",
    "status": "PASS_PARTIAL",
    "carater_rows": "6",
    "carater_unmatched_rd_rows": "0",
    "motivo_rows": "28",
    "motivo_unmatched_rd_rows": "0",
}
EXPECTED_MONTHS = {
    f"{year}{month:02d}" for year in range(2017, 2020)
    for month in range(1, 13)
}
DIGITS = set("0123456789")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def check_manifest() -> None:
    if not MANIFEST.is_file():
        raise RuntimeError("Manifesto normativo III-C1 ausente")
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if data.get("stage") != "PHASE_III_C1_NORMATIVE_REFERENCES" or data.get("status") != "PASS":
        raise RuntimeError("Manifesto normativo não aprovado")
    sources = data.get("sources", [])
    if not isinstance(sources, list) or not any(
        s.get("url") == PORTARIA_719 for s in sources
    ):
        raise RuntimeError("Portaria 719/2007 não reconciliada no manifesto")

    files = data.get("files", [])
    if not isinstance(files, list) or len(files) != 2:
        raise RuntimeError("Manifesto deve conter as duas referências III-C1")
    records = {r.get("name"): r for r in files}
    ref_meta = records.get("carater_atendimento.csv")
    motivo_meta = records.get("motivo_saida_permanencia.csv")
    if (
        len(records) != 2 or not ref_meta or not motivo_meta
        or ref_meta.get("rows") != 6 or motivo_meta.get("rows") != 28
        or ref_meta.get("sha256") != EXPECTED_CSV_SHA
        or sha256(REF) != EXPECTED_CSV_SHA
    ):
        raise RuntimeError("SHA ou linhas de referência CAR_INT divergentes")
    motivo_file = ROOT / "motivo_saida_permanencia.csv"
    if not motivo_file.is_file() or sha256(motivo_file) != motivo_meta.get("sha256"):
        raise RuntimeError("Integridade do manifesto normativo C1 não reconciliada")


def check_reference() -> set[str]:
    expected = dict(CARATER_ATENDIMENTO)
    if tuple(expected) != EXPECTED_CODES:
        raise RuntimeError("Domínio aprovado no materializador mudou")
    with REF.open("r", newline="", encoding="utf-8-sig") as stream:
        reader = csv.DictReader(stream, delimiter=";")
        if reader.fieldnames != EXPECTED_REF_FIELDS:
            raise RuntimeError(f"Schema da referência divergente: {reader.fieldnames}")
        rows = list(reader)
    if len(rows) != 6:
        raise RuntimeError("Referência CAR_INT não contém seis códigos")
    codes = set()
    for row in rows:
        if None in row or any(v is None for v in row.values()):
            raise RuntimeError("CSV CAR_INT malformado")
        code = row["codigo_fonte"]
        if (
            code not in expected or code in codes
            or row["descricao"] != expected[code]
            or row["fonte_oficial"] != PORTARIA_719
        ):
            raise RuntimeError(f"Domínio de caráter divergente para {code!r}")
        codes.add(code)
    if codes != set(EXPECTED_CODES):
        raise RuntimeError("Domínio CAR_INT incompleto")
    print("REFERENCE_ROWS=6")
    print("REFERENCE_DISTINCT_CODES=6")
    print("REFERENCE_CODES=01,02,03,04,05,06")
    print("REFERENCE_SHA256=" + sha256(REF))
    print("REFERENCE_LABELS=EXACT_MATCH_TO_APPROVED_NORMATIVE_MATERIALIZER")
    return codes


def check_existing_qvd() -> None:
    qvd_rows, qvd_fields = qvd_header(QVD)
    if qvd_rows != 6 or qvd_fields != EXPECTED_QVD_FIELDS:
        raise RuntimeError(f"REF_CARATER_ATENDIMENTO.qvd divergente: {qvd_rows}/{qvd_fields}")
    rd_rows, rd_fields = qvd_header(RD_QVD)
    if rd_rows != 566672 or "CAR_INT" not in rd_fields:
        raise RuntimeError(f"SRC_SIH_RD.qvd divergente: {rd_rows}/{rd_fields}")
    with CHECKPOINT.open("r", encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream, delimiter=";")
        items = list(reader)
        if len(items) != 1:
            raise RuntimeError("Checkpoint III-C1 deve ter exatamente uma linha")
        row = items[0]
        if None in row or any(v is None for v in row.values()):
            raise RuntimeError("Checkpoint III-C1 malformado")
        for field, target in EXPECTED_CHECKPOINT.items():
            if row.get(field) != target:
                raise RuntimeError(f"Checkpoint C1 divergiu em {field}: {row.get(field)!r}")
    print("REFERENCE_QVD_ROWS=6")
    print("REFERENCE_QVD_FIELDS=6")
    print("RD_QVD_ROWS=566672")
    print("CHECKPOINT_C1=PASS_PARTIAL_ZERO_UNMATCHED")


def rd_normalize(raw: str, source: Path, line: int) -> str:
    """Normaliza o texto numérico estrito após validar o valor físico.

    Equivale à saída Qlik Right('00' & KeepChar(Text(CAR_INT), digits), 2)
    para os valores verificados de um ou dois algarismos, sem caracteres
    estranhos. Não admitir que a expressão Qlik mascare entradas inválidas.
    """
    value = raw.strip(" ")
    if (
        not (1 <= len(value) <= 2)
        or any(ch not in DIGITS for ch in value)
    ):
        raise RuntimeError(f"CAR_INT bruto inesperado: {source}:{line} {raw!r}")
    return value.zfill(2)


def check_rd(codes: set[str]) -> None:
    paths = sorted(Path(s) for s in glob.glob(RD_GLOB))
    months: set[str] = set()
    raw_hist = Counter()
    norm_hist = Counter()
    by_year = Counter()
    total = 0
    for path in paths:
        name = path.stem
        if len(name) != 8 or not name.startswith("RDPB") or not name[4:].isdigit():
            raise RuntimeError(f"Arquivo RD inesperado: {path}")
        month = f"20{name[4:]}"
        if month in months or month not in EXPECTED_MONTHS:
            raise RuntimeError(f"Competência RD inesperada: {month}")
        months.add(month)
        count_this_month = 0
        with path.open("r", encoding="utf-8-sig", newline="") as stream:
            reader = csv.DictReader(stream, delimiter=";")
            if not reader.fieldnames or "CAR_INT" not in reader.fieldnames:
                raise RuntimeError(f"CAR_INT não encontrado em {path}")
            for lineno, record in enumerate(reader, 2):
                raw = record.get("CAR_INT")
                if raw is None or None in record:
                    raise RuntimeError(f"RD malformado: {path}:{lineno}")
                code = rd_normalize(raw, path, lineno)
                raw_hist[raw] += 1
                norm_hist[code] += 1
                by_year[month[:4]] += 1
                if code not in codes:
                    raise RuntimeError(f"CAR_INT sem referência: {path}:{lineno}/{code}")
                count_this_month += 1
                total += 1
        if count_this_month == 0:
            raise RuntimeError(f"RD vazio: {month}")
    if months != EXPECTED_MONTHS or total != 566672:
        raise RuntimeError(f"RD 36 competências/566672 esperado: {len(months)} / {total}")
    if not set(norm_hist).issubset(codes):
        raise RuntimeError("RD normalizado fora do domínio normativo")
    print("RD_FILES=36")
    print("RD_MONTHS=36")
    print("RD_ROWS=566672")
    print("RD_RAW_DISTINCT=" + str(len(raw_hist)))
    print("RD_NORMALIZED_DISTINCT=" + str(len(norm_hist)))
    print("RD_RAW_VALUES=" + repr(sorted(raw_hist.items())))
    print("RD_NORMALIZED_COUNTS=" + repr(sorted(norm_hist.items())))
    print("RD_YEAR_COUNTS=" + repr(sorted(by_year.items())))
    print("RD_UNMATCHED=0")


def main() -> int:
    print("MODE=IV_DIM_CARATER_READ_ONLY_PREFLIGHT")
    print("OUTPUT_FILES_WRITTEN=0")
    print("QVD_GENERATED=False")
    check_manifest()
    codes = check_reference()
    check_existing_qvd()
    check_rd(codes)
    print("SK_RULE_CANDIDATE=Hash128_CAR_AND_NORMALIZED_CODE")
    print("SOURCE_DOMAIN_POLICY=FULL_OFFICIAL_01_TO_06")
    print("VERDICT=PASS_CARATER_6_CODE_REFERENCE_AND_RD_PREFLIGHT_ONLY")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
