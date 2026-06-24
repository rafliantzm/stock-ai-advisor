from __future__ import annotations

import csv
import hashlib
import json
import re
import shutil
from collections import Counter
from dataclasses import dataclass
from datetime import datetime
from difflib import SequenceMatcher
from pathlib import Path
from typing import Iterable


PROJECT_ROOT = Path(__file__).resolve().parents[2]
BOOKS_DIR = PROJECT_ROOT / "data" / "books"
CATALOG_DIR = PROJECT_ROOT / "data" / "catalog"
CSV_OUTPUT = CATALOG_DIR / "books_catalog.csv"
JSON_OUTPUT = CATALOG_DIR / "books_catalog.json"
CSV_BACKUP = CATALOG_DIR / "books_catalog.backup.csv"
JSON_BACKUP = CATALOG_DIR / "books_catalog.backup.json"
SUMMARY_OUTPUT = CATALOG_DIR / "catalog_summary.md"

CATALOG_FIELDS = [
    "book_id",
    "file_name",
    "title_guess",
    "category_guess",
    "source_type",
    "priority",
    "size_mb",
    "modified_at",
    "extract_status",
    "processing_status",
    "notes",
]

PRIORITY_RANK = {
    "high": 0,
    "medium_high": 1,
    "medium": 2,
}

CATEGORY_RANK = {
    "harmonic_pattern": 0,
    "fibonacci_analysis": 1,
    "support_resistance": 2,
    "candlestick_pattern": 3,
    "chart_pattern": 4,
    "trendline_analysis": 5,
    "volume_price_analysis": 6,
    "risk_management": 7,
    "fundamental_analysis": 8,
    "investment_management": 9,
    "psychology": 10,
    "supporting": 11,
}


@dataclass(frozen=True)
class CategoryRule:
    category: str
    keywords: tuple[str, ...]
    source_type: str
    priority: str


CATEGORY_RULES = [
    CategoryRule(
        category="harmonic_pattern",
        keywords=(
            "harmonic",
            "harmoni",
            "gartley",
            "bat",
            "butterfly",
            "crab",
            "abcd",
            "xabcd",
            "prz",
            "reversal zone",
        ),
        source_type="graph_theory_reference",
        priority="high",
    ),
    CategoryRule(
        category="fibonacci_analysis",
        keywords=(
            "fibonacci",
            "fibo",
            "retracement",
            "extension",
            "golden ratio",
        ),
        source_type="graph_theory_reference",
        priority="high",
    ),
    CategoryRule(
        category="support_resistance",
        keywords=(
            "support",
            "resistance",
            "snr",
            "supply",
            "demand",
            "zona",
            "zone",
        ),
        source_type="technical_reference",
        priority="high",
    ),
    CategoryRule(
        category="candlestick_pattern",
        keywords=(
            "candlestick",
            "candle",
            "bullish",
            "bearish",
            "doji",
            "engulfing",
            "hammer",
            "pinbar",
        ),
        source_type="technical_reference",
        priority="high",
    ),
    CategoryRule(
        category="chart_pattern",
        keywords=(
            "chart pattern",
            "pattern",
            "triangle",
            "wedge",
            "head shoulder",
            "double top",
            "double bottom",
            "flag",
            "pennant",
        ),
        source_type="technical_reference",
        priority="high",
    ),
    CategoryRule(
        category="trendline_analysis",
        keywords=(
            "trendline",
            "trend line",
            "trend",
            "channel",
        ),
        source_type="technical_reference",
        priority="high",
    ),
    CategoryRule(
        category="volume_price_analysis",
        keywords=(
            "volume",
            "vpa",
            "tape",
            "tape reading",
            "wyckoff",
            "bandarmology",
            "bandar",
        ),
        source_type="volume_reference",
        priority="high",
    ),
    CategoryRule(
        category="fundamental_analysis",
        keywords=(
            "fundamental",
            "laporan keuangan",
            "valuation",
            "valuasi",
            "finansial",
            "financial",
            "ratio",
            "rasio",
        ),
        source_type="fundamental_reference",
        priority="medium_high",
    ),
    CategoryRule(
        category="risk_management",
        keywords=(
            "risk",
            "risiko",
            "stop loss",
            "money management",
            "margin of safety",
            "position sizing",
        ),
        source_type="risk_reference",
        priority="high",
    ),
    CategoryRule(
        category="investment_management",
        keywords=(
            "portfolio",
            "portofolio",
            "investment",
            "investing",
            "investasi",
        ),
        source_type="investment_reference",
        priority="medium",
    ),
    CategoryRule(
        category="psychology",
        keywords=(
            "psychology",
            "psikologi",
            "mindset",
            "mental",
        ),
        source_type="education_reference",
        priority="medium",
    ),
]

SUPPORTING_RULE = CategoryRule(
    category="supporting",
    keywords=(),
    source_type="supporting_reference",
    priority="medium",
)


def normalize_text(value: str) -> str:
    cleaned = re.sub(r"[_\-.]+", " ", value)
    cleaned = re.sub(r"\s+", " ", cleaned)
    return cleaned.strip()


def normalize_for_matching(value: str) -> str:
    cleaned = normalize_text(value).lower()
    cleaned = re.sub(r"[^a-z0-9]+", " ", cleaned)
    return re.sub(r"\s+", " ", cleaned).strip()


def keyword_matches(normalized_name: str, keyword: str) -> bool:
    normalized_keyword = normalize_for_matching(keyword)
    if not normalized_keyword:
        return False

    pattern = rf"(?<![a-z0-9]){re.escape(normalized_keyword)}(?![a-z0-9])"
    return re.search(pattern, normalized_name) is not None


def guess_title(pdf_path: Path) -> str:
    return normalize_text(pdf_path.stem)


def detect_category(file_name: str) -> CategoryRule:
    normalized_name = normalize_for_matching(file_name)

    for rule in CATEGORY_RULES:
        if any(keyword_matches(normalized_name, keyword) for keyword in rule.keywords):
            return rule

    return SUPPORTING_RULE


def create_book_id(relative_path: str) -> str:
    normalized_path = relative_path.replace("\\", "/").lower()
    digest = hashlib.sha1(normalized_path.encode("utf-8")).hexdigest()[:12]
    return f"book_{digest}"


def iter_pdf_files(books_dir: Path) -> Iterable[Path]:
    return sorted(
        (path for path in books_dir.rglob("*.pdf") if path.is_file()),
        key=lambda path: path.relative_to(books_dir).as_posix().lower(),
    )


def format_modified_at(timestamp: float) -> str:
    return datetime.fromtimestamp(timestamp).astimezone().isoformat(timespec="seconds")


def build_catalog_row(pdf_path: Path) -> dict[str, object]:
    relative_name = pdf_path.relative_to(BOOKS_DIR).as_posix()
    stat = pdf_path.stat()
    rule = detect_category(relative_name)

    return {
        "book_id": create_book_id(relative_name),
        "file_name": relative_name,
        "title_guess": guess_title(pdf_path),
        "category_guess": rule.category,
        "source_type": rule.source_type,
        "priority": rule.priority,
        "size_mb": round(stat.st_size / (1024 * 1024), 2),
        "modified_at": format_modified_at(stat.st_mtime),
        "extract_status": "pending",
        "processing_status": "not_processed",
        "notes": "",
    }


def backup_existing_catalog() -> list[Path]:
    backups: list[Path] = []
    backup_pairs = (
        (CSV_OUTPUT, CSV_BACKUP),
        (JSON_OUTPUT, JSON_BACKUP),
    )

    for source, backup in backup_pairs:
        if source.exists():
            shutil.copy2(source, backup)
            backups.append(backup)

    return backups


def write_csv(rows: list[dict[str, object]], output_path: Path) -> None:
    with output_path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=CATALOG_FIELDS)
        writer.writeheader()
        writer.writerows(rows)


def write_json(rows: list[dict[str, object]], output_path: Path) -> None:
    with output_path.open("w", encoding="utf-8") as file:
        json.dump(rows, file, ensure_ascii=False, indent=2)
        file.write("\n")


def sort_by_processing_priority(row: dict[str, object]) -> tuple[int, int, str]:
    priority = str(row["priority"])
    category = str(row["category_guess"])
    title = str(row["title_guess"]).lower()
    return (
        PRIORITY_RANK.get(priority, 99),
        CATEGORY_RANK.get(category, 99),
        title,
    )


def duplicate_similarity(title_a: str, title_b: str) -> float:
    normalized_a = normalize_for_matching(title_a)
    normalized_b = normalize_for_matching(title_b)
    if not normalized_a or not normalized_b:
        return 0.0

    sequence_score = SequenceMatcher(None, normalized_a, normalized_b).ratio()
    tokens_a = set(normalized_a.split())
    tokens_b = set(normalized_b.split())
    token_score = len(tokens_a & tokens_b) / len(tokens_a | tokens_b)
    return max(sequence_score, token_score)


def find_possible_duplicates(rows: list[dict[str, object]]) -> list[tuple[str, str, float]]:
    duplicates: list[tuple[str, str, float]] = []

    for index, row_a in enumerate(rows):
        for row_b in rows[index + 1 :]:
            similarity = duplicate_similarity(
                str(row_a["title_guess"]),
                str(row_b["title_guess"]),
            )
            if similarity >= 0.86:
                duplicates.append(
                    (
                        str(row_a["file_name"]),
                        str(row_b["file_name"]),
                        similarity,
                    )
                )

    return sorted(duplicates, key=lambda item: item[2], reverse=True)


def render_markdown_list(items: Iterable[str]) -> str:
    rendered = [f"- {item}" for item in items]
    return "\n".join(rendered) if rendered else "- Tidak ada"


def create_summary_report(rows: list[dict[str, object]], output_path: Path) -> None:
    category_counts = Counter(str(row["category_guess"]) for row in rows)
    high_priority_count = sum(1 for row in rows if row["priority"] == "high")
    priority_rows = sorted(rows, key=sort_by_processing_priority)
    top_20 = priority_rows[:20]
    possible_duplicates = find_possible_duplicates(rows)
    recommended_first = [
        row
        for row in priority_rows
        if row["priority"] in {"high", "medium_high"}
    ][:15]

    category_lines = [
        f"{category}: {category_counts.get(category, 0)}"
        for category in CATEGORY_RANK
        if category_counts.get(category, 0) > 0
    ]
    top_20_lines = [
        f"{row['file_name']} - {row['category_guess']} - {row['priority']}"
        for row in top_20
    ]
    duplicate_lines = [
        f"{left} <> {right} ({similarity:.0%})"
        for left, right, similarity in possible_duplicates[:30]
    ]
    recommendation_lines = [
        f"{row['file_name']} - mulai dari kategori {row['category_guess']}"
        for row in recommended_first
    ]

    content = f"""# Catalog Summary

Generated at: {datetime.now().astimezone().isoformat(timespec="seconds")}

## Total File PDF Terdeteksi

{len(rows)}

## Jumlah Per Kategori

{render_markdown_list(category_lines)}

## Jumlah High Priority

{high_priority_count}

## Daftar 20 Buku Prioritas Tertinggi

{render_markdown_list(top_20_lines)}

## File yang Kemungkinan Duplikat Berdasarkan Nama Mirip

{render_markdown_list(duplicate_lines)}

## Rekomendasi Buku yang Diproses Dulu

Mulai dari buku high priority yang menjadi fondasi analisis teknikal berbasis grafik, lalu lanjut ke fundamental medium-high.

{render_markdown_list(recommendation_lines)}

## Catatan

Report ini hanya memakai nama file dan metadata filesystem. Isi PDF belum dibaca, teks belum diekstrak, dan tidak ada file yang dikirim ke Supabase.
"""

    output_path.write_text(content, encoding="utf-8")


def main() -> None:
    if not BOOKS_DIR.exists():
        raise FileNotFoundError(f"Books directory not found: {BOOKS_DIR}")

    CATALOG_DIR.mkdir(parents=True, exist_ok=True)
    backups = backup_existing_catalog()

    rows = [build_catalog_row(pdf_path) for pdf_path in iter_pdf_files(BOOKS_DIR)]
    write_csv(rows, CSV_OUTPUT)
    write_json(rows, JSON_OUTPUT)
    create_summary_report(rows, SUMMARY_OUTPUT)

    print(f"Scanned {len(rows)} PDF file(s).")
    if backups:
        print("Backed up previous catalog:")
        for backup in backups:
            print(f"- {backup}")
    else:
        print("No previous catalog found to back up.")
    print(f"CSV catalog: {CSV_OUTPUT}")
    print(f"JSON catalog: {JSON_OUTPUT}")
    print(f"Summary report: {SUMMARY_OUTPUT}")


if __name__ == "__main__":
    main()
