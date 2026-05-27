# Rubix Next Steps

## 1. Split the core package from the raylib desktop frontend

Make `rubix` a pure product/core module that can be reused by web, desktop, CLI, tests, and future iOS work without importing raylib. Move raylib-facing exports such as the desktop app, renderer, camera input, and desktop controls behind a separate frontend module.

## 2. Add an algorithm model

Create an `algorithm.zig` foundation for named algorithms, display notation, source metadata, stage/look/case IDs, and parsed executable moves. This should become the product-facing home for CFOP algorithm data.

## 3. Extend notation for CFOP data

Add a token layer that can preserve display notation while expanding to executable moves. It should handle rotations, slices, wide moves, setup/comment syntax, and normalization needed by common CFOP algorithms.

## 4. Add read-only cube inspection APIs

Expose clear cubie and sticker queries for trainer and recognition code: corner/edge at position, orientation, solved slot checks, last-layer masks, and case-friendly state views. Avoid making trainer code depend directly on packed bits.

## 5. Add the first trainer session model

Introduce a renderer-free `trainer.zig` model for selected stage, case, mode, prompt, hint state, attempt state, playback command, and progress update hooks before building more UI.
