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

Edge chunk layout:

```text
bits 0..3 = edge piece id
bit 4     = edge orientation
```

## Move Conventions

Use standard cube notation.

- `U` is clockwise when looking directly at the Up face.
- `U'` is counterclockwise when looking directly at the Up face.
- `R` is clockwise when looking directly at the Right face.
- `R'` is counterclockwise when looking directly at the Right face.
- The same viewing rule applies to other faces; for example, `D` is clockwise when looking directly at the Down face.

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

For `U` and `U'`, move whole 5-bit chunks without changing orientation.

For `R` and `R'`, move whole edge chunks without flipping edges. Corner chunks must be moved with orientation changes that match `Cube.facelet(...)`:

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
