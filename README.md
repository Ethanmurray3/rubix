# Rubix

Rubix is a Zig and raylib Rubik's Cube visualizer. It uses a compact cubie model for cube state, animates face turns, and renders the cube in 3D with controls that follow the current camera view.

## Requirements

- Zig `0.16.0`
- A desktop environment that can run raylib

## Commands

```sh
zig build
zig build run
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

- `src/cube.zig` owns the packed `u100` cube state, cubie encoding, move application, validation, and facelet projection.
- `src/move.zig` owns move enums, move axes, inverse moves, and standard move names.
- `src/scramble.zig` owns scramble generation and scramble shape.
- `src/notation.zig` parses and formats move notation such as `R U R' U'`.
- `src/animation.zig` owns queued turn animation and commits moves only when animations finish.
- `src/render.zig` owns raylib drawing and held-cube orientation rendering.
- `src/main.zig` owns the app loop, camera, controls, scramble/reset actions, and overlay UI.
- `src/root.zig` is the package entry point for tests and future library use.

## Roadmap

- Keep hardening the cube core with known-case move tests and physical-state invariants.
- Expand notation support into algorithm formatting and inverse algorithms.
- Split presentation-facing facelet helpers out of `cube.zig` when the next feature makes that useful.
- Add CLI commands for applying, checking, scrambling, and inverting algorithms.
- Explore solver work later, starting with a smaller 2x2 search project before full 3x3 solving.
