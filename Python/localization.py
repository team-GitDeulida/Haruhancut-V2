import csv
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent
LANGUAGES = ["en", "ko"]

CSV_PATH = SCRIPT_DIR / "localizable.csv"
LOCALIZING_DIR = PROJECT_ROOT / "Projects" / "Shared" / "DSKit" / "Resources" / "Localizing"
ENUM_OUTPUT_PATH = PROJECT_ROOT / "Projects" / "Shared" / "DSKit" / "Sources" / "Extensions+" / "LocalizationKey.swift"
OUTPUT_FILES = {
    lang: LOCALIZING_DIR / f"{lang}.lproj" / "Localizable.strings"
    for lang in LANGUAGES
}


def escape_strings_value(value: str) -> str:
    return value.replace('"', '\\"')


def to_swift_case_name(key: str) -> str:
    separators_replaced = key.replace(".", "_").replace("-", "_")
    parts = [part for part in separators_replaced.split("_") if part]
    if not parts:
        raise ValueError(f"Invalid localization key: {key}")

    first = parts[0].lower()
    rest = [part[:1].upper() + part[1:] for part in parts[1:]]
    return first + "".join(rest)


def read_preamble(path: Path) -> str:
    if not path.exists():
        return ""

    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    body_start = next(
        (index for index, line in enumerate(lines) if line.lstrip().startswith('"')),
        len(lines),
    )
    return "".join(lines[:body_start])


if not CSV_PATH.exists():
    raise FileNotFoundError(f"CSV file not found: {CSV_PATH}")


localizations = {lang: [] for lang in LANGUAGES}
enum_keys = ["import Foundation", "", "public enum LocalizationKey: String {"]

with CSV_PATH.open("r", encoding="utf-8-sig", newline="") as csv_file:
    reader = csv.DictReader(csv_file)

    missing_columns = [column for column in ["key", *LANGUAGES] if column not in (reader.fieldnames or [])]
    if missing_columns:
        raise ValueError(f"Missing CSV columns: {', '.join(missing_columns)}")

    for row in reader:
        key = (row.get("key") or "").strip()
        if not key:
            continue

        enum_keys.append(f'    case {to_swift_case_name(key)} = "{key}"')

        for lang in LANGUAGES:
            value = row.get(lang, "")
            line = f'"{escape_strings_value(key)}" = "{escape_strings_value(value)}";'
            localizations[lang].append(line)


for lang in LANGUAGES:
    output_path = OUTPUT_FILES[lang]
    output_path.parent.mkdir(parents=True, exist_ok=True)

    preamble = read_preamble(output_path)
    content = "\n".join(localizations[lang]) + "\n"
    output_path.write_text(f"{preamble}{content}", encoding="utf-8")

enum_keys.append("")
enum_keys.append("    public var localized: String {")
enum_keys.append("        rawValue.localized()")
enum_keys.append("    }")
enum_keys.append("}")

ENUM_OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
ENUM_OUTPUT_PATH.write_text("\n".join(enum_keys) + "\n", encoding="utf-8")


print(f"Localization files generated successfully from {CSV_PATH.name}")
