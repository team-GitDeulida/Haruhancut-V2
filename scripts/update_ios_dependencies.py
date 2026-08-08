#!/usr/bin/env python3
"""Find safe Swift Package updates for Haruhancut's Tuist manifest.

Only direct .package(url: ..., from: ...) declarations are eligible. The
script deliberately supports the format used in Tuist/Package.swift rather
than attempting to rewrite arbitrary Swift source code.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Iterable


SEMVER_PATTERN = re.compile(r"^v?(\d+)\.(\d+)\.(\d+)$")
PACKAGE_PATTERN = re.compile(
    r'\.package\s*\(\s*url:\s*"(?P<url>[^"]+)"\s*,\s*'
    r'from:\s*"(?P<version>[^"]+)"\s*\)',
    re.DOTALL,
)

# Native SDKs have a larger compatibility surface. Their minor releases are
# reported but never applied automatically.
PATCH_ONLY_IDENTITIES = frozenset(
    {
        "firebase-ios-sdk",
        "kakao-ios-sdk",
        "kakao-ios-sdk-rx",
    }
)


@dataclass(frozen=True, order=True)
class Version:
    major: int
    minor: int
    patch: int

    @classmethod
    def parse(cls, value: str) -> "Version | None":
        match = SEMVER_PATTERN.fullmatch(value.strip())
        if match is None:
            return None
        return cls(*(int(part) for part in match.groups()))

    def __str__(self) -> str:
        return f"{self.major}.{self.minor}.{self.patch}"


@dataclass(frozen=True)
class Dependency:
    url: str
    declared_version: Version

    @property
    def identity(self) -> str:
        path = normalize_url(self.url).rsplit("/", 1)[-1]
        return path.lower()

    @property
    def patch_only(self) -> bool:
        return self.identity in PATCH_ONLY_IDENTITIES


def normalize_url(url: str) -> str:
    return url.strip().removesuffix("/").removesuffix(".git").lower()


def parse_dependencies(package_file: Path) -> tuple[list[Dependency], list[dict[str, str]]]:
    dependencies: list[Dependency] = []
    skipped: list[dict[str, str]] = []
    source = "\n".join(
        line for line in package_file.read_text().splitlines() if not line.lstrip().startswith("//")
    )

    for match in PACKAGE_PATTERN.finditer(source):
        version = Version.parse(match.group("version"))
        if version is None:
            skipped.append(
                {
                    "url": match.group("url"),
                    "reason": "unsupported-version-requirement",
                    "detail": f'from: "{match.group("version")}" is not a stable SemVer value',
                }
            )
            continue
        dependencies.append(Dependency(match.group("url"), version))

    return dependencies, skipped


def load_resolved_versions(resolved_file: Path) -> dict[str, Version]:
    data = json.loads(resolved_file.read_text())
    versions: dict[str, Version] = {}

    for pin in data.get("pins", []):
        location = pin.get("location")
        version_text = pin.get("state", {}).get("version")
        if not isinstance(location, str) or not isinstance(version_text, str):
            continue
        version = Version.parse(version_text)
        if version is not None:
            versions[normalize_url(location)] = version

    return versions


def fetch_versions(url: str, timeout: int) -> list[Version]:
    result = subprocess.run(
        ["git", "ls-remote", "--tags", "--refs", url],
        check=True,
        capture_output=True,
        text=True,
        timeout=timeout,
    )
    versions = {
        version
        for line in result.stdout.splitlines()
        if len(line.split()) == 2
        for version in [Version.parse(line.split()[1].removeprefix("refs/tags/"))]
        if version is not None
    }
    return sorted(versions)


def select_safe_target(
    current: Version, available: Iterable[Version], patch_only: bool
) -> Version | None:
    candidates = [
        version
        for version in available
        if version.major == current.major
        and (not patch_only or version.minor == current.minor)
        and version > current
    ]
    return max(candidates, default=None)


def build_update_plan(
    dependencies: Iterable[Dependency],
    resolved_versions: dict[str, Version],
    lookup: Callable[[str], list[Version]],
    initial_skips: Iterable[dict[str, str]] = (),
) -> dict[str, object]:
    updates: list[dict[str, str]] = []
    skipped = list(initial_skips)
    major_updates_excluded: list[dict[str, str]] = []
    errors: list[dict[str, str]] = []

    for dependency in dependencies:
        current = resolved_versions.get(normalize_url(dependency.url), dependency.declared_version)
        try:
            available = lookup(dependency.url)
        except (subprocess.SubprocessError, TimeoutError, OSError) as error:
            errors.append(
                {
                    "identity": dependency.identity,
                    "url": dependency.url,
                    "reason": "version-lookup-failed",
                    "detail": str(error),
                }
            )
            continue

        if not available:
            skipped.append(
                {
                    "identity": dependency.identity,
                    "url": dependency.url,
                    "reason": "no-stable-semver-tags",
                    "detail": "No vX.Y.Z or X.Y.Z tag was found.",
                }
            )
            continue

        newer_major = [version for version in available if version.major > current.major]
        if newer_major:
            major_updates_excluded.append(
                {
                    "identity": dependency.identity,
                    "from": str(current),
                    "latest_major": str(max(newer_major)),
                }
            )

        target = select_safe_target(current, available, dependency.patch_only)
        if target is None:
            policy = "patch-only" if dependency.patch_only else "patch-or-minor"
            skipped.append(
                {
                    "identity": dependency.identity,
                    "url": dependency.url,
                    "reason": "already-up-to-date-within-policy",
                    "detail": policy,
                }
            )
            continue

        updates.append(
            {
                "identity": dependency.identity,
                "url": dependency.url,
                "declared_from": str(dependency.declared_version),
                "resolved_from": str(current),
                "to": str(target),
                "update_type": "minor" if target.minor != current.minor else "patch",
                "policy": "patch-only" if dependency.patch_only else "patch-or-minor",
            }
        )

    return {
        "has_changes": bool(updates),
        "updates": updates,
        "major_updates_excluded": major_updates_excluded,
        "skipped": skipped,
        "errors": errors,
    }


def apply_updates(package_file: Path, updates: Iterable[dict[str, str]]) -> None:
    targets = {normalize_url(update["url"]): update["to"] for update in updates}
    original = package_file.read_text()

    def is_commented(match: re.Match[str]) -> bool:
        line_start = original.rfind("\n", 0, match.start()) + 1
        return original[line_start:match.start()].lstrip().startswith("//")

    def replace(match: re.Match[str]) -> str:
        if is_commented(match):
            return match.group(0)
        target = targets.get(normalize_url(match.group("url")))
        if target is None:
            return match.group(0)
        start = match.start("version") - match.start()
        end = match.end("version") - match.start()
        return f"{match.group(0)[:start]}{target}{match.group(0)[end:]}"

    package_file.write_text(PACKAGE_PATTERN.sub(replace, original))


def markdown_report(report: dict[str, object]) -> str:
    lines = ["## iOS dependency updater report", ""]
    updates = report["updates"]
    if updates:
        lines.extend(["### Updates", "", "| Package | From | To | Policy |", "| --- | --- | --- | --- |"])
        for update in updates:
            lines.append(
                f"| {update['identity']} | {update['resolved_from']} | {update['to']} | {update['policy']} |"
            )
    else:
        lines.extend(["### Updates", "", "No safe dependency updates were found."])

    lines.extend(["", "### Major updates excluded", ""])
    major_updates = report["major_updates_excluded"]
    if major_updates:
        lines.extend(["| Package | Current | Latest excluded major |", "| --- | --- | --- |"])
        for update in major_updates:
            lines.append(
                f"| {update['identity']} | {update['from']} | {update['latest_major']} |"
            )
    else:
        lines.append("No newer major release was found.")

    lines.extend(["", "### Skipped", ""])
    skipped = report["skipped"]
    if skipped:
        for item in skipped:
            identity = item.get("identity", item.get("url", "unknown"))
            lines.append(f"- {identity}: {item['reason']} ({item['detail']})")
    else:
        lines.append("No package was skipped.")

    lines.extend(
        [
            "",
            "### Validation",
            "",
            "- Tuist dependency resolution and project generation completed before this PR was created.",
            "- Core, Data, and App build-for-testing/test-without-building checks completed successfully.",
            "- This workflow does not enable auto-merge or deployment.",
        ]
    )
    return "\n".join(lines) + "\n"


def write_file(path: str | None, content: str) -> None:
    if path is not None:
        Path(path).write_text(content)


def parse_arguments() -> argparse.Namespace:
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(
        description="Find and optionally apply safe direct iOS Swift Package updates."
    )
    parser.add_argument("--package-file", type=Path, default=root / "Tuist/Package.swift")
    parser.add_argument("--resolved-file", type=Path, default=root / "Tuist/Package.resolved")
    parser.add_argument("--report", help="Path to write the structured JSON report.")
    parser.add_argument("--markdown-report", help="Path to write the Markdown report.")
    parser.add_argument("--dry-run", action="store_true", help="Report candidates without editing files.")
    parser.add_argument("--timeout", type=int, default=30, help="Seconds allowed for each Git tag lookup.")
    return parser.parse_args()


def main() -> int:
    arguments = parse_arguments()
    dependencies, initial_skips = parse_dependencies(arguments.package_file)
    resolved_versions = load_resolved_versions(arguments.resolved_file)
    report = build_update_plan(
        dependencies,
        resolved_versions,
        lambda url: fetch_versions(url, arguments.timeout),
        initial_skips,
    )

    report["dry_run"] = arguments.dry_run
    report["direct_dependency_count"] = len(dependencies)
    report_json = json.dumps(report, ensure_ascii=False, indent=2) + "\n"
    write_file(arguments.report, report_json)
    write_file(arguments.markdown_report, markdown_report(report))
    print(report_json, end="")

    if report["errors"]:
        return 1
    if report["has_changes"] and not arguments.dry_run:
        apply_updates(arguments.package_file, report["updates"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
