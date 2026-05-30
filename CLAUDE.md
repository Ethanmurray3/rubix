# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```sh
zig build                          # compile everything
zig build run                      # launch the raylib desktop app
zig build cli -- help              # CLI help
zig build cli -- apply "R U R' U'" # apply moves to solved cube
zig build cli -- check "R U R' U'" # validate a move sequence
zig build cli -- invert "R U R' U'"
zig build cli -- scramble --seed 1234
zig build test                     # run all tests
zig fmt build.zig src/*.zig test/*.zig          # format
zig fmt --check build.zig src/*.zig test/*.zig  # check format
```

To run a single test file, wire it into `build.zig` (see `addTestFile`) or use `zig test` with explicit imports.

Requires Zig `0.16.0` and a raylib-capable desktop environment.

## Architecture

Two packages:

- **`rubix`** (`src/root.zig`) — the renderer-free portable core. Must never import raylib. This is the target for web and future iOS frontends.
- **`rubix_desktop`** (`src/desktop.zig`) — raylib-specific desktop modules (app, camera, controls, gui, render). Imports both `rubix` and `raylib`.

### Core package modules (`src/root.zig` exports)

| Module | Responsibility |
|---|---|
| `cube.zig` | Packed `u100` cube state, cubie enums, move application, validation |
| `facelet.zig` | Face/color types, facelet coordinate mapping, `color()` projection |
| `move.zig` | Move enums, axes, inverse moves, standard move names |
| `notation.zig` | Algorithm notation parsing and formatting |
| `scramble.zig` | Scramble generation |
| `animation.zig` | Queued turn animation; commits moves to `Cube` only when a visual turn finishes |
| `algorithm.zig` | Named algorithms with display notation, parsed executable moves, source metadata |
| `cfop.zig` | CFOP stages, look variants, shared enums |
| `cfop_cases.zig` | Curated 2-look OLL/PLL case definitions with setup/solution fixtures |
| `cfop_recognition.zig` | AUF-aware case recognition returning solved/known/unsupported |
| `trainer.zig` | `Session` state for reference, drill, and recognition-quiz modes |
| `progress.zig` | Per-case attempts, timing, accuracy, learned status, weak-case ranking |
| `ui.zig` | Status strings, face names, scramble notation formatting |
| `cli_core.zig` | Testable CLI command behavior |

### Desktop package modules

`app.zig` owns the GUI app loop and state. `gui.zig` owns window setup and overlay drawing. `render.zig` owns 3D cube drawing, `Axis`, and `Orientation`. `camera.zig` owns orbit camera math. `controls.zig` maps keyboard input and held-cube orientation to moves.

### Cube state internals

State is a `u100`: 20 cubies × 5 bits each (8 corners, 12 edges). Corner chunks are `[piece_id:3][orientation:2]`; edge chunks are `[piece_id:4][flip:1]`. Corner orientation 0 means the white/yellow sticker faces Up or Down. The bit layout is documented in full in `AGENTS.md`.

`Cube.bits` is public but product-facing trainer and UI code should use the clear cube/case APIs, not packed-bit access. All externally constructed cube states must pass `Cube.validate()`.

`facelet.faceletIndex(...)` asserts on bad coordinates (trusted internal use). `facelet.faceletIndexChecked(...)` returns an error for validated input paths.

### Key invariants

- `src/root.zig` and everything it exports must be raylib-free.
- `animation.Animator` is the only path that calls `Cube.applyMove(...)` from the desktop frontend; never commit moves directly from render/input code.
- Rendering reads cube colors only through `facelet.color(...)`; there is no separate sticker-array state.
- `render.Orientation` is a view/control concern only — it must never mutate `Cube.bits`.
- Move tables are hand-coded; do not replace them without keeping the full validation/fixture suite green.

### Notation

`notation.zig` parses and formats move sequences (e.g. `R U R' U'`). Face turns and rotations are executable. Slice and wide move tokens are parsed for display but executable expansion is not yet implemented — do not assume they will apply to a `Cube`.

## Testing

- `zig build test` after any changes to cube logic, notation, animation, CFOP recognition, trainer state, or progress.
- CFOP tests use exact setup/solution cube-state fixtures; keep those fixtures passing.
- Trainer and progress tests must not import raylib.
- Desktop rendering changes: compile first, then manual raylib smoke test.

## Product Direction

First shipped scope is the 2-look OLL/PLL trainer (reference, drill, recognition quiz, timer, hints, progress). Web is the primary future platform; the raylib desktop app is a prototype harness. iOS is a later target. See `PLANS.md` for the full roadmap.

J Perm's CFOP pages are the curriculum reference. Store Rubix's own curated algorithm data with attribution metadata; do not copy J Perm's prose, images, or UI wholesale.
