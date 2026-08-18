from std.os import mkdir, makedirs
from std.pathlib import Path
from std.subprocess import run

from mojopt.command import Commandable
from mojopt.default import reflection_default
from mojopt.deserialize import MojOptDeserializable, Opt

from hatlib.project import get_module_name
from hatlib.subprocess import POpenHandle

comptime NIGHTLY_CHANNEL = "https://conda.modular.com/max-nightly"
comptime STABLE_CHANNEL = "https://conda.modular.com/max"
comptime STABLE_MOJO_VERSION = "=1.0.0"


@fieldwise_init
struct UserInfo(Copyable, Movable):
    var username: String
    var email: String


def pixi_install(project_dir: Path) raises:
    var cmd = String(t"pixi install --no-progress --manifest-path {project_dir}/pixi.toml")
    var handle = POpenHandle[True](cmd)
    for line in handle:
        print(line, end="")
    var retcode = handle.close()
    if retcode != 0:
        raise Error("Failed to install deps.")


def get_user_and_email(project_dir: Path) raises -> UserInfo:
    var git_dir = String(project_dir)
    var email = run("git -C {} config user.email".format(git_dir))
    var username = run("git -C {} config user.name".format(git_dir))
    return UserInfo(username^, email^)


def pick_channel(nightly: Bool) -> String:
    if not nightly:
        return STABLE_CHANNEL
    else:
        return NIGHTLY_CHANNEL


def pick_mojo_version(nightly: Bool) -> String:
    if nightly:
        return "*"
    return STABLE_MOJO_VERSION


def create_lib_structure(project_dir: Path, module_name: String) raises:
    makedirs(project_dir / module_name, exist_ok=True)
    touch(project_dir / module_name / "__init__.mojo")
    var fh = open(project_dir / module_name / "lib.mojo", "w")
    fh.write_bytes(LIB_TEMPLATE.as_bytes())


def create_bin_structure(project_dir: Path) raises:
    var fh = open(project_dir / "main.mojo", "w")
    fh.write_bytes(MAIN_TEMPLATE.as_bytes())


def touch(path: Path) raises:
    _ = open(path, "a")


def write_gitignore(project_dir: Path) raises:
    var fh = open(project_dir / ".gitignore", "w")
    fh.write_bytes(GITIGNORE_TEMPLATE.as_bytes())


def create_test_structure(project_dir: Path, module_name: String, is_lib: Bool) raises:
    mkdir(project_dir / "tests")
    var fh = open(project_dir / "tests" / "test_example.mojo", "w")
    if is_lib:
        var test_contents = LIB_TEST_TEMPLATE.format(module_name)
        fh.write_bytes(test_contents.as_bytes())
    else:
        fh.write_bytes(BIN_TEST_TEMPLATE.as_bytes())


def write_pixi_toml(
    project_dir: Path,
    user_info: UserInfo,
    channel: String,
    mojo_version: String,
    project_name: String,
    module_name: String,
    is_lib: Bool,
) raises:
    var build_config: String
    var run_task: String
    if is_lib:
        build_config = LIB_BUILD_CONFIG_TEMPLATE.format(module_name, module_name)
        run_task = "# Library projects do not define a run task."
    else:
        build_config = BIN_BUILD_CONFIG_TEMPLATE.format(project_name)
        run_task = RUN_TASK_TEMPLATE

    var pixi_contents = PIXI_TEMPLATE.format(
        user_info.username,
        user_info.email,
        channel,
        project_name,
        build_config,
        mojo_version,
        mojo_version,
        mojo_version,
        run_task,
        mojo_version,
        project_name,
    )

    var fh = open(project_dir / "pixi.toml", "w")
    fh.write_bytes(pixi_contents.as_bytes())


@fieldwise_init
struct New(Commandable, Defaultable, MojOptDeserializable, Writable):
    comptime name = "new"

    @staticmethod
    def description() -> String:
        return """Create a new Mojo project.
            For further documentation on Mojo project structure, see https://prefix-dev.github.io/pixi-build-backends/backends/pixi-build-mojo/#project-structure-examples."""

    def __init__(out self):
        self = reflection_default[Self]()

    var project_name: Opt[
        String,
        short="n",
        long="name",
        help="The name of the project, also used to create a directory.",
    ]
    var location: Opt[
        String,
        short="l",
        default_value=["."],
        help="Location to create the project",
    ]
    var nightly: Opt[
        Bool,
        help="Create a project relying on the latest nightly Mojo.",
        default_value=["False"],
    ]
    var lib: Opt[
        Bool,
        help="Create a project structure for a Mojo library.",
        default_value=["False"],
    ]

    def run(self) raises:
        var channel = pick_channel(self.nightly.value)
        var mojo_version = pick_mojo_version(self.nightly.value)
        var location = Path(self.location.value)
        var project_name = self.project_name.value
        var module_name = get_module_name(project_name)

        # Create the directory
        var project_dir = location / project_name
        mkdir(project_dir)

        # Git init and find user info
        _ = run("git init -b main {}".format(String(project_dir)))

        var user_info = get_user_and_email(project_dir)

        # Fill in `pixi.toml` template
        write_pixi_toml(
            project_dir,
            user_info,
            channel,
            mojo_version,
            project_name,
            module_name,
            self.lib.value,
        )
        write_gitignore(project_dir)

        if self.lib.value:
            create_lib_structure(project_dir, module_name)
        else:
            create_bin_structure(project_dir)
        create_test_structure(project_dir, module_name, self.lib.value)
        pixi_install(project_dir)


comptime PIXI_TEMPLATE = """[workspace]
authors = ["{} <{}>"]
channels = [
    "https://prefix.dev/conda-forge",
    "{}",
    "https://repo.prefix.dev/modular-community",
]
platforms = ["linux-64", "linux-aarch64", "osx-arm64"]
preview = ["pixi-build"]
requires-pixi = ">=0.76"

[package]
name = "{}"
version = "0.1.0"

[package.build]
backend = {{ name = "pixi-build-mojo", version = "0.*", channels = [
    "https://prefix.dev/pixi-build-backends",
    "https://prefix.dev/conda-forge",
] }}
{}

[package.host-dependencies]
mojo-compiler = "{}"

[package.build-dependencies]
mojo-compiler = "{}"

[package.run-dependencies]
mojo-compiler = "{}"

[tasks]
{}
t = {{ cmd = "sh -c 'find ./tests -name test_*.mojo | xargs -I % mojo run -I . -D ASSERT=all %'" }}
format = "mojo format --line-length 100 ."

[target.linux-64.tasks]
# Mojo 1.0 may select AVX-512 on CI runners whose hosts do not expose it.
t = {{ cmd = "sh -c 'find ./tests -name test_*.mojo | xargs -I % mojo run --target-features=-avx512f,-avx512bw,-avx512cd,-avx512dq,-avx512vl,-avx512ifma,-avx512vbmi,-avx512vbmi2,-avx512vnni,-avx512bitalg,-avx512vpopcntdq,-avx512fp16,-avx512bf16 -I . -D ASSERT=all %'" }}

[dependencies]
mojo = "{}"
{} = {{ path = "." }}
"""

comptime BIN_BUILD_CONFIG_TEMPLATE = (
    '[[package.build.config.bins]]\nname = "{}"\npath = "main.mojo"'
)

comptime LIB_BUILD_CONFIG_TEMPLATE = '[package.build.config.pkg]\nname = "{}"\npath = "{}"'

comptime RUN_TASK_TEMPLATE = 'r = "mojo run main.mojo"'

comptime MAIN_TEMPLATE = """def main() raises:
    print("🎩🪄🐇")
"""

comptime LIB_TEMPLATE = """def pull_rabbit() -> String:
    return "🐇"
"""

comptime BIN_TEST_TEMPLATE = """from std.testing import assert_equal, TestSuite


def test_example() raises:
    assert_equal("🎩", "🎩")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
"""

comptime LIB_TEST_TEMPLATE = """from std.testing import assert_equal, TestSuite

from {}.lib import pull_rabbit


def test_pull_rabbit() raises:
    assert_equal(pull_rabbit(), "🐇")


def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
"""

comptime GITIGNORE_TEMPLATE = """# pixi environments
.pixi/
!.pixi/config.toml

# hat
target/

# Mojo packages
*.mojoc
*.mojopkg
"""
