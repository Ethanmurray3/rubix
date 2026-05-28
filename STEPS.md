# Rubix Next Steps

## Completed Milestones

- Core package split: `rubix` is now the renderer-free core package, and `rubix_desktop` owns raylib app/render/input exports.
- Cube inspection APIs: `Cube` now exposes read-only corner/edge state, solved slot checks, up-layer checks, and facelet color views for future recognition/trainer code.
- CFOP notation foundation: notation now has a token/display layer that recognizes face turns, rotations, slices, and wide moves, while executable expansion currently supports face turns and rotations.
- CFOP algorithm model: `cfop.zig` and `algorithm.zig` provide stages, look variants, case refs, source metadata, display notation, executable moves, validation, and application.
- Starter 2-look case data: `cfop_cases.zig` has an initial small static catalog for 2-look OLL/PLL with setup and solution fixtures.
- Starter recognition: `cfop_recognition.zig` can identify the current starter setup fixtures by exact cube state.

## Next Gate: Review Fixes

These issues came out of the multi-agent review of the first CFOP trainer core commits. Fix these before building `trainer.zig` or more case data.

1. Fix `y` rotation expansion in `src/notation.zig`.
   - Current behavior maps `y F` to `L`.
   - Standard cube notation should map `y F` to `R`.
   - Add standalone tests for `x`, `x'`, `y`, `y'`, `z`, and `z'` face-frame mappings.

2. Replace the starter PLL algorithms in `src/cfop_cases.zig`.
   - The current Ua/Ub entries resolve because setup is the inverse of the same sequence, but the sequences are not valid PLL-only states.
   - Use verified 2-look PLL U-perm algorithms and keep source attribution.

3. Strengthen CFOP case fixture tests.
   - Do not only test `setup + solution == solved`.
   - PLL setup should preserve F2L and last-layer orientation while permuting only the last layer.
   - OLL setup should preserve the expected permutation constraints and create an orientation case.

4. Tighten `algorithm.Definition.validate`.
   - Add `EmptyName`.
   - Decide whether parser/expansion failures should stay as inferred errors or be mapped into validation-domain errors.
   - Document that string/move slices are borrowed and currently intended for static case data.

5. Clarify or replace exact fixture recognition.
   - `cfop_recognition.recognizeTwoLook` currently matches exact full-cube setup states.
   - Rename/document it as starter fixture recognition or move toward precomputed case signatures.
   - Do not rely on it for real trainer recognition until AUF/orientation variants are handled.

## Next Product Steps

## 1. Finish CFOP data correctness

After the review fixes, complete the 2-look OLL/PLL data slice with verified algorithms, semantic case fixtures, and attribution. Do not add more trainer behavior until the case data can be trusted.

## 2. Improve recognition beyond exact fixtures

Replace exact full-cube matching with case signatures that can tolerate AUF/orientation variants where appropriate. Recognition should return supported case IDs or a clear unknown result.

## 3. Add the first trainer session model

Introduce a renderer-free `trainer.zig` model for selected stage, case, mode, prompt, hint state, attempt state, playback command, and progress update hooks before building more UI.

## 4. Add basic progress

Add `progress.zig` for attempts, success, best/average time, recognition accuracy, learned status, weak-case selection, and due-case review. Keep persistence out of scope for the first pass.

## 5. Lightly wire the desktop prototype

Use raylib as a temporary harness to browse starter cases, show setup/solution algorithms, play animations, reveal hints, and record in-memory progress. Keep the long-term product logic renderer-free.
