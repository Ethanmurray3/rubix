# Rubix Project Notes

## Project Goal

Rubix is a Zig learning project focused on Rubik's Cube state, binary data manipulation, and terminal rendering.

Prioritize clear code that exposes the bit operations being learned. Avoid premature abstractions that hide how cube state is packed, moved, or decoded.

## Current Architecture

- `src/cube.zig` owns cube state and cube logic.
- `src/render.zig` owns terminal rendering.
- `src/main.zig` creates a cube and prints it.
- `src/root.zig` is the package module entry point.

The cube state is represented as a wrapper around one `u100`:

```zig
pub const Cube = struct {
    bits: u100,
};
```

There is no sticker-array state. Rendering reads colors from the packed cube bits through `Cube.facelet(...)`.

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

## Near-Term Implementation Rules

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

For `R`, `R'`, `L`, and `L'`, move whole edge chunks without flipping edges. Corner chunks must be moved with orientation changes that match `Cube.facelet(...)`.

For `F`, `F'`, `B`, and `B'`, move corner chunks with orientation changes and flip every moved edge chunk.

Current corner orientation changes:

```text
R:  UFR -> URB (+1), URB -> DRB (+2), DRB -> DFR (+1), DFR -> UFR (+2)
R': UFR -> DFR (+1), DFR -> DRB (+2), DRB -> URB (+1), URB -> UFR (+2)
```

## Future Ideas

These are not current implementation scope:

- Better terminal rendering, possibly using an alternate terminal buffer.
- Centered 2D terminal rendering.
- Experimental 3D ASCII rendering.
- Keyboard controls for moves, such as lowercase/uppercase pairs for clockwise/counterclockwise turns.
- Scramble generation.
- Solver algorithm.
- CFOP helper for learning algorithms.
