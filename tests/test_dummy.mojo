from testing import assert_equal, TestSuite


def test_dummy():
    assert_equal("a", "a")


def main():
    TestSuite.discover_tests[__functions_in_module()]().run()
