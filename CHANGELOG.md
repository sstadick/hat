# CHANGELOG

## v0.5.0

- chore: update Hat and generated stable projects to Mojo 1.1.0
- chore: pin MojOpt 0.5.0, which supports Mojo 1.1.0
- fix: use the current C-string span and pointer APIs for subprocess calls
- chore: stop generating the obsolete `.mojopkg` ignore entry
- test: validate project generation, subprocesses, and end-to-end builds on all supported platforms

## v0.4.0

- chore: update Hat and generated stable projects to Mojo 1.0.0
- chore: update MojOpt and remove the unused ExtraMojo dependency
- fix: build libraries with `mojo precompile` and the `.mojoc` format
- fix: generate valid underscore module names for dashed library projects
- fix: let nightly projects resolve from the nightly channel instead of pinning a stable compiler
- chore: require a current Pixi/build-backend stack and add Linux AArch64 to generated projects

## v0.3.0

- chore: update Hat to Mojo 1.0.0b1
- chore: use stable Modular channel and packaged ExtraMojo 0.22.0
- fix: update Mojo syntax and iterator code for current compiler behavior
- fix: pin pixi CI/build backend to the API-3-compatible build path

## v0.2.0

- fix: properly run pixi install for new projects
- fix: no double newlines when printing pixi install, hat test, and hat build
- feat: switch to mojopt
