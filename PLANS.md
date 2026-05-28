# Rubix Product Roadmap

## Vision

Rubix is a polished CFOP trainer for people learning to solve a Rubik's Cube with Cross, F2L, OLL, and PLL. It should feel like a friendly, high-quality learning product: playful enough for kids and beginners, accurate enough for speedcubers, and structured enough to help users build real algorithm memory.

The product should support both a real cube beside the app and a virtual cube inside the UI. A learner should be able to look up an algorithm, see how to set it up, watch it animate, drill recognition, practice execution, and eventually race against a computer solver.

Web is the primary future platform. The current Zig/raylib desktop app remains a useful prototype frontend and correctness harness until the portable core and trainer experience are ready for broader product work. iOS is a later target.

## Content Direction

J Perm's site is the main reference point for CFOP organization and algorithm selection:

- https://jperm.net/3x3/cfop
- https://jperm.net/3x3/cfop/f2l
- https://jperm.net/algs/2lookoll
- https://jperm.net/algs/oll
- https://jperm.net/algs/2lookpll
- https://jperm.net/algs/pll

Use J Perm as attributed inspiration and a reference for case organization. Do not copy the site's prose, images, trainer UI, or data wholesale without a later licensing/permission decision. Store Rubix's own curated algorithm data with source links and attribution metadata.

## Product Milestones

### Current Status

Completed:

- Documentation and architecture pivot.
- Initial portable core boundary: `rubix` is renderer-free and `rubix_desktop` owns raylib-facing modules.
- Read-only cube inspection APIs for corner/edge state, solved slots, up-layer checks, and facelet color views.
- CFOP notation token foundation for face turns, rotations, slices, and wide move display tokens.
- Initial CFOP/algorithm model with source metadata and executable move validation.
- Starter 2-look OLL/PLL case catalog and exact fixture recognizer.

Partial or temporary:

- Notation accepts slice/wide tokens but executable expansion for slice/wide moves is intentionally unsupported.
- Starter PLL data and stage semantics need review fixes before more case data is added.
- Recognition currently matches exact setup fixtures and is not yet real AUF/orientation-aware CFOP recognition.

### Current Review Fixes

Before building the trainer session, resolve the review issues found in the first CFOP core pass:

- Fix standard `y`/`y'` rotation expansion and add direct rotation mapping tests.
- Replace the starter PLL U-perm algorithms with verified PLL-only algorithms.
- Strengthen CFOP fixture tests so they assert stage semantics, not only `setup + solution == solved`.
- Add missing algorithm metadata validation for empty names and document borrowed static-data slices.
- Treat exact full-cube case recognition as a temporary fixture matcher until AUF/orientation-aware signatures exist.

### 1. Documentation and Architecture Pivot

- Reframe the repo as a shipped CFOP trainer product, not a Zig learning project.
- Keep the current desktop visualizer working while future work moves toward a portable trainer core and web-first UI.
- Document that trainer/session/progress/CFOP logic must stay independent from raylib.
- Make product polish, maintainability, portability, and learner outcomes the default decision criteria.
- Status: done.

### 2. Portable Core Boundary

- Split pure product logic from renderer-specific frontends.
- Keep cube state, moves, notation, facelet projection, scramble, algorithm data, CFOP recognition, trainer sessions, progress, and solver planning independent from raylib.
- Isolate raylib into desktop app, rendering, window, and input adapter modules.
- Move reusable orientation/control/session concepts into renderer-free modules before building web or iOS frontends.
- Status: initial split done; future orientation/control/session extraction can continue as trainer needs it.

### 3. Algorithm and Case Foundation

- Add a named algorithm model with IDs, display notation, parsed executable moves, stage, look variant, case metadata, and source attribution.
- Extend notation support for CFOP algorithm data, including rotations, slices, wide moves, comments, setup moves, and display-friendly formatting.
- Add curated case data for 2-look OLL and 2-look PLL first.
- Add fixtures proving setup algorithms create expected cases and solution algorithms resolve them.
- Status: algorithm model and starter data are in place; review fixes and stronger semantic tests are required before this milestone is done enough.

### 4. 2-Look OLL/PLL MVP

The first real product milestone is a 2-look last-layer trainer.

Required modes:

- Reference: show the case, setup, algorithm, notes, and animated playback.
- Drill: time attempts, reveal hints, track success, and repeat weak cases.
- Recognition quiz: show a cube state and ask the learner to identify the case or choose the algorithm.

Required learner flows:

- Choose OLL or PLL.
- Choose 2-look mode.
- Browse cases and algorithms.
- Generate a practice state.
- Animate setup and solution.
- Use the app with either a real cube or the virtual cube.
- Record basic progress per case.

### 5. Full CFOP Curriculum

- Add full OLL and full PLL case sets after the 2-look trainer is solid.
- Add F2L learning flows with pair recognition, setup states, recommended insertions, and common beginner-friendly alternatives.
- Add Cross planning and practice with guided inspection, piece highlighting, and staged hints.
- Add a CFOP solve-plan engine that teaches a human-style CFOP path rather than searching for an optimal solution.

### 6. Gamification and Progress

- Track attempts, streaks, best time, average time, recognition accuracy, and learned status per case.
- Add rewards for repeated successful algorithms, daily practice, streaks, and mastery milestones.
- Add spaced repetition so weak or due cases appear more often.
- Keep rewards motivating but secondary to real learning.

### 7. Bot Race Mode

- Add a solve race where the user presses Space to start a timer and solves a real or virtual cube against a CFOP bot.
- Give bots skill levels similar to chess bots: beginner, intermediate, advanced, expert.
- Bot difficulty should affect recognition delay, turning speed, pauses, and algorithm efficiency.
- Use the same CFOP solve-plan engine that powers teaching and playback.

### 8. Web and iOS Product Surfaces

- Build the first web UI around the actual trainer screen, not a landing page.
- Keep a polished 3D cube, stage navigation, algorithm playback, timer, hints, quiz controls, and progress visible without crowding the learner.
- Treat iOS as a later packaging and interaction target after the core trainer API is stable.

## Architecture Direction

Future modules should move toward this shape:

- `algorithm.zig`: named algorithms, source metadata, notation display, parsed executable move sequences.
- `cfop.zig`: CFOP stages, look variants, solve-plan concepts, and shared enums.
- `cfop_cases.zig`: curated case definitions for OLL, PLL, F2L, and Cross training.
- `cfop_recognition.zig`: case detection and stage-state recognition.
- `cfop_solver.zig`: human-style CFOP solve plans for teaching and bot playback.
- `trainer.zig`: lesson state, drill sessions, prompts, hints, answer checking, and mode transitions.
- `progress.zig`: per-case attempts, streaks, best times, mastery status, and review scheduling.
- `frontend` or adapter modules: raylib, web, and future iOS input/rendering layers.

The cube state may keep its compact internal representation, but product APIs should expose clear concepts instead of forcing UI and trainer code to work directly with packed bits.

## UI Direction

Rubix should look and feel like a shipped learning product. Prefer a modern, friendly, lightly playful style with pastel speed-cube colors, soft cube edges, clear typography, and responsive controls. Avoid debug-heavy overlays, dense engineering panels, or one-off prototype UI.

The primary trainer screen should center the cube and the current learning task. Expected controls include stage selection, case selection, algorithm playback, hint reveal, timer, progress state, and virtual-cube moves. Any frontend should translate inputs into semantic trainer commands such as `start_attempt`, `show_hint`, `submit_move`, `play_algorithm`, `choose_case`, and `mark_case_status`.

## Testing Expectations

- Run `zig build` after code changes.
- Run `zig build test` after changes to cube logic, notation, algorithm parsing, CFOP recognition, trainer state, progress, animation state, or solver behavior.
- For docs-only changes, `git diff --check` is enough unless commands or module claims need verification.
- CFOP tests should use known setup and solution fixtures.
- Trainer tests should cover mode transitions, hint state, timing state, answer checks, and progress updates without requiring a renderer.
- Frontend changes should be manually smoke-tested in the relevant browser or raylib app when practical.
