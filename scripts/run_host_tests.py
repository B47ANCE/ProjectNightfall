"""Run Nightfall's existing host tests in isolated Lua 5.1 interpreters.

Requires Python 3 and lupa (Lua 5.1 build). This is offline validation, never
Project Zomboid, native Kahlua, multiplayer, deployment, or release evidence.
Sibling dependency checkouts are read from --dependencies (default: parent).
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LUA = Path("src/ProjectNightfall/42/media/lua")
SHARED = LUA / "shared"
MODULE = SHARED / "ProjectNightfall"
CLIENT = LUA / "client/ProjectNightfall"
ARGUMENTS = {
    "ai_boundaries": [MODULE / "PN_Config.lua"],
    "artificial_uv": [MODULE / "PN_ArtificialUV.lua"],
    "build_effigy_action": [MODULE / "PN_BuildEffigyAction.lua"],
    "dependency_diagnostics": [MODULE / "PN_DependencyDiagnostics.lua"],
    "ecosystem_test": [CLIENT / "PN_EcosystemTest.lua"],
    "effigies": [MODULE / "PN_Effigies.lua"],
    "effigy_menu": [CLIENT / "PN_EffigyMenu.lua"],
    "event_boundaries": [MODULE / "PN_ZombieUV.lua"],
    "fake_dead_transition": [MODULE / "PN_ZombieUV.lua"],
    "feral_reserve": [MODULE / "PN_FeralReserve.lua"],
    "guided_test": [CLIENT / "PN_GuidedTest.lua"],
    "lifecycle_rules": [MODULE / "PN_LifecycleRules.lua"],
    "lightworks_uv_contract": [MODULE / "PN_FlashlightBulbs.lua"],
    "mortis_integration": [MODULE / "PN_MortisIntegration.lua"],
    "natural_uv_health": [MODULE / "PN_NaturalUVHealth.lua"],
    "night_transition": [MODULE / "PN_NightTransition.lua"],
    "rise_source_contract": [MODULE / "PN_ZombieUV.lua"],
    "sandbox_contract": [Path("src/ProjectNightfall/42/media/sandbox-options.txt"),
                         SHARED / "Translate/EN/Sandbox.json", SHARED / "Sandbox/Nightfall.lua",
                         SHARED / "Sandbox/NightfallNoFerals.lua", MODULE / "PN_Config.lua"],
    "sandbox_ownership": [SHARED / "Sandbox/Nightfall.lua", MODULE / "PN_Config.lua"],
    "state_persistence": [MODULE / "PN_StatePersistence.lua"],
    "testkit": [CLIENT / "PN_TestKit.lua"],
    "uv_metabolism": [MODULE / "PN_UVMetabolism.lua"],
    "uv_migration_contract": [SHARED],
}
DEPENDENCIES = {entry["folder"]: entry["mod_id"] for entry in
                json.loads((ROOT / "SOURCE_INVENTORY.json").read_text())["dependency_sources"]}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dependencies", type=Path, default=ROOT.parent)
    parser.add_argument("--only", nargs="+", help="Test paths relative to the project root")
    parser.add_argument("--legacy-only", action="store_true", help="Run only the original top-level suite")
    parser.add_argument("--verbose", action="store_true", help="Show successful tests' Lua output")
    options = parser.parse_args()
    try:
        from lupa.lua51 import LuaRuntime
    except ImportError:
        parser.error("lupa.lua51 is required; install lupa in the selected Python environment")
    dependencies = options.dependencies.resolve()
    roots = [ROOT / LUA / side for side in ("shared", "client", "server")]
    for folder, mod_id in DEPENDENCIES.items():
        base = dependencies / folder / "src" / mod_id / "42/media/lua"
        if not base.is_dir():
            parser.error(f"Missing source dependency: {base}")
        roots.extend(base / side for side in ("shared", "client", "server"))
    search_path = ";".join(str(base / "?.lua").replace("\\", "/") for base in roots)
    discovery = (ROOT / "tests").glob if options.legacy_only else (ROOT / "tests").rglob
    tests = [ROOT / name for name in options.only] if options.only else sorted(discovery("test_*.lua"))
    if not tests:
        parser.error("No tests selected")
    failures = []
    original_cwd = Path.cwd()
    os.chdir(ROOT)
    try:
        for test in tests:
            test = test.resolve()
            if not test.is_file() or not test.is_relative_to(ROOT / "tests"):
                parser.error(f"Not a project test file: {test}")
            lua = LuaRuntime(unpack_returned_tuples=True)
            messages = []
            lua.globals().print = lambda *values: messages.append(" ".join(map(str, values)))
            lua.globals().package.path = search_path + ";" + lua.globals().package.path
            # The debug-surface test uses explicit ../family/... paths. Resolve
            # only those declared dependency folders through --dependencies too;
            # never alias a renamed production namespace or substitute a mock.
            lua.globals()._testDependencyRoot = dependencies.as_posix()
            lua.globals()._testDependencyFolders = lua.table_from({name: True for name in DEPENDENCIES})
            lua.execute('''local originalLoadfile=loadfile
                loadfile=function(path)
                    if type(path)=="string" and path:sub(1,3)=="../" then
                        local folder=path:match("^%.%./([^/]+)/")
                        if _testDependencyFolders[folder] then path=_testDependencyRoot.."/"..path:sub(4) end
                    end
                    return originalLoadfile(path)
                end''')
            args = ARGUMENTS.get(test.stem.removeprefix("test_"), [])
            lua.globals().arg = lua.table_from([str(ROOT / path).replace("\\", "/") for path in args])
            # Existing debug tests need debug mode; the release-gate test
            # explicitly overrides this to verify inert non-debug loading.
            lua.execute("isDebugEnabled=function() return true end")
            try:
                lua.execute(test.read_text(encoding="utf-8-sig"), name=str(test.relative_to(ROOT)))
                if options.verbose:
                    print("\n".join(messages))
                print(f"PASS {test.relative_to(ROOT).as_posix()}", flush=True)
            except Exception as error:
                failures.append(test)
                print("\n".join(messages))
                print(f"FAIL {test.relative_to(ROOT).as_posix()}: {error}", flush=True)
    finally:
        os.chdir(original_cwd)
    print(f"Offline Lua 5.1: {len(tests) - len(failures)}/{len(tests)} passed; {len(failures)} failed.")
    return int(bool(failures))


if __name__ == "__main__":
    raise SystemExit(main())
