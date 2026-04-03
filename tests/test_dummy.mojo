from std.testing import assert_equal, TestSuite


def test_dummy() raises:
    assert_equal("a", "a")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
