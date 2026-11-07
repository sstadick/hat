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

### Nightly source checkout

The `nightly` branch builds Hat with **Mojo 1.3.0.dev2026110705** from
`https://conda.modular.com/max-nightly` and pins mojopt to
[`c102cbf55b237f021e061affd91ee02322b85e49`](https://github.com/sstadick/mojopt/commit/c102cbf55b237f021e061affd91ee02322b85e49).
That dependency is published on mojopt's nightly branch, not yet released on
stable; promotion depends on [mojopt PR #11](https://github.com/sstadick/mojopt/pull/11)
landing and the final pins being retested.
From this branch, use `pixi install --locked` for development. To install it:

```bash
pixi global install \
  --channel conda-forge \
  --channel https://conda.modular.com/max-nightly \
  --channel https://repo.prefix.dev/modular-community \
  --path .
```

Generated projects still default to stable Mojo 1.1.0; use `hat new --nightly`
to select the latest published nightly compiler for a new project. Generated
`pixi.toml` files keep development and package build/host/run constraints aligned:
`=1.1.0` by default, or `*` with the nightly channel. Commit the generated
`pixi.lock` to freeze the resolved compiler; check it with `pixi run mojo --version`.

## Usage

```bash
# Create a new binary project
hat new --name mojo-grep

# Create a new lib project
hat new --lib --name amazing-lib

# Track the latest nightly compiler instead of stable Mojo 1.1.0
hat new --nightly --name nightly-project

# Build project (defaults to release build)
hat build 

# Build with debug and asserts on
hat build --debug

# Test your project
hat test
```

Hat 0.5.0 and generated projects use stable Mojo 1.1.0 by default, require Pixi 0.76 or newer, and rely on the [`pixi-build-mojo`](https://prefix-dev.github.io/pixi-build-backends/backends/pixi-build-mojo) backend. Library names such as `amazing-lib` are mapped to importable Mojo package names such as `amazing_lib`.

Libraries and packages created this way can be used through Git paths and do not need to be published on Conda. To publish on [modular-community](https://github.com/modular/modular-community), create a `recipe.yaml` and follow that repository's publishing process. Automatic recipe generation remains on Hat's roadmap.

> [!Warning]
> Since `hat` relies on `pixi.toml` and its generated `t` task, changing that task may break `hat test`.

## Future directions

- Reduce reliance on pixi the cli tool, add bindings to the core pixi libs and call them directly.

## TODOs

- Add a `generate-recipe` subcommand to export a recipe that can be used for rattler
- Add some ENV VARS to the build env that `hat` uses such as project version, project name, etc by parsing the pixi toml file. This allows CLI tools to pull those in at comptime.
