# Rubix Next Steps

## Completed Milestones

- Core package split: `rubix` is now the renderer-free core package, and `rubix_desktop` owns raylib app/render/input exports.
- Cube inspection APIs: `Cube` now exposes read-only corner/edge state, solved slot checks, up-layer checks, and facelet color views for future recognition/trainer code.
- CFOP notation foundation: notation now has a token/display layer that recognizes face turns, rotations, slices, and wide moves, while executable expansion currently supports face turns and rotations.
- CFOP algorithm model: `cfop.zig` and `algorithm.zig` provide stages, look variants, case refs, source metadata, display notation, executable moves, validation, and application.
- Starter 2-look case data: `cfop_cases.zig` has an initial small static catalog for 2-look OLL/PLL with setup and solution fixtures.
- Starter recognition: `cfop_recognition.zig` can identify the current starter setup fixtures by exact cube state.
- Review fixes: rotation expansion, starter U-perm data, semantic fixture tests, empty-name validation, and exact-recognition documentation are complete.

## Next Gate: Full 2-Look Core Trainer

Finish a trusted renderer-free 2-look trainer foundation before investing in web or heavier desktop UI.

1. Complete full 2-look OLL/PLL data.
   - Add all standard 2-look OLL and PLL cases.
   - Keep Rubix-owned case data with J Perm attribution links.
   - Ensure every setup fixture preserves stage semantics and solves with its solution.

2. Replace exact fixture recognition.
   - Recognize last-layer signatures instead of exact full-cube setup states.
   - Handle AUF variants.
   - Return known, solved, or unsupported results.

3. Add the first trainer session model.
   - Support reference, drill, and recognition quiz modes.
   - Track selected case, prompt cube, hints, attempts, answer checks, and playback commands.

4. Add basic progress.
   - Track attempts, success, best/average time, recognition accuracy, learned status, weak-case ranking, and review selection.
   - Keep persistence out of scope.

5. Lightly wire the desktop prototype.
   - Use raylib as a temporary harness for browsing cases, showing algorithms, playing animations, revealing hints, and recording in-memory progress.

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
