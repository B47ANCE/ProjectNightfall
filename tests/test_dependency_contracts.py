from pathlib import Path
import json
import tempfile
import unittest
from scripts.dependency_contracts import inspect

class DependencyContractTests(unittest.TestCase):
    def test_transitive_migration_is_not_reported_as_a_pass(self):
        with tempfile.TemporaryDirectory(prefix="nightfall-contract-tests-") as temporary:
            root = Path(temporary)
            (root / "SOURCE_INVENTORY.json").write_text(json.dumps({"dependency_sources": [{"folder": "Spectrum", "mod_id": "lightWorks"}]}))
            source = root / "Spectrum/src/lightWorks/42"
            source.mkdir(parents=True)
            (source / "mod.info").write_text("id=lightWorks\nrequire=powerWorks\nmodversion=0.25.3\n")
            report = inspect(root, root)
            self.assertEqual(report["direct"], "PASS")
            self.assertEqual(report["transitive"], "BLOCKED")
            self.assertEqual(report["transitive_errors"][0]["missing_required_mod_id"], "powerWorks")
            (source / "mod.info").write_text("id=lightWorks\nmodversion=0.25.3\n")
            self.assertEqual(inspect(root, root)["transitive"], "PASS")
            (source / "mod.info").write_text("id=wrong\n")
            self.assertEqual(inspect(root, root)["direct"], "FAIL")
