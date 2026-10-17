import copy
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

from scripts.audit_policy import failure_reasons, historical_mirror, localization_value_errors
from scripts.prepare_ci_dependencies import prepare, validate_lock


class AuditPolicyTests(unittest.TestCase):
    def report(self):
        return {"dependency_contracts": {"direct_errors": [], "transitive_errors": []},
                "case_collisions": [], "localization": {"key_parity_errors": []},
                "requires": {"family_module_errors": []}, "non_lua_runtime_dependencies": [],
                "syntax": {"errors": []}, "historical_mirror": {"errors": []},
                "package_inputs": {}, "index_audit": {"denied_paths": [], "potential_secret_paths": []},
                "current_directory_archives": [], "copy_missing": ["new.lua"], "copy_changed": [],
                "copy_extra": [], "package_validation": {"error": "No current package"}}

    def test_source_pass_does_not_grant_release_or_hide_source_failures(self):
        report = self.report()
        self.assertEqual(failure_reasons(report), [])
        self.assertEqual(failure_reasons(report, release=True), ["current Contents parity", "current package validation"])
        for section, key, value in [("syntax", "status", "NOT TESTED"),
                                     ("package_inputs", "error", "wrong Mod ID"),
                                     ("historical_mirror", "errors", ["changed"]),
                                     ("dependency_contracts", "direct_errors", ["missing"]),
                                     ("index_audit", "potential_secret_paths", ["private.txt"])]:
            bad = copy.deepcopy(report)
            bad[section][key] = value
            self.assertTrue(failure_reasons(bad), (section, key))

    def test_historical_archives_still_require_integrity_and_classification(self):
        report = self.report()
        item = {"path": "old.zip", "classification": "historical", "errors": [], "source_differences": ["old.lua"]}
        report["current_directory_archives"] = [item]
        self.assertEqual(failure_reasons(report), [])
        for classification, errors in [("historical", ["CRC failure"]), ("unclassified", []), ("current", [])]:
            item.update(classification=classification, errors=errors)
            self.assertTrue(failure_reasons(report))

    def test_historical_tree_detects_committed_staged_unstaged_and_ignored_changes(self):
        with tempfile.TemporaryDirectory(prefix="nightfall-history-") as temporary:
            root = Path(temporary)
            def git(*args):
                return subprocess.check_output(["git", "-c", "core.autocrlf=false", *args], cwd=root, text=True).strip()
            git("init", "-q")
            git("config", "user.name", "Nightfall tests")
            git("config", "user.email", "tests@example.invalid")
            mirror = root / "Contents/mods/ProjectNightfall"
            mirror.mkdir(parents=True)
            content = mirror / "old.lua"
            content.write_bytes(b"return 1\n")
            (root / ".gitignore").write_bytes(b"*.ignored\n")
            git("add", ".")
            git("commit", "-qm", "fixture")
            inventory = {"packaging_mirror": {"path": "Contents/mods/ProjectNightfall", "use_for_release": False,
                                             "git_tree": git("rev-parse", "HEAD:Contents/mods/ProjectNightfall")}}
            self.assertEqual(historical_mirror(root, inventory)["status"], "PASS")
            extra = mirror / "new.ignored"
            extra.write_bytes(b"extra")
            self.assertEqual(historical_mirror(root, inventory)["status"], "FAIL")
            extra.unlink()  # Disposable test-owned fixture only.
            content.write_bytes(b"return 2\n")
            self.assertEqual(historical_mirror(root, inventory)["status"], "FAIL")
            git("add", ".")
            self.assertEqual(historical_mirror(root, inventory)["status"], "FAIL")
            git("commit", "-qm", "changed fixture")
            self.assertEqual(historical_mirror(root, inventory)["status"], "FAIL")
            del inventory["packaging_mirror"]["git_tree"]
            self.assertEqual(historical_mirror(root, inventory)["status"], "FAIL")

    def test_translation_placeholders_and_nonempty_values(self):
        self.assertEqual(localization_value_errors({"label": "%1: %2"}, {"label": "%2 - %1"}), [])
        for value in ["missing %1", "%1 %1", "", None, 5]:
            self.assertTrue(localization_value_errors({"label": "%1: %2"}, {"label": value}))
        self.assertTrue(localization_value_errors({"label": "label"}, {"extra": "value"}))

    def test_dependency_lock_rejects_mutable_refs_unexpected_origins_and_paths(self):
        root = Path(__file__).resolve().parents[1]
        inventory = json.loads((root / "SOURCE_INVENTORY.json").read_text())
        lock = json.loads((root / "tests/dependencies.lock.json").read_text())
        self.assertEqual(len(validate_lock(lock, inventory)), 5)
        for key, value in [("commit", "main"), ("url", "file:///other"), ("folder", "../escape"), ("mod_id", "../bad")]:
            bad = copy.deepcopy(lock)
            bad["dependencies"][0][key] = value
            with self.assertRaises(ValueError):
                validate_lock(bad, inventory)

    def test_existing_fixture_is_verified_without_fetch_or_repair(self):
        with tempfile.TemporaryDirectory(prefix="nightfall-fixtures-") as temporary:
            root = Path(temporary)
            fixture = root / ".local/ci-dependencies/Fixture"
            source = fixture / "src/Fixture/42"
            source.mkdir(parents=True)
            metadata = source / "mod.info"
            metadata.write_bytes(b"id=Fixture\nmodversion=1.0.0\n")
            def git(*args):
                return subprocess.check_output(["git", "-c", "core.autocrlf=false", *args], cwd=fixture, text=True).strip()
            git("init", "-q")
            git("config", "user.name", "Nightfall tests")
            git("config", "user.email", "tests@example.invalid")
            git("remote", "add", "origin", "https://github.com/B47ANCE/Fixture.git")
            git("add", ".")
            git("commit", "-qm", "fixture")
            (root / "tests").mkdir()
            (root / "SOURCE_INVENTORY.json").write_text(json.dumps({"dependency_sources": [{"folder": "Fixture", "mod_id": "Fixture"}]}))
            (root / "tests/dependencies.lock.json").write_text(json.dumps({"dependencies": [{"folder": "Fixture", "mod_id": "Fixture",
                "url": "https://github.com/B47ANCE/Fixture.git", "commit": git("rev-parse", "HEAD")}]}))
            self.assertEqual(prepare(root, check_only=True)[0]["version"], "1.0.0")
            metadata.write_bytes(b"id=Fixture\nmodversion=2.0.0\n")
            with self.assertRaisesRegex(ValueError, "dirty"):
                prepare(root, check_only=True)
            self.assertIn(b"2.0.0", metadata.read_bytes())
            git("remote", "set-url", "origin", "https://github.com/B47ANCE/Other.git")
            with self.assertRaisesRegex(ValueError, "origin differs"):
                prepare(root, check_only=True)


if __name__ == "__main__":
    unittest.main()
