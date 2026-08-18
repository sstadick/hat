from std.testing import assert_equal, TestSuite
from std.pathlib import Path

from hatlib.project import get_module_name, get_project_name
from hatlib.subcommands.new import pick_channel, pick_mojo_version


def test_dummy() raises:
    assert_equal("a", "a")


def test_project_names() raises:
    assert_equal(get_project_name(Path(".")), "hat")
    assert_equal(get_module_name("amazing-lib"), "amazing_lib")


def test_project_channels() raises:
    assert_equal(pick_channel(False), "https://conda.modular.com/max")
    assert_equal(pick_channel(True), "https://conda.modular.com/max-nightly")
    assert_equal(pick_mojo_version(False), "=1.0.0")
    assert_equal(pick_mojo_version(True), "*")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
