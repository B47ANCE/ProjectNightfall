"""Source/release audit policy. Historical evidence never becomes current proof."""
from collections import Counter
from pathlib import Path
import re
import subprocess


def placeholders(value: str) -> Counter:
    # PZ numbered substitutions and printf-style fields; ignore escaped %%.
    return Counter(re.findall(r"%[1-9]\d*|%[-+0 #]*\d*(?:\.\d+)?[cdeEfgGiouXxs]",
                              value.replace("%%", "")))


def localization_value_errors(expected: dict, values: dict) -> list[str]:
    errors = []
    if set(values) != set(expected):
        errors.append("English key parity differs")
    for key, value in values.items():
        if not isinstance(value, str) or not value.strip():
            errors.append(f"{key}: empty or non-string translation")
        elif key in expected and placeholders(value) != placeholders(expected[key]):
            errors.append(f"{key}: substitution placeholders differ")
    return errors


def historical_mirror(root: Path, inventory: dict) -> dict:
    mirror = inventory.get("packaging_mirror", {})
    if mirror.get("use_for_release", True):
        return {"status": "CURRENT", "errors": []}
    path, expected = mirror.get("path", ""), mirror.get("git_tree", "")
    if (not path or Path(path).is_absolute() or ".." in Path(path).parts
            or not re.fullmatch(r"[0-9a-f]{40}", expected)):
        return {"status": "FAIL", "errors": ["Historical mirror lacks safe path/pinned Git tree"]}
    def git(*args):
        return subprocess.check_output(["git", *args], cwd=root, text=True, encoding="utf-8").strip()
    errors = []
    try:
        if git("rev-parse", f"HEAD:{path}") != expected:
            errors.append("Historical mirror committed tree differs")
        if git("diff", "HEAD", "--", path):
            errors.append("Historical mirror index/worktree differs")
        if git("ls-files", "--others", "--exclude-standard", "--", path):
            errors.append("Historical mirror contains untracked files")
        # Ignored extras also cannot silently enter a retained mirror.
        if git("ls-files", "--others", "--ignored", "--exclude-standard", "--", path):
            errors.append("Historical mirror contains ignored files")
    except subprocess.CalledProcessError:
        errors.append("Historical mirror Git evidence unavailable")
    return {"status": "FAIL" if errors else "PASS", "git_tree": expected, "errors": errors,
            "scope": "Retained Git tree plus index/worktree; line-ending normalization allowed by Git"}


def failure_reasons(report: dict, release: bool = False) -> list[str]:
    failures = []
    checks = {
        "dependency contracts": report["dependency_contracts"]["direct_errors"] or report["dependency_contracts"]["transitive_errors"],
        "case collisions": report["case_collisions"],
        "localization": report["localization"]["key_parity_errors"],
        "family require paths": report["requires"]["family_module_errors"],
        "Lua-only runtime": report["non_lua_runtime_dependencies"],
        "Lua syntax": report["syntax"].get("errors") or "NOT TESTED" in report["syntax"].get("status", ""),
        "protected historical mirror": report["historical_mirror"]["errors"],
        "source package inputs": report["package_inputs"].get("error"),
        "operation protection baseline": report.get("protected_files_changed"),
        "Git index private/generated paths": report["index_audit"]["denied_paths"],
        "Git index potential secrets": report["index_audit"]["potential_secret_paths"],
    }
    for label, failed in checks.items():
        if failed:
            failures.append(label)
    for item in report["current_directory_archives"]:
        if (item["errors"] or item["classification"] == "unclassified"
                or (item["classification"] != "historical" and item.get("source_differences"))):
            failures.append("archive integrity/classification: " + item["path"])
    if release:
        if report["copy_missing"] or report["copy_extra"] or report["copy_changed"]:
            failures.append("current Contents parity")
        if report["package_validation"].get("error"):
            failures.append("current package validation")
    return failures
