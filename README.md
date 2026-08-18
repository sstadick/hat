# hat 🎩

A thin wrapper over Pixi that makes common Mojo project tasks easier.

## Install

```
pixi self-update --no-release-note

pixi global install \
  --channel conda-forge \
  --channel https://conda.modular.com/max \
  --channel https://repo.prefix.dev/modular-community \
  --git https://github.com/sstadick/hat

# Add the pixi dir to your path
export PATH="$HOME/.pixi/bin:$PATH"
```

## Usage

```bash
# Create a new binary project
hat new --name mojo-grep

# Create a new lib project
hat new --lib --name amazing-lib

# Track the latest nightly compiler instead of stable Mojo 1.0.0
hat new --nightly --name nightly-project

# Build project (defaults to release build)
hat build 

# Build with debug and asserts on
hat build --debug

# Test your project
hat test
```

Generated projects use stable Mojo 1.0.0 by default, require Pixi 0.76 or newer, and rely on the [`pixi-build-mojo`](https://prefix-dev.github.io/pixi-build-backends/backends/pixi-build-mojo) backend. Library names such as `amazing-lib` are mapped to importable Mojo package names such as `amazing_lib`.

Libraries and packages created this way can be used through Git paths and do not need to be published on Conda. To publish on [modular-community](https://github.com/modular/modular-community), create a `recipe.yaml` and follow that repository's publishing process. Automatic recipe generation remains on Hat's roadmap.

> [!Warning]
> Since `hat` relies on `pixi.toml` and its generated `t` task, changing that task may break `hat test`.

## Future directions

- Reduce reliance on pixi the cli tool, add bindings to the core pixi libs and call them directly.

## TODOs

- Add a `generate-recipe` subcommand to export a recipe that can be used for rattler
- Add some ENV VARS to the build env that `hat` uses such as project version, project name, etc by parsing the pixi toml file. This allows CLI tools to pull those in at comptime.
