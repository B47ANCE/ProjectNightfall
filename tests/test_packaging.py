"""Packaging safety/integrity tests use disposable project fixtures only."""
from pathlib import Path
import json
import os
import stat
import tempfile
import unittest
from unittest import mock
import warnings
import zipfile

from scripts import package_project as packaging


class PackagingTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="nightfall-package-tests-")
        self.root = Path(self.temporary.name).resolve()
        self.addCleanup(self.temporary.cleanup)
        self.write("VERSION", b"0.27.4\n")
        self.write("SOURCE_INVENTORY.json", json.dumps({"project_version": "0.27.4", "mod_ids": ["ProjectNightfall"],
                   "workshop_ids": ["3788593239"], "required_mod_ids": ["lightWorks"]}).encode())
        self.write("WORKSHOP_ID.txt", b"3788593239\n")
        self.write("preview.png", b"PNG fixture")
        self.write("workshop.txt", b"version=1\ndescription=[b]Mod Version:[/b] 0.27.4\ndescription=\n")
        self.write("WORKSHOP_DESCRIPTION.txt", b"Version 0.27.4\n\nDevelopment build\n")
        self.write("WORKSHOP_CHANGE_NOTE.txt", b"Version 0.27.4\n\nOffline tests only\n")
        self.write("src/ProjectNightfall/42/mod.info", b"id=ProjectNightfall\nmodversion=0.27.4\nrequire=lightWorks\nversionMin=42.20.3\n")
        self.write("src/ProjectNightfall/42/media/lua/shared/Test.lua", b"return {}\n")
        self.write("src/ProjectNightfall/42/icon.png", b"PNG fixture")
        self.write("src/ProjectNightfall/thumbnail.png", b"PNG fixture")
        self.write("src/ProjectNightfall/info.txt", b"Version:\n0.27.4\n")
        self.write("Contents/mods/ProjectNightfall/42/mod.info", b"id=ProjectNightfall\nmodversion=0.27.1\n")
        import subprocess
        for command in (["git", "init", "-q"], ["git", "config", "core.autocrlf", "false"],
                        ["git", "add", "src", "preview.png", "workshop.txt", "VERSION"],
                        ["git", "-c", "user.name=Nightfall Tests", "-c", "user.email=tests@example.invalid",
                         "commit", "-qm", "package fixture"]):
            subprocess.check_call(command, cwd=self.root)


    def write(self, name, data):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        return path

    def archive(self, members):
        path = self.root / "fixture.zip"
        with warnings.catch_warnings(), zipfile.ZipFile(path, "w") as package:
            warnings.simplefilter("ignore", UserWarning)
            for name, data in members:
                package.writestr(name, data)
        return path

    def test_build_preserves_old_mirror_and_repeat_is_identical(self):
        old = packaging.read_tree(self.root / packaging.MIRROR)
        proposed = packaging.plan(self.root)
        report = packaging.build(self.root)
        self.assertEqual(report["contents_parity"], "PASS")
        self.assertEqual(packaging.read_tree(self.root / proposed["backup"]), old)
        paths = packaging.locations(self.root, "0.27.4")
        before = [path.read_bytes() for path in paths]
        self.assertEqual(packaging.build(self.root)["sha256"], report["sha256"])
        self.assertEqual([path.read_bytes() for path in paths], before)

    def test_changed_inputs_cannot_overwrite_existing_package(self):
        packaging.build(self.root)
        archive = packaging.locations(self.root, "0.27.4")[0]
        before = archive.read_bytes()
        self.write("src/ProjectNightfall/42/media/lua/shared/Test.lua", b"return {changed=true}\n")
        with self.assertRaisesRegex(packaging.PackageError, "refusing artifact overwrite"):
            packaging.build(self.root)
        self.assertEqual(archive.read_bytes(), before)

    def test_unknown_mirror_file_is_not_deleted(self):
        self.write("Contents/mods/ProjectNightfall/user-note.txt", b"keep me")
        with self.assertRaisesRegex(packaging.PackageError, "implicit deletion"):
            packaging.build(self.root)
        self.assertEqual((self.root / packaging.MIRROR / "user-note.txt").read_bytes(), b"keep me")

    def test_failed_mirror_install_restores_original(self):
        before = packaging.read_tree(self.root / packaging.MIRROR)
        replace = os.replace
        def fail_install(source, destination):
            if Path(source).name == "ProjectNightfall" and Path(destination) == self.root / packaging.MIRROR:
                raise OSError("injected install failure")
            return replace(source, destination)
        with mock.patch.object(packaging.os, "replace", side_effect=fail_install):
            with self.assertRaises(OSError):
                packaging.build(self.root)
        self.assertEqual(packaging.read_tree(self.root / packaging.MIRROR), before)
        self.assertFalse(packaging.locations(self.root, "0.27.4")[0].exists())
        self.assertEqual(packaging.build(self.root)["contents_parity"], "PASS")

    def test_traversal_and_extra_members_are_rejected(self):
        expected = packaging.inputs(self.root)[1]
        for name in ("../escape.txt", "C:/escape.txt", "unexpected-development-file.txt"):
            with self.subTest(name=name), self.assertRaises(packaging.PackageError):
                packaging.verify_archive(self.archive([*expected.items(), (name, b"unwanted")]), expected)
        self.assertFalse((self.root.parent / "escape.txt").exists())

    def test_missing_duplicate_and_case_collision_are_rejected(self):
        expected = packaging.inputs(self.root)[1]
        first = next(iter(expected))
        for members in (list(expected.items())[1:], [*expected.items(), (first, b"duplicate")],
                        [*expected.items(), (first.upper(), expected[first])]):
            with self.subTest(members=len(members)), self.assertRaises(packaging.PackageError):
                packaging.verify_archive(self.archive(members), expected)

    def test_zip_symlink_is_rejected(self):
        expected = packaging.inputs(self.root)[1]
        members = list(expected.items())
        name, data = members[0]
        link = zipfile.ZipInfo(name)
        link.create_system = 3
        link.external_attr = (stat.S_IFLNK | 0o777) << 16
        path = self.archive([(link, data), *members[1:]])
        with self.assertRaisesRegex(packaging.PackageError, "Linked"):
            packaging.verify_archive(path, expected)

    def test_payload_mismatch_and_crc_damage_are_rejected(self):
        expected = packaging.inputs(self.root)[1]
        changed = list(expected.items())
        changed[0] = (changed[0][0], b"different source bytes")
        with self.assertRaisesRegex(packaging.PackageError, "payload differs"):
            packaging.verify_archive(self.archive(changed), expected)
        path = self.archive(list(expected.items()))
        with zipfile.ZipFile(path) as package:
            entry = package.infolist()[0]
        offset = entry.header_offset + 30 + len(entry.filename.encode()) + len(entry.extra)
        damaged = bytearray(path.read_bytes());damaged[offset] ^= 1;path.write_bytes(damaged)
        with self.assertRaises(packaging.PackageError):
            packaging.verify_archive(path, expected)

    def test_manifest_and_checksum_mismatch_are_rejected(self):
        packaging.build(self.root)
        _, manifest, checksum = packaging.locations(self.root, "0.27.4")
        original = manifest.read_bytes()
        metadata = json.loads(original);metadata["archive_sha256"] = "0" * 64
        manifest.write_text(json.dumps(metadata))
        with self.assertRaisesRegex(packaging.PackageError, "manifest mismatch"):
            packaging.verify(self.root)
        manifest.write_bytes(original)
        checksum.write_text("wrong checksum")
        with self.assertRaisesRegex(packaging.PackageError, "checksum sidecar"):
            packaging.verify(self.root)

    def test_interrupted_output_install_is_recoverable(self):
        original = Path.write_text
        def fail_manifest(path, *args, **kwargs):
            if path.name.endswith(".manifest.json"):
                raise OSError("injected manifest failure")
            return original(path, *args, **kwargs)
        with mock.patch.object(Path, "write_text", side_effect=fail_manifest, autospec=True):
            with self.assertRaises(OSError):
                packaging.build(self.root)
        # An ordinary retry must finish without deleting or replacing an archive.
        self.assertEqual(packaging.build(self.root)["provenance"], "PASS")

    def test_provenance_fields_cannot_be_forged(self):
        packaging.build(self.root)
        _, manifest, _ = packaging.locations(self.root, "0.27.4")
        original = manifest.read_bytes()
        for key, value in (("source_commit", "not-a-commit"), ("builder_sha256", "not-a-hash"),
                           ("source_worktree_dirty", "false"), ("G7", "PASS"), ("G8", "PASS")):
            with self.subTest(field=key):
                metadata = json.loads(original);metadata[key] = value
                manifest.write_text(json.dumps(metadata))
                with self.assertRaises(packaging.PackageError):
                    packaging.verify(self.root)
        manifest.write_bytes(original)

    def test_each_interrupted_install_resumes_identical_outputs(self):
        original = os.link
        for failure_number in (1, 2, 3):
            with self.subTest(failure_number=failure_number):
                # A separate owned fixture avoids sharing versioned outputs.
                other = PackagingTests();other.setUp()
                try:
                    calls = 0
                    def fail_link(source, destination):
                        nonlocal calls
                        calls += 1
                        if calls == failure_number:
                            raise OSError("injected output installation failure")
                        return original(source, destination)
                    with mock.patch.object(packaging.os, "link", side_effect=fail_link):
                        with self.assertRaises(OSError):
                            packaging.build(other.root)
                    outputs = packaging.locations(other.root, "0.27.4")
                    before = {p: p.read_bytes() for p in outputs if p.exists()}
                    self.assertEqual(packaging.build(other.root)["provenance"], "PASS")
                    for path, data in before.items():
                        self.assertEqual(path.read_bytes(), data)
                finally:
                    other.doCleanups()

    def test_well_formed_forged_hash_and_commit_are_rejected(self):
        packaging.build(self.root)
        _, manifest, _ = packaging.locations(self.root, "0.27.4")
        original = manifest.read_bytes()
        for key, value in (("source_commit", "0" * 40), ("builder_sha256", "0" * 64)):
            with self.subTest(field=key):
                metadata = json.loads(original);metadata[key] = value
                manifest.write_text(json.dumps(metadata))
                with self.assertRaises(packaging.PackageError):
                    packaging.verify(self.root)
        manifest.write_bytes(original)

    def test_clean_provenance_must_match_commit_bytes(self):
        self.write("src/ProjectNightfall/42/media/lua/shared/Test.lua", b"return {dirty=true}\n")
        packaging.build(self.root)
        _, manifest, _ = packaging.locations(self.root, "0.27.4")
        metadata = json.loads(manifest.read_text())
        self.assertTrue(metadata["source_worktree_dirty"])
        metadata["source_worktree_dirty"] = False
        manifest.write_text(json.dumps(metadata))
        with self.assertRaisesRegex(packaging.PackageError, "commit bytes"):
            packaging.verify(self.root)

    def test_pending_retry_refuses_a_colliding_output_before_install(self):
        with mock.patch.object(packaging.os, "link", side_effect=OSError("interrupted before ZIP")):
            with self.assertRaises(OSError):
                packaging.build(self.root)
        archive, manifest, _ = packaging.locations(self.root, "0.27.4")
        manifest.write_text("preserve unexpected existing metadata")
        with self.assertRaisesRegex(packaging.PackageError, "refusing artifact overwrite"):
            packaging.build(self.root)
        self.assertFalse(archive.exists())
        self.assertEqual(manifest.read_text(), "preserve unexpected existing metadata")

    def test_clean_windows_text_checkout_is_bound_to_commit(self):
        import subprocess
        subprocess.check_call(["git", "config", "core.autocrlf", "true"], cwd=self.root)
        self.write("src/ProjectNightfall/42/media/lua/shared/Test.lua", b"return {}\r\n")
        # Refresh Git's EOL normalization/stat cache without changing the blob.
        subprocess.check_call(["git", "add", "--renormalize", "src"], cwd=self.root)
        subprocess.check_call(["git", "diff", "--cached", "--exit-code"], cwd=self.root)
        self.assertEqual(packaging.build(self.root)["provenance"], "PASS")
        _, manifest, _ = packaging.locations(self.root, "0.27.4")
        self.assertFalse(json.loads(manifest.read_text())["source_worktree_dirty"])

    def test_unsafe_source_type_and_outside_path_are_rejected(self):
        with self.assertRaises(packaging.PackageError):
            packaging.owned(self.root, "../outside")
        self.write("src/ProjectNightfall/42/injected.jar", b"not allowed")
        with self.assertRaisesRegex(packaging.PackageError, "Unexpected source payload"):
            packaging.plan(self.root)


if __name__ == "__main__":
    unittest.main()
