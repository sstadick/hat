from std.testing import assert_equal, assert_raises, TestSuite

from hatlib.subprocess import POpenHandle, run


def test_run_output() raises:
    var result = run("printf 'hello\\nworld\\n'")
    assert_equal(result.stdout, "hello\nworld")
    assert_equal(result.returncode, 0)
    result.check()


def test_run_failure_and_stderr() raises:
    var result = run("sh -c \"printf 'failure\\n' >&2; exit 7\"")
    assert_equal(result.stdout, "failure")
    assert_equal(result.returncode, 7)
    with assert_raises(contains="exit code 7"):
        result.check()


def test_line_iteration() raises:
    var handle = POpenHandle("printf 'first\\n\\na longer final line'")
    var lines = List[String]()
    for line in handle:
        lines.append(line)
    assert_equal(lines, ["first\n", "\n", "a longer final line"])
    assert_equal(handle.close(), 0)


def test_empty_output() raises:
    var handle = POpenHandle("true")
    var count = 0
    for _ in handle:
        count += 1
    assert_equal(count, 0)
    assert_equal(handle.close(), 0)


def test_tty_output() raises:
    var result = run[mimic_tty=True]("printf 'hat-tty\\n'")
    assert_equal(result.stdout, "hat-tty")
    assert_equal(result.returncode, 0)


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
