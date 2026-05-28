# Rubix Next Steps

## Completed Milestones

- Core package split: `rubix` is now the renderer-free core package, and `rubix_desktop` owns raylib app/render/input exports.
- Cube inspection APIs: `Cube` now exposes read-only corner/edge state, solved slot checks, up-layer checks, and facelet color views for future recognition/trainer code.
- CFOP notation foundation: notation now has a token/display layer that recognizes face turns, rotations, slices, and wide moves, while executable expansion currently supports face turns and rotations.
- CFOP algorithm model: `cfop.zig` and `algorithm.zig` provide stages, look variants, case refs, source metadata, display notation, executable moves, validation, and application.
- Starter 2-look case data: `cfop_cases.zig` has an initial small static catalog for 2-look OLL/PLL with setup and solution fixtures.
- Starter recognition: `cfop_recognition.zig` can identify the current starter setup fixtures by exact cube state.
- Review fixes: rotation expansion, starter U-perm data, semantic fixture tests, empty-name validation, and exact-recognition documentation are complete.
- Full 2-look case data: `cfop_cases.zig` now covers 10 OLL cases and 6 PLL cases with inverse setup fixtures.
- AUF-aware recognition: `cfop_recognition.zig` returns solved, known, or unsupported results.
- Trainer core: `trainer.zig` supports reference, drill, recognition quiz, hints, attempts, answers, and playback requests without renderer imports.
- Progress core: `progress.zig` tracks attempts, timing, accuracy, learned status, weak cases, and due reviews in memory.
- Desktop prototype: raylib can browse cases, show setup/solution algorithms, play setup/solution animations, reveal hints, and record drill progress.

## Next Gate: Product Trainer Surface

Make the trainer usable and polished without moving product logic back into raylib.

1. Polish the desktop trainer harness.
   - Make mode/case navigation clearer.
   - Add recognition quiz input beyond the current reference/drill prototype.
   - Keep the UI useful, but avoid treating raylib as the final product surface.

2. Improve notation execution coverage.
   - Add executable support for slice and wide moves.
   - Keep existing face-turn and rotation tests green.
   - This should happen before importing larger full OLL/PLL algorithm sets.

3. Design the first web trainer screen.
   - Build the real trainer screen first: cube, case selector, algorithm playback, timer, hints, quiz state, and progress.
   - Use the existing core APIs instead of duplicating trainer logic in the frontend.

4. Add persistence after the trainer loop feels right.
   - Save progress locally first.
   - Keep account/cloud sync out of scope until the local product is useful.

5. Prepare full CFOP expansion.
   - Add full OLL/PLL after notation and trainer UX are stable.
   - Add F2L and Cross teaching only after the last-layer trainer is genuinely useful.

## Next Product Steps

## 1. Productize the trainer experience

Use the current desktop harness to learn what feels awkward, then move the same flow into a web-first trainer surface.

## 2. Expand algorithm capability

Add executable slice/wide notation support and stronger algorithm data tooling before importing larger case sets.

## 3. Add persistence and rewards

Persist local progress, then layer in rewards, streaks, and spaced-repetition tuning.
