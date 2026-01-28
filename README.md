# hat 🎩

A thin wrapper over pixi to make common mojo related task easier.

## Usage

```
# Create a new binary project
hat new --name mojo-grep --nightly

# Create a new lib project
hat new --lib --nightly --name amazing-lib

# Build project (defaults to release build)
hat build 

# Build with debug and asserts on
hat build --debug

# Test your project
hat test
```

Note that this sets up a fully functioning pixi project under. There is no magic here, you can look at the pixi.toml and fall back to running pixi / mojo commands as needed. 

> [!Warning]
> Since `hat` relies on the pixi.toml, and some task defined there, changing any of the pre-defined tasks may break `hat`.

## Known issues

- Some of the text-forwarding from running pixi commands gets odd re-formatting.

## Future directions

- Reduce reliance on pixi the cli tool, add bindings to the core pixi libs and call them directly.
