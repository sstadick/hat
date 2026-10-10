from std.pathlib import Path
from std.tempfile import TemporaryDirectory
from std.testing import assert_false, assert_true, TestSuite

from hatlib.subcommands.new import (
    UserInfo,
    create_bin_structure,
    create_lib_structure,
    create_test_structure,
    pick_channel,
    pick_mojo_version,
    write_gitignore,
    write_pixi_toml,
)


def test_generated_manifests() raises:
    for nightly in [False, True]:
        for is_lib in [False, True]:
            with TemporaryDirectory() as tempdir:
                var root = Path(tempdir)
                var user = UserInfo("CI", "ci@example.com")
                write_pixi_toml(
                    root,
                    user,
                    pick_channel(nightly),
                    pick_mojo_version(nightly),
                    "example-project",
                    "example_project",
                    is_lib,
                )
                var contents = open(root / "pixi.toml", "r").read()
                var version = pick_mojo_version(nightly)
                assert_true('[package.host-dependencies]\nmojo-compiler = "' + version in contents)
                assert_true('[package.build-dependencies]\nmojo-compiler = "' + version in contents)
                assert_true('[package.run-dependencies]\nmojo-compiler = "' + version in contents)
                assert_true('[dependencies]\nmojo = "' + version in contents)
                assert_true(pick_channel(nightly) in contents)
                assert_false("1.0.0" in contents)
                assert_true('"linux-aarch64"' in contents)
                if is_lib:
                    assert_true('[package.build.config.pkg]\nname = "example_project"' in contents)
                    assert_false('r = "mojo run main.mojo"' in contents)
                else:
                    assert_true(
                        '[[package.build.config.bins]]\nname = "example-project"' in contents
                    )
                    assert_true('r = "mojo run main.mojo"' in contents)


def test_generated_sources() raises:
    with TemporaryDirectory() as tempdir:
        var root = Path(tempdir)
        create_bin_structure(root)
        create_test_structure(root, "example", False)
        assert_true("def main() raises:" in open(root / "main.mojo", "r").read())
        assert_true(
            "TestSuite.discover_tests" in open(root / "tests/test_example.mojo", "r").read()
        )

    with TemporaryDirectory() as tempdir:
        var root = Path(tempdir)
        create_lib_structure(root, "example_lib")
        create_test_structure(root, "example_lib", True)
        write_gitignore(root)
        assert_true((root / "example_lib/__init__.mojo").exists())
        assert_true("def pull_rabbit()" in open(root / "example_lib/lib.mojo", "r").read())
        assert_true(
            "from example_lib.lib import pull_rabbit"
            in open(root / "tests/test_example.mojo", "r").read()
        )
        var ignored = open(root / ".gitignore", "r").read()
        assert_true("*.mojoc" in ignored)
        assert_false("*.mojopkg" in ignored)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
