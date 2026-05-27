# Rubix

Rubix is becoming a polished CFOP trainer for learning Cross, F2L, OLL, and PLL. The current repo contains a portable cube engine, notation helpers, and a Zig/raylib desktop prototype that animates a 3D cube and provides a useful correctness harness while the product moves toward a web-first trainer experience.

See [PLANS.md](PLANS.md) for the product roadmap, MVP scope, content policy, and future architecture direction.

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

## Product Direction

Rubix should become a shipped learning product, not a debug visualizer. The first product milestone is a 2-look OLL/PLL trainer with reference views, setup states, algorithm playback, recognition quizzes, timers, and basic progress tracking. Later milestones add full OLL/PLL, F2L and Cross lessons, gamified practice, real-cube reference flows, bot races, web delivery, and eventually iOS.

J Perm's CFOP and algorithm pages are the main reference for curriculum organization and algorithm selection, with attribution. Rubix should maintain its own curated algorithm data and should not copy site prose, images, or UI wholesale without a separate licensing decision.

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

- `src/cube.zig` owns the packed `u100` cube state, cubie encoding, move application, and validation. Product-facing trainer code should prefer clear cube/case APIs over direct packed-bit access.
- `src/facelet.zig` owns face/color types, facelet coordinate mapping, and cube-to-sticker color projection. `faceletIndex` is a fast assert-style helper for internal coordinates; `faceletIndexChecked` is available for checked input paths.
- `src/move.zig` owns move enums, move axes, inverse moves, and standard move names.
- `src/scramble.zig` owns scramble generation and scramble shape.
- `src/notation.zig` parses and formats move notation such as `R U R' U'`.
- `src/animation.zig` owns queued turn animation and commits moves only when animations finish.
- `src/root.zig` exports the pure `rubix` package. It should stay renderer-free so web, desktop, CLI, tests, and future iOS frontends share the same product logic.
- Future `algorithm`, `cfop`, `cfop_cases`, `cfop_recognition`, `trainer`, `progress`, and `cfop_solver` modules should remain renderer-free.
- `src/desktop.zig` exports the current raylib desktop frontend modules.
- `src/render.zig` owns raylib cube drawing plus `Axis` and `Orientation` rendering data for the current desktop prototype.
- `src/camera.zig` owns orbit camera math and view-axis helpers for the current desktop prototype.
- `src/controls.zig` maps keyboard input and held-cube orientation into cube moves for the current desktop prototype.
- `src/ui.zig` owns status strings, face names, and scramble notation formatting.
- `src/gui.zig` owns raylib window setup, frame drawing, and overlay drawing.
- `src/app.zig` owns the GUI app loop and state transitions.
- `src/main.zig` is the small GUI entry point; `zig build run` still launches the raylib app.
- `src/cli.zig` and `src/cli_core.zig` provide the separate `rubix-cli` executable behind `zig build cli -- ...`.
- `rubix_desktop` is the separate package entry point for raylib-specific tests and desktop code.

## Audit Decisions

- Move tables stay hand-coded for now. The current risk is mitigated by cube validation, permutation parity checks, and known facelet fixtures for all 18 face turns. A data-driven move-table generator is deferred until solver/search work makes that abstraction earn its keep.
- `Cube.bits` remains public for now because it is useful for fixture construction, validation tests, and tooling. Product code should not leak packed-bit details into trainer UI or progress APIs.
- Facelet indexing now has both forms: `faceletIndex` for trusted internal coordinates and `faceletIndexChecked` for callers that need an error instead of an assertion.

## Roadmap

- Add `PLANS.md`-driven CFOP product modules for algorithms, cases, recognition, trainer sessions, progress, and CFOP-style solve plans.
- Build the first shipped learning loop around 2-look OLL and 2-look PLL.
- Keep the cube engine and trainer/session logic portable and independent from raylib.
- Use the current raylib app as a prototype frontend while the product moves toward a web-first trainer.
- Add web and later iOS frontends once the core trainer API is stable.
