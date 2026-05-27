# Rubix Project Notes

## Project Goal

Rubix is a Zig learning project focused on Rubik's Cube state, binary data manipulation, interactive 3D rendering, animation, sound, and eventually CFOP learning tools.

The cube should feel like a modern kids puzzle and speed cube rather than an old-school debug demo. Prefer pastel sticker colors, softer cube edges, a light playful background, and cartoony UI polish that still feels high quality.

Prioritize clear code and avoid premature abstractions. The code should stay readable and should keep important cube-state bit operations visible while the project is still being used for learning.

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

The cube state is represented as a wrapper around one `u100`:

```zig
pub const Cube = struct {
    bits: u100,
};
```

There is no sticker-array state. Rendering reads colors from the packed cube bits through `facelet.color(...)`.

`Cube.bits` is intentionally public as a low-level value-type API while this remains a systems-learning project. Tests, fixtures, and future debug/CLI tools may construct raw states, but public raw states must continue to pass `Cube.validate()` before being treated as physical cubes.

Move tables are hand-coded for now. The risk is covered by validation, corner/edge permutation parity checks, and known facelet fixtures for all 18 moves. Defer generated or data-driven move tables until solver/search work needs them.

`facelet.faceletIndex(...)` is the fast assert-style helper for trusted internal coordinates. Use `facelet.faceletIndexChecked(...)` for any path that accepts unchecked coordinates and should return an error instead of asserting.

## Rendering and UI Rules

- Keep raylib as the active rendering backend for now.
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

## Current Animation Behavior

- User face turns are queued and animated one at a time. This preserves cube-state correctness while still making rapid repeated key presses feel responsive.
- Scramble on `Tab` resets to solved, generates a non-mutating `Cube.scramble(...)`, queues the scramble moves, displays the notation, and copies it to the clipboard.
- Magnetic easing currently uses a quick ease-out to a small overshoot, then settles back to the exact target angle before committing the move.
- Default turn durations are tuned for more visible frames: user turns are about `0.16s`, scramble turns are about `0.115s`, and the app requests a high render target FPS while still respecting vsync.
- `VisualTurn.layer_lift` gives the active layer a small bell-shaped outward lift while turning.
- True overlapping physical turns are not implemented yet. Do not start a second physical layer turn before the active move commits unless the renderer is upgraded to handle cubie-level transforms safely.

## Portability Rules

The long-term goal is to ship on desktop platforms and eventually explore WebAssembly and iOS.

- Avoid direct OS APIs in core logic.
- Keep cube logic, algorithm parsing, CFOP recognition, animation state, and app state independent from raylib where practical.
- Put platform-specific rendering, audio, window, and input concerns behind thin app-layer boundaries.
- Prefer assets and APIs that can work on desktop and future WebAssembly builds.
- Treat iOS as a later packaging target. Do not let iOS complexity block a more finished desktop/web-friendly product first.
- Keep native desktop builds working before adding web or mobile build complexity.

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
- Keep first moves explicit. Do not introduce generic cycle helpers until the raw bit manipulation is comfortable.
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

1. Visual polish
   - Make the app feel like a finished, cartoony, modern speed-cube puzzle.
   - Continue improving soft cube edges, lighting, shadows, sticker bevel feel, and the friendly overlay.
   - Add orientation aids for top/front/right without making the UI feel technical.
   - Do a manual GUI pass on moving-layer transforms from multiple camera angles and held-cube orientations.

2. Architecture cleanup for portability
   - Keep the new `app`, `camera`, `controls`, `ui`, and `gui` boundaries small and testable.
   - Keep pure logic modules free of raylib imports so they can be tested and reused for desktop, web, and mobile experiments.
   - Add WebAssembly build notes once the app loop is structured for web.

3. Animation and sound
   - Tune animation duration, overshoot, layer lift, and easing after manual playtesting.
   - Consider cubie-level transforms later if true overlapping turns become important.
   - Add lightweight sound effects for turns, scramble, reset, solved, and invalid actions.
   - Keep sounds optional and easy to disable for web/mobile.

4. CFOP trainer foundation
   - Add algorithm playback through the same move queue used by input.
   - Build helper/trainer behavior before attempting a full optimal solver.
   - Start with beginner-friendly CFOP data: cross/F2L guidance, then 2-look OLL/PLL, then full OLL/PLL.
   - Defer data-driven move tables until solver/search work needs generated transition data.

5. Helper UI
   - Highlight relevant cube pieces/stickers for the current learning step.
   - Show the recommended algorithm in a child-friendly panel.
   - Support step-through and auto-play.
   - Eventually detect sections and suggest algorithms based on the current cube state.

## Testing Expectations

- Run `zig build` after code changes.
- Run `zig build test` after changes to cube logic, app logic, parsing, animation state, or solver/trainer code.
- For rendering changes, compile first and do a manual GUI smoke test when practical.
- Future parser tests should cover normal moves, primes, doubles, and invalid tokens.
- Animation tests should cover move queue order, delayed commits, clear/reset behavior, and final visual target angles.
- Future CFOP tests should use known cube states for recognition and algorithm suggestions.
