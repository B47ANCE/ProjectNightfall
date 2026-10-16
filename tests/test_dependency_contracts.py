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

    def test_nightfall_runtime_requirements_cannot_drift_from_inventory(self):
        with tempfile.TemporaryDirectory(prefix="nightfall-own-contract-") as temporary:
            root = Path(temporary)
            inventory = {"dependency_sources": [{"folder": "HealthCare", "mod_id": "B47ANCEDHealthCare"}],
                         "required_mod_ids": ["B47ANCEDHealthCare"]}
            (root / "SOURCE_INVENTORY.json").write_text(json.dumps(inventory))
            dependency = root / "HealthCare/src/B47ANCEDHealthCare/42"
            dependency.mkdir(parents=True)
            (dependency / "mod.info").write_text("id=B47ANCEDHealthCare\n")
            own = root / "src/ProjectNightfall/42/mod.info";own.parent.mkdir(parents=True)
            own.write_text("id=ProjectNightfall\nrequire=medWorks\n")
            self.assertEqual(inspect(root, root)["direct"], "FAIL")
            own.write_text("id=ProjectNightfall\nrequire=B47ANCEDHealthCare\n")
            self.assertEqual(inspect(root, root)["direct"], "PASS")
