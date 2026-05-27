# Rubix Project Notes

## Project Goal

Rubix is a polished CFOP trainer product for people learning to solve a Rubik's Cube with Cross, F2L, OLL, and PLL. The product should support real-cube reference practice, virtual-cube interaction, algorithm playback, recognition quizzes, progress tracking, and eventually gamified bot races.

Web is the main future platform. The current Zig/raylib app is a desktop prototype and correctness harness, not the center of the long-term architecture. iOS is a later target after the portable trainer core is stable.

The cube should feel like a modern kids puzzle and speed cube rather than an old-school debug demo. Prefer pastel sticker colors, softer cube edges, a light playful background, and cartoony UI polish that still feels high quality.

Prioritize product quality, maintainability, portability, and learner outcomes. Keep code clear and avoid premature abstractions, but do not preserve learning-project internals when a refactor makes the product easier to ship, test, or extend.

## Current Architecture

- `src/cube.zig` owns packed cube state, cube logic, move application, and validation.
- `src/move.zig` owns move types, move axes, inverse moves, and standard move names.
- `src/scramble.zig` owns scramble shape and generation.
- `src/facelet.zig` owns face/color types, facelet coordinate mapping, and cube-to-sticker color projection.
- `src/notation.zig` owns algorithm parsing and formatting.
- `src/animation.zig` owns pure move-queue animation state, magnetic easing, visual turn progress, and delayed move commits.
- `src/render.zig` owns raylib 3D cube drawing plus `Axis` and `Orientation`.
- `src/camera.zig` owns orbit camera math and view-axis helpers.
- `src/controls.zig` owns keyboard-to-move mapping and held-cube orientation input.
- `src/ui.zig` owns status strings, face names, and scramble notation formatting.
- `src/gui.zig` owns raylib window setup, frame drawing, and overlay drawing.
- `src/app.zig` owns the GUI app loop and state transitions.
- `src/main.zig` is only the GUI entry point.
- `src/cli.zig` and `src/cli_core.zig` own the separate command-line executable and testable command behavior.
- `src/root.zig` is the package module entry point.

Future product modules should move toward:

- `algorithm.zig` for named algorithms, notation display, parsed executable moves, and source metadata.
- `cfop.zig` for stages, look variants, and shared CFOP concepts.
- `cfop_cases.zig` for curated Cross, F2L, OLL, and PLL case definitions.
- `cfop_recognition.zig` for stage and case recognition.
- `cfop_solver.zig` for human-style CFOP solve plans used by teaching, playback, and bots.
- `trainer.zig` for lesson state, drills, prompts, hints, answer checking, and session transitions.
- `progress.zig` for attempts, streaks, best times, mastery state, rewards, and review scheduling.

The cube state is represented as a wrapper around one `u100`:

```zig
pub const Cube = struct {
    bits: u100,
};
```

There is no sticker-array state. Rendering reads colors from the packed cube bits through `facelet.color(...)`.

`Cube.bits` is public for now as a low-level value-type API. Tests, fixtures, and future debug/CLI tools may construct raw states, but product-facing trainer and UI code should prefer clear cube/case APIs instead of exposing packed-bit details. Public raw states must continue to pass `Cube.validate()` before being treated as physical cubes.

Move tables are hand-coded for now. The risk is covered by validation, corner/edge permutation parity checks, and known facelet fixtures for all 18 moves. Generated or data-driven move tables are allowed when they clearly improve correctness, maintainability, CFOP recognition, or solver work.

`facelet.faceletIndex(...)` is the fast assert-style helper for trusted internal coordinates. Use `facelet.faceletIndexChecked(...)` for any path that accepts unchecked coordinates and should return an error instead of asserting.

## Rendering and UI Rules

- Keep raylib as the active desktop rendering backend for now, but do not design new product logic around raylib.
- Rendering must read cube state through `facelet.color(...)`; do not introduce a separate sticker-array source of truth.
- Camera movement and held-cube orientation are UI/render concerns, not cube-state mutations.
- `render.Orientation` changes how the cube is viewed and controlled; it must not call cube move methods or rewrite `Cube.bits`.
- `animation.Animator` queues moves and commits them to `Cube.applyMove(...)` only when the active visual turn finishes.
- `render.drawCube(...)` may receive `?animation.VisualTurn` for temporary moving-layer transforms, but the packed cube bits remain the only committed state.
- Fast face controls are `W/S/D/A/Q/E`, with Shift making the move prime.
- Whole-cube orientation controls should behave like rotating a real cube in hand.
- Any new controls must be reflected in the overlay.
- Avoid visuals that feel like a raw debug demo. Prefer a light blue or playful bright background, soft shadows, friendly UI panels, and modern pastel speed-cube colors.
- Reduce or replace debug grid visuals as the presentation becomes more polished.
- Trainer UI should feel like a shipped learning product: clear, encouraging, fast to scan, and friendly without becoming cluttered or childish.
- Prefer semantic trainer commands such as `start_attempt`, `show_hint`, `submit_move`, `play_algorithm`, `choose_case`, and `mark_case_status` before mapping them to web, raylib, or iOS inputs.
- For the future web app, build the actual trainer as the first screen: cube, CFOP stage, case, algorithm playback, timer, hints, quiz state, and progress.

## Current Animation Behavior

- User face turns are queued and animated one at a time. This preserves cube-state correctness while still making rapid repeated key presses feel responsive.
- Scramble on `Tab` resets to solved, generates a non-mutating `Cube.scramble(...)`, queues the scramble moves, displays the notation, and copies it to the clipboard.
- Magnetic easing currently uses a quick ease-out to a small overshoot, then settles back to the exact target angle before committing the move.
- Default turn durations are tuned for more visible frames: user turns are about `0.16s`, scramble turns are about `0.115s`, and the app requests a high render target FPS while still respecting vsync.
- `VisualTurn.layer_lift` gives the active layer a small bell-shaped outward lift while turning.
- True overlapping physical turns are not implemented yet. Do not start a second physical layer turn before the active move commits unless the renderer is upgraded to handle cubie-level transforms safely.

## Portability Rules

The long-term goal is a web-first shipped product with desktop and iOS paths available when the core is ready.

- Avoid direct OS APIs in core logic.
- Keep cube logic, algorithm parsing, CFOP recognition, trainer sessions, progress, solver planning, animation state, and app state independent from raylib.
- Put platform-specific rendering, audio, window, and input concerns behind thin app-layer boundaries.
- Prefer assets and APIs that can work on web and desktop.
- Treat iOS as a later packaging target. Do not let iOS complexity block a more finished desktop/web-friendly product first.
- Keep native desktop builds working while adding web or mobile build complexity.

## CFOP Content Rules

- Use J Perm's CFOP and algorithm pages as attributed inspiration and reference points for case organization and algorithm choices.
- Do not copy J Perm prose, images, trainer UI, or site data wholesale without a later licensing or permission decision.
- Store Rubix's own curated algorithm data with source links and attribution metadata.
- First shipped learning scope is 2-look OLL and 2-look PLL.
- Add full OLL, full PLL, F2L, and Cross after the 2-look last-layer trainer is useful and tested.
- The computer solver should teach a human-style CFOP path, not merely produce an optimal solve.

## Bit Layout

The cube has 20 physical cubie positions. Each position uses one 5-bit chunk.

Positions are ordered as:

```text
0  ufr    5  drb    10 ub    15 fl
1  urb    6  dbl    11 ul    16 df
2  ubl    7  dlf    12 fr    17 dr
3  ulf    8  uf     13 br    18 db
4  dfr    9  ur     14 bl    19 dl
```

The bit offset for a position is:

```text
offset = position * 5
```

Corner chunk layout:

```text
bits 0..2 = corner piece id
bits 3..4 = corner orientation
```

Corner orientation convention:

```text
0 = the cubie's white/yellow sticker is on an Up/Down face
1 = the cubie is twisted clockwise from orientation 0
2 = the cubie is twisted counterclockwise from orientation 0
```

In code, each corner position lists its three faces with the Up/Down face first. Orientation `1` moves the white/yellow sticker to the third face in that list, and orientation `2` moves it to the second face.

Examples:

```text
UFR faces are [up, front, right]
orientation 0: white/yellow sticker on up
orientation 1: white/yellow sticker on right
orientation 2: white/yellow sticker on front

DFR faces are [down, right, front]
orientation 0: white/yellow sticker on down
orientation 1: white/yellow sticker on front
orientation 2: white/yellow sticker on right
```

Edge chunk layout:

```text
bits 0..3 = edge piece id
bit 4     = edge orientation
```

Edge orientation convention:

```text
0 = normal edge orientation
1 = flipped from normal
```

For edges with white/yellow, normal means the white/yellow sticker is on an Up/Down face when the edge is in an Up/Down slot. For middle-layer edges without white/yellow, normal means the green/blue sticker is on a Front/Back face.

## Move Conventions

Use standard cube notation.

- `U` is clockwise when looking directly at the Up face.
- `U'` is counterclockwise when looking directly at the Up face.
- `D` is clockwise when looking directly at the Down face.
- `D'` is counterclockwise when looking directly at the Down face.
- `R` is clockwise when looking directly at the Right face.
- `R'` is counterclockwise when looking directly at the Right face.
- `L` is clockwise when looking directly at the Left face.
- `L'` is counterclockwise when looking directly at the Left face.
- `F` is clockwise when looking directly at the Front face.
- `F'` is counterclockwise when looking directly at the Front face.
- `B` is clockwise when looking directly at the Back face.
- `B'` is counterclockwise when looking directly at the Back face.

When documenting moves, prefer cubie movement notation:

```text
UF -> UL
```

This means the cubie currently at `UF` moves to `UL`.

Implementation assignments are the reverse form:

```text
UL = old.UF
```

## Cube Logic Rules

- Implement raw bit movement with small helpers such as `getChunk` and `setChunk`.
- Keep move logic readable and well tested. Introduce helper abstractions when they improve correctness, maintainability, generated data, or product work.
- Mutating move methods are preferred:

```zig
pub fn turnU(self: *Cube) void
```

- Inside a mutating move, take an old snapshot first:

```text
old = self.bits
new = old
```

Then read from `old`, write to `new`, and assign `self.bits = new`.

For `U`, `U'`, `D`, and `D'`, move whole 5-bit chunks without changing orientation.

For `R`, `R'`, `L`, and `L'`, move whole edge chunks without flipping edges. Corner chunks must be moved with orientation changes that match `facelet.color(...)`.

For `F`, `F'`, `B`, and `B'`, move corner chunks with orientation changes and flip every moved edge chunk.

Current corner orientation changes:

```text
R:  UFR -> URB (+1), URB -> DRB (+2), DRB -> DFR (+1), DFR -> UFR (+2)
R': UFR -> DFR (+1), DFR -> DRB (+2), DRB -> URB (+1), URB -> UFR (+2)
```

## Near-Term Roadmap

See `PLANS.md` for the full roadmap. The near-term priorities are:

1. Documentation and architecture pivot
   - Keep the repo aligned around a shipped CFOP trainer product.
   - Make product polish, portability, and learner outcomes the default tradeoff.

2. Portable core boundary
   - Keep trainer/session/progress/CFOP logic renderer-free.
   - Isolate raylib-specific rendering, input, and window concerns.

3. Algorithm and case foundation
   - Add named algorithm data with source metadata and parsed executable moves.
   - Extend notation for CFOP algorithm needs such as rotations, slices, wide moves, setup moves, and comments.

4. 2-look OLL/PLL MVP
   - Build reference, drill, recognition quiz, timer, setup, and playback flows.
   - Support both real-cube reference practice and virtual-cube interaction.

5. Full product expansion
   - Add full OLL/PLL, F2L, Cross, gamified progress, bot races, web UI, and later iOS.

## Testing Expectations

- Run `zig build` after code changes.
- Run `zig build test` after changes to cube logic, app logic, parsing, animation state, or solver/trainer code.
- For rendering changes, compile first and do a manual GUI smoke test when practical.
- Future parser tests should cover normal moves, primes, doubles, and invalid tokens.
- Animation tests should cover move queue order, delayed commits, clear/reset behavior, and final visual target angles.
- Future CFOP tests should use known setup and solution fixtures for recognition, algorithm suggestions, and trainer answer checks.
- Trainer/progress tests should cover mode transitions, hint state, timing state, progress updates, rewards, and review scheduling without requiring a renderer.
