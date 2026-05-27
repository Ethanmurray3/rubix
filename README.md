# Rubix

Rubix is a Zig and raylib Rubik's Cube visualizer. It uses a compact cubie model for cube state, animates face turns, and renders the cube in 3D with controls that follow the current camera view.

## Requirements

- Zig `0.16.0`
- A desktop environment that can run raylib

## Commands

```sh
zig build
zig build run
zig build cli -- help
zig build cli -- apply "R U R' U'"
zig build cli -- check "R U R' U'"
zig build cli -- invert "R U R' U'"
zig build cli -- scramble --seed 1234
zig build test
zig fmt build.zig src/*.zig test/*.zig
zig fmt --check build.zig src/*.zig test/*.zig
```

## Controls

| Input | Action |
| --- | --- |
| `W` / `S` | Turn the visible up/down faces |
| `D` / `A` | Turn the visible right/left faces |
| `Q` / `E` | Turn the visible front/back faces |
| `Shift` | Make a face turn prime |
| Arrow keys | Rotate the held cube around the current view axes |
| `Z` / `X` | Roll the held cube |
| `C` | Flip the held cube |
| `0` | Reset held-cube orientation |
| `Tab` | Generate, animate, display, and copy a scramble |
| `Space` | Reset cube state |
| Mouse drag | Orbit camera |
| Mouse wheel | Zoom |
| `Esc` | Quit |

## Architecture

- `src/cube.zig` owns the packed `u100` cube state, cubie encoding, move application, and validation. `Cube.bits` is intentionally public as a low-level value-type API for tests, fixtures, and future tooling.
- `src/facelet.zig` owns face/color types, facelet coordinate mapping, and cube-to-sticker color projection. `faceletIndex` is a fast assert-style helper for internal coordinates; `faceletIndexChecked` is available for checked input paths.
- `src/move.zig` owns move enums, move axes, inverse moves, and standard move names.
- `src/scramble.zig` owns scramble generation and scramble shape.
- `src/notation.zig` parses and formats move notation such as `R U R' U'`.
- `src/animation.zig` owns queued turn animation and commits moves only when animations finish.
- `src/render.zig` owns raylib cube drawing plus `Axis` and `Orientation` rendering data.
- `src/camera.zig` owns orbit camera math and view-axis helpers.
- `src/controls.zig` maps keyboard input and held-cube orientation into cube moves.
- `src/ui.zig` owns status strings, face names, and scramble notation formatting.
- `src/gui.zig` owns raylib window setup, frame drawing, and overlay drawing.
- `src/app.zig` owns the GUI app loop and state transitions.
- `src/main.zig` is the small GUI entry point; `zig build run` still launches the raylib app.
- `src/cli.zig` and `src/cli_core.zig` provide the separate `rubix-cli` executable behind `zig build cli -- ...`.
- `src/root.zig` is the package entry point for tests and future library use.

## Audit Decisions

- Move tables stay hand-coded for now. The current risk is mitigated by cube validation, permutation parity checks, and known facelet fixtures for all 18 face turns. A data-driven move-table generator is deferred until solver/search work makes that abstraction earn its keep.
- `Cube.bits` remains public on purpose. Rubix is still a systems-learning project, and the packed value is useful for fixture construction, validation tests, and future CLI/debug tools.
- Facelet indexing now has both forms: `faceletIndex` for trusted internal coordinates and `faceletIndexChecked` for callers that need an error instead of an assertion.

## Roadmap

- Keep hardening the cube core with additional known algorithm fixtures and invalid raw-state fixtures.
- Add GUI algorithm playback through the same move queue used by input.
- Expand CLI output options when concrete workflows need them.
- Defer data-driven move tables until solver or search work needs generated transition data.
- Explore solver work later, starting with a smaller 2x2 search project before full 3x3 solving.
