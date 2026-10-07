#!/usr/bin/env python3
"""Materializa referências normativas pequenas usadas no staging da Fase III.

Fontes oficiais:
- Portaria SAS/MS nº 719/2007:
  https://bvsms.saude.gov.br/bvs/saudelegis/sas/2007/prt0719_28_12_2007.html
- Portaria SAS/MS nº 384/2010:
  https://bvsms.saude.gov.br/bvs/sas/Links%20finalizados%20SAS%202010/prt0384_12_08_2010.html

O script não baixa bases externas. Ele materializa somente os domínios
normativos já fechados no Boundary 4 e grava manifesto com SHA-256.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

PORTARIA_719 = (
    "https://bvsms.saude.gov.br/bvs/saudelegis/sas/2007/"
    "prt0719_28_12_2007.html"
)
PORTARIA_384 = (
    "https://bvsms.saude.gov.br/bvs/sas/Links%20finalizados%20SAS%202010/"
    "prt0384_12_08_2010.html"
)

CARATER_ATENDIMENTO = [
    ("01", "Eletivo"),
    ("02", "Urgência"),
    ("03", "Acidente no local de trabalho ou a serviço da empresa"),
    ("04", "Acidente no trajeto para o trabalho"),
    ("05", "Outros tipos de Acidente de Trânsito"),
    ("06", "Outros tipos de Lesões e Envenenamentos por agentes químicos ou físicos"),
]

MOTIVO_SAIDA_PERMANENCIA = [
    ("11", "1.1", "Alta Curado", "POR ALTA"),
    ("12", "1.2", "Alta Melhorado", "POR ALTA"),
    ("13", "1.3", "Alta da Puérpera e permanência do recém-nascido", "POR ALTA"),
    ("14", "1.4", "Alta a pedido", "POR ALTA"),
    ("15", "1.5", "Alta com previsão de retorno para acompanhamento do paciente", "POR ALTA"),
    ("16", "1.6", "Alta por Evasão", "POR ALTA"),
    ("17", "1.7", "Alta da Puérpera e recém-nascido", "POR ALTA"),
    ("18", "1.8", "Alta por Outros motivos", "POR ALTA"),
    ("21", "2.1", "Por características próprias da doença", "POR PERMANÊNCIA"),
    ("22", "2.2", "Por Intercorrência", "POR PERMANÊNCIA"),
    ("23", "2.3", "Por impossibilidade sócio-familiar", "POR PERMANÊNCIA"),
    ("24", "2.4", "Por Processo de doação de órgãos, tecidos e células - doador vivo", "POR PERMANÊNCIA"),
    ("25", "2.5", "Por Processo de doação de órgãos, tecidos e células - doador morto", "POR PERMANÊNCIA"),
    ("26", "2.6", "Por mudança de Procedimento", "POR PERMANÊNCIA"),
    ("27", "2.7", "Por reoperação", "POR PERMANÊNCIA"),
    ("28", "2.8", "Outros motivos", "POR PERMANÊNCIA"),
    ("31", "3.1", "Transferido para outro estabelecimento", "POR TRANSFERÊNCIA"),
    ("41", "4.1", "Com declaração de óbito fornecida pelo médico assistente", "POR ÓBITO"),
    ("42", "4.2", "Com declaração de óbito fornecida pelo Instituto Médico Legal - IML", "POR ÓBITO"),
    ("43", "4.3", "Com declaração de óbito fornecida pelo Serviço de Verificação de Óbito - SVO.", "POR ÓBITO"),
    ("51", "5.1", "ENCERRAMENTO ADMINISTRATIVO", "POR OUTROS MOTIVOS"),
]


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_csv(path: Path, fieldnames: list[str], rows: list[dict[str, str]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames, delimiter=";")
        writer.writeheader()
        writer.writerows(rows)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--output-dir",
        default="BASE/REFERENCIAS",
        help="Diretório local de saída (default: BASE/REFERENCIAS)",
    )
    args = parser.parse_args()

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    if len(CARATER_ATENDIMENTO) != 6:
        raise RuntimeError("Domínio CAR_INT deve conter exatamente 6 códigos.")
    if len({codigo for codigo, _ in CARATER_ATENDIMENTO}) != 6:
        raise RuntimeError("Domínio CAR_INT contém códigos duplicados.")

    if len(MOTIVO_SAIDA_PERMANENCIA) != 21:
        raise RuntimeError("Domínio de motivo de saída/permanência deve conter 21 códigos.")
    if len({codigo for codigo, *_ in MOTIVO_SAIDA_PERMANENCIA}) != 21:
        raise RuntimeError("Domínio de motivo de saída/permanência contém códigos duplicados.")

    carater_path = output_dir / "carater_atendimento.csv"
    motivo_path = output_dir / "motivo_saida_permanencia.csv"
    manifest_path = output_dir / "manifesto_referencias_normativas.json"

    write_csv(
        carater_path,
        ["codigo_fonte", "descricao", "fonte_oficial"],
        [
            {
                "codigo_fonte": codigo,
                "descricao": descricao,
                "fonte_oficial": PORTARIA_719,
            }
            for codigo, descricao in CARATER_ATENDIMENTO
        ],
    )

    write_csv(
        motivo_path,
        [
            "codigo_fonte",
            "codigo_normativo",
            "descricao",
            "grupo",
            "fonte_oficial_719",
            "fonte_oficial_384",
        ],
        [
            {
                "codigo_fonte": codigo_fonte,
                "codigo_normativo": codigo_normativo,
                "descricao": descricao,
                "grupo": grupo,
                "fonte_oficial_719": PORTARIA_719,
                "fonte_oficial_384": PORTARIA_384,
            }
            for codigo_fonte, codigo_normativo, descricao, grupo
            in MOTIVO_SAIDA_PERMANENCIA
        ],
    )

    manifest = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "stage": "PHASE_III_C1_NORMATIVE_REFERENCES",
        "status": "PASS",
        "sources": [
            {"name": "Portaria SAS/MS nº 719/2007", "url": PORTARIA_719},
            {"name": "Portaria SAS/MS nº 384/2010", "url": PORTARIA_384},
        ],
        "files": [
            {
                "name": carater_path.name,
                "rows": 6,
                "sha256": sha256_file(carater_path),
            },
            {
                "name": motivo_path.name,
                "rows": 21,
                "sha256": sha256_file(motivo_path),
            },
        ],
    }

    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"CARATER_FILE={carater_path}")
    print("CARATER_ROWS=6")
    print(f"MOTIVO_FILE={motivo_path}")
    print("MOTIVO_ROWS=21")
    print(f"MANIFEST={manifest_path}")
    print("VERDICT=PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
