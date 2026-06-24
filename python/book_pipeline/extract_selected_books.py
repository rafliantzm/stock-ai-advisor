from __future__ import annotations

import argparse
import csv
import json
from datetime import datetime
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[2]
BOOKS_DIR = PROJECT_ROOT / "data" / "books"
CATALOG_CSV = PROJECT_ROOT / "data" / "catalog" / "books_catalog.csv"
CATALOG_JSON = PROJECT_ROOT / "data" / "catalog" / "books_catalog.json"
OUTPUT_DIR = PROJECT_ROOT / "data" / "extracted_text"
EXTRACTION_REPORT = OUTPUT_DIR / "extraction_report.json"
EXTRACTION_SUMMARY = OUTPUT_DIR / "extraction_summary.md"

ALLOWED_CATEGORIES = {
    "harmonic_pattern",
    "fibonacci_analysis",
    "support_resistance",
    "candlestick_pattern",
    "chart_pattern",
    "trendline_analysis",
    "volume_price_analysis",
    "risk_management",
}

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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract digital PDF text for selected high-priority books only.",
    )
    parser.add_argument(
        "--max-books",
        type=int,
        default=10,
        help="Maximum number of selected books to extract.",
    )
    parser.add_argument(
        "--priority",
        default="high",
        help="Catalog priority to process, usually 'high'.",
    )
    return parser.parse_args()


def load_pypdf_reader() -> Any:
    try:
        from pypdf import PdfReader
    except ImportError as exc:
        raise SystemExit(
            "Missing dependency: pypdf. Install it with "
            "`python -m pip install -r python/requirements.txt`."
        ) from exc

    return PdfReader


def read_catalog() -> list[dict[str, str]]:
    if not CATALOG_CSV.exists():
        raise FileNotFoundError(f"Catalog CSV not found: {CATALOG_CSV}")

    with CATALOG_CSV.open("r", newline="", encoding="utf-8") as file:
        return list(csv.DictReader(file))


def write_catalog_csv(rows: list[dict[str, str]]) -> None:
    with CATALOG_CSV.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=CATALOG_FIELDS)
        writer.writeheader()
        writer.writerows(rows)


def catalog_row_for_json(row: dict[str, str]) -> dict[str, Any]:
    json_row: dict[str, Any] = dict(row)
    try:
        json_row["size_mb"] = float(row["size_mb"])
    except (KeyError, TypeError, ValueError):
        json_row["size_mb"] = row.get("size_mb", "")

    return json_row


def write_catalog_json(rows: list[dict[str, str]]) -> None:
    with CATALOG_JSON.open("w", encoding="utf-8") as file:
        json.dump([catalog_row_for_json(row) for row in rows], file, ensure_ascii=False, indent=2)
        file.write("\n")


def select_books(
    rows: list[dict[str, str]],
    priority: str,
    max_books: int,
) -> list[dict[str, str]]:
    selected = [
        row
        for row in rows
        if row.get("priority") == priority
        and row.get("category_guess") in ALLOWED_CATEGORIES
    ]
    return selected[:max_books]


def resolve_book_path(file_name: str) -> Path:
    candidate = (BOOKS_DIR / file_name).resolve()
    books_root = BOOKS_DIR.resolve()

    try:
        candidate.relative_to(books_root)
    except ValueError as exc:
        raise ValueError(f"Refusing to process file outside data/books: {file_name}") from exc

    return candidate


def clean_page_text(text: str | None) -> str:
    if not text:
        return ""

    lines = [line.rstrip() for line in text.replace("\x00", "").splitlines()]
    return "\n".join(lines).strip()


def extract_book(row: dict[str, str], pdf_reader: Any) -> dict[str, Any]:
    pdf_path = resolve_book_path(row["file_name"])
    if not pdf_path.exists():
        raise FileNotFoundError(f"PDF not found: {pdf_path}")

    reader = pdf_reader(str(pdf_path))
    pages: list[dict[str, Any]] = []

    for index, page in enumerate(reader.pages, start=1):
        text = clean_page_text(page.extract_text())
        char_count = len(text)
        page_status = "success" if char_count > 0 else "needs_ocr"
        pages.append(
            {
                "page_number": index,
                "text": text,
                "char_count": char_count,
                "extraction_status": page_status,
            }
        )

    total_pages = len(pages)
    pages_with_text = sum(1 for page in pages if page["char_count"] > 0)
    empty_pages = total_pages - pages_with_text
    total_chars = sum(page["char_count"] for page in pages)

    if total_pages == 0 or pages_with_text == 0:
        overall_status = "needs_ocr"
    elif empty_pages > 0:
        overall_status = "partial"
    else:
        overall_status = "success"

    return {
        "book_id": row["book_id"],
        "file_name": row["file_name"],
        "category_guess": row["category_guess"],
        "source_type": row["source_type"],
        "priority": row["priority"],
        "pages": pages,
        "summary": {
            "total_pages": total_pages,
            "pages_with_text": pages_with_text,
            "empty_pages": empty_pages,
            "total_chars": total_chars,
            "overall_status": overall_status,
        },
    }


def save_book_extraction(result: dict[str, Any]) -> Path:
    output_path = OUTPUT_DIR / f"{result['book_id']}.json"
    with output_path.open("w", encoding="utf-8") as file:
        json.dump(result, file, ensure_ascii=False, indent=2)
        file.write("\n")

    return output_path


def update_catalog_row(row: dict[str, str], overall_status: str, note: str = "") -> None:
    row["extract_status"] = overall_status

    if overall_status == "success":
        row["processing_status"] = "extracted"
    elif overall_status == "partial":
        row["processing_status"] = "partial"
    elif overall_status == "needs_ocr":
        row["processing_status"] = "needs_ocr"

    if note:
        existing_note = row.get("notes", "")
        row["notes"] = f"{existing_note}; {note}".strip("; ")


def write_report(report: dict[str, Any]) -> None:
    with EXTRACTION_REPORT.open("w", encoding="utf-8") as file:
        json.dump(report, file, ensure_ascii=False, indent=2)
        file.write("\n")


def write_summary(report: dict[str, Any]) -> None:
    successful_items = [
        item
        for item in report["processed_books"]
        if item["overall_status"] in {"success", "partial", "needs_ocr"}
    ]
    high_level_lines = [
        f"- Requested priority: {report['requested_priority']}",
        f"- Max books: {report['max_books']}",
        f"- Selected books: {report['selected_count']}",
        f"- Processed books: {len(successful_items)}",
        f"- Missing files: {len(report['missing_files'])}",
        f"- Failed files: {len(report['failed_files'])}",
    ]
    processed_lines = [
        (
            f"- {item['file_name']} - {item['category_guess']} - "
            f"{item['overall_status']} - {item['total_chars']} chars"
        )
        for item in report["processed_books"]
    ]
    missing_lines = [
        f"- {item['file_name']} - {item['reason']}"
        for item in report["missing_files"]
    ]
    failed_lines = [
        f"- {item['file_name']} - {item['reason']}"
        for item in report["failed_files"]
    ]

    content = f"""# Text Extraction Summary

Generated at: {report['generated_at']}

## Run Settings

{chr(10).join(high_level_lines)}

## Processed Books

{chr(10).join(processed_lines) if processed_lines else "- Tidak ada"}

## Missing Files

{chr(10).join(missing_lines) if missing_lines else "- Tidak ada"}

## Failed Files

{chr(10).join(failed_lines) if failed_lines else "- Tidak ada"}

## Notes

- Ekstraksi hanya memakai parser PDF digital `pypdf`.
- OCR belum dijalankan otomatis.
- File PDF asli tidak diubah.
- Tidak ada data yang dikirim ke Supabase.
"""

    EXTRACTION_SUMMARY.write_text(content, encoding="utf-8")


def main() -> None:
    args = parse_args()
    if args.max_books < 1:
        raise ValueError("--max-books must be at least 1")

    pdf_reader = load_pypdf_reader()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    catalog_rows = read_catalog()
    selected_rows = select_books(catalog_rows, args.priority, args.max_books)

    report: dict[str, Any] = {
        "generated_at": datetime.now().astimezone().isoformat(timespec="seconds"),
        "catalog_csv": str(CATALOG_CSV),
        "books_dir": str(BOOKS_DIR),
        "requested_priority": args.priority,
        "allowed_categories": sorted(ALLOWED_CATEGORIES),
        "max_books": args.max_books,
        "selected_count": len(selected_rows),
        "processed_books": [],
        "missing_files": [],
        "failed_files": [],
    }

    for row in selected_rows:
        try:
            pdf_path = resolve_book_path(row["file_name"])
            if not pdf_path.exists():
                raise FileNotFoundError(f"PDF not found: {pdf_path}")

            result = extract_book(row, pdf_reader)
            output_path = save_book_extraction(result)
            overall_status = result["summary"]["overall_status"]
            update_catalog_row(row, overall_status)

            report["processed_books"].append(
                {
                    "book_id": row["book_id"],
                    "file_name": row["file_name"],
                    "category_guess": row["category_guess"],
                    "output_path": str(output_path),
                    "overall_status": overall_status,
                    "total_pages": result["summary"]["total_pages"],
                    "pages_with_text": result["summary"]["pages_with_text"],
                    "empty_pages": result["summary"]["empty_pages"],
                    "total_chars": result["summary"]["total_chars"],
                }
            )
        except FileNotFoundError as exc:
            update_catalog_row(row, "needs_ocr", "file not found during extraction")
            report["missing_files"].append(
                {
                    "book_id": row.get("book_id", ""),
                    "file_name": row.get("file_name", ""),
                    "reason": str(exc),
                }
            )
        except Exception as exc:  # Keep the batch moving and record the exact failure.
            update_catalog_row(row, "needs_ocr", f"extraction failed: {exc}")
            report["failed_files"].append(
                {
                    "book_id": row.get("book_id", ""),
                    "file_name": row.get("file_name", ""),
                    "reason": repr(exc),
                }
            )

    write_catalog_csv(catalog_rows)
    write_catalog_json(catalog_rows)
    write_report(report)
    write_summary(report)

    print(f"Selected {len(selected_rows)} book(s).")
    print(f"Processed {len(report['processed_books'])} book(s).")
    print(f"Missing files: {len(report['missing_files'])}.")
    print(f"Failed files: {len(report['failed_files'])}.")
    print(f"Extraction report: {EXTRACTION_REPORT}")
    print(f"Extraction summary: {EXTRACTION_SUMMARY}")


if __name__ == "__main__":
    main()
