from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "dependency_updater", ROOT / "scripts/update_ios_dependencies.py"
)
updater = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
sys.modules[SPEC.name] = updater
SPEC.loader.exec_module(updater)


class DependencyUpdaterTests(unittest.TestCase):
    def test_selects_highest_safe_minor_update_and_excludes_major(self) -> None:
        dependency = updater.Dependency("https://github.com/example/Example.git", updater.Version(1, 2, 3))
        report = updater.build_update_plan(
            [dependency],
            {updater.normalize_url(dependency.url): updater.Version(1, 2, 3)},
            lambda _: [updater.Version(1, 2, 4), updater.Version(1, 4, 0), updater.Version(2, 0, 0)],
        )

        self.assertEqual(report["updates"][0]["to"], "1.4.0")
        self.assertEqual(report["updates"][0]["update_type"], "minor")
        self.assertEqual(report["major_updates_excluded"][0]["latest_major"], "2.0.0")

    def test_rejects_major_only_update(self) -> None:
        dependency = updater.Dependency("https://github.com/example/Example.git", updater.Version(1, 2, 3))
        report = updater.build_update_plan(
            [dependency],
            {},
            lambda _: [updater.Version(2, 0, 0)],
        )

        self.assertFalse(report["has_changes"])
        self.assertEqual(report["major_updates_excluded"][0]["latest_major"], "2.0.0")

    def test_native_sdk_is_patch_only(self) -> None:
        dependency = updater.Dependency(
            "https://github.com/firebase/firebase-ios-sdk.git", updater.Version(11, 14, 0)
        )
        report = updater.build_update_plan(
            [dependency],
            {},
            lambda _: [updater.Version(11, 14, 2), updater.Version(11, 15, 0)],
        )

        self.assertEqual(report["updates"][0]["to"], "11.14.2")
        self.assertEqual(report["updates"][0]["policy"], "patch-only")

    def test_reports_no_change_when_current_version_is_latest(self) -> None:
        dependency = updater.Dependency("https://github.com/example/Example.git", updater.Version(1, 2, 3))
        report = updater.build_update_plan(
            [dependency],
            {},
            lambda _: [updater.Version(1, 2, 3)],
        )

        self.assertFalse(report["has_changes"])
        self.assertEqual(report["skipped"][0]["reason"], "already-up-to-date-within-policy")

    def test_ignores_prerelease_and_non_semver_tags(self) -> None:
        self.assertEqual(updater.Version.parse("v1.2.3"), updater.Version(1, 2, 3))
        self.assertIsNone(updater.Version.parse("1.2.3-beta.1"))
        self.assertIsNone(updater.Version.parse("release-1.2.3"))

    def test_ignores_commented_out_package_declarations(self) -> None:
        package_content = '''
// .package(url: "https://github.com/example/Example.git", from: "1.2.3"),
let package = Package(dependencies: [])
'''
        with tempfile.TemporaryDirectory() as directory:
            package_file = Path(directory) / "Package.swift"
            package_file.write_text(package_content)

            dependencies, skipped = updater.parse_dependencies(package_file)

        self.assertEqual(dependencies, [])
        self.assertEqual(skipped, [])

    def test_dry_run_does_not_modify_package_file(self) -> None:
        package_content = '''
let package = Package(
    dependencies: [
        .package(url: "https://github.com/example/Example.git", from: "1.2.3")
    ]
)
'''
        resolved_content = {
            "pins": [
                {
                    "location": "https://github.com/example/Example.git",
                    "state": {"version": "1.2.3"},
                }
            ]
        }

        with tempfile.TemporaryDirectory() as directory:
            package_file = Path(directory) / "Package.swift"
            resolved_file = Path(directory) / "Package.resolved"
            package_file.write_text(package_content)
            resolved_file.write_text(json.dumps(resolved_content))
            dependencies, skipped = updater.parse_dependencies(package_file)
            report = updater.build_update_plan(
                dependencies,
                updater.load_resolved_versions(resolved_file),
                lambda _: [updater.Version(1, 2, 4)],
                skipped,
            )

            original = package_file.read_text()
            self.assertTrue(report["has_changes"])
            self.assertEqual(package_file.read_text(), original)

    def test_apply_updates_preserves_commented_declaration(self) -> None:
        package_content = '''
// .package(url: "https://github.com/example/Example.git", from: "1.2.3")
let package = Package(
    dependencies: [
        .package(url: "https://github.com/example/Example.git", from: "1.2.3")
    ]
)
'''
        with tempfile.TemporaryDirectory() as directory:
            package_file = Path(directory) / "Package.swift"
            package_file.write_text(package_content)

            updater.apply_updates(
                package_file,
                [{"url": "https://github.com/example/Example.git", "to": "1.2.4"}],
            )

            updated = package_file.read_text()
            self.assertIn('// .package(url: "https://github.com/example/Example.git", from: "1.2.3")', updated)
            self.assertIn('.package(url: "https://github.com/example/Example.git", from: "1.2.4")', updated)

    def test_lookup_failure_prevents_updates(self) -> None:
        dependency = updater.Dependency("https://github.com/example/Example.git", updater.Version(1, 2, 3))
        lookup = Mock(side_effect=OSError("network unavailable"))
        report = updater.build_update_plan([dependency], {}, lookup)

        self.assertFalse(report["has_changes"])
        self.assertEqual(report["errors"][0]["reason"], "version-lookup-failed")


if __name__ == "__main__":
    unittest.main()
