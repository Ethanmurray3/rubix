# Web Frontend — Next Steps

## What exists

`web/index.html` — a fully interactive HTML/CSS/JS prototype of the trainer screen.
- CSS 3D cube with GAN aesthetic (rounded tiles, black chassis, pastel face colors)
- 3-column layout: sidebar (stages + cases) | main (cube + timer) | right panel (algorithm + stats)
- Working: mode switching, timer start/stop/reset, hint toggle, case/stage selection
- Design tokens defined as CSS custom properties in `:root` — easy to tweak

## Design tokens (CSS vars)

| Token | Value | Notes |
|---|---|---|
| `--bg` | `#F5F3EE` | Warm cream background |
| `--s0` | `#FFFFFF` | White surface (sidebar, panel) |
| `--acc` | `#5BA4E5` | GAN blue — accent + blue face |
| `--cR/cG/cO/cY/cW` | see `:root` | Cube face colors, also used for algorithm tokens and stage chips |
| `--fd` | Syne | Display/headings |
| `--fm` | Space Mono | Timer, algorithm notation |
| `--fb` | Instrument Sans | Body UI |

## Immediate next screens to build

### 1. Case Library (`web/library.html`)
- Grid of 2D case previews for all 2-look OLL (10) and PLL (6) cases
- Each card: 2D top-view face grid, case name, best time, learned status
- Filter/sort by stage, status, difficulty

### 2. Progress view (`web/progress.html`)
- Per-case accuracy bars and streak counts
- "Due for review" queue (cases with low accuracy or not practiced recently)
- Simple sparklines for attempt history

### 3. Algorithm playback UI
- Step-through mode: highlight the current move token, show which layer moves
- Animate the cube tiles moving when the Zig WASM core is wired up

## Wiring to Zig WASM core

When `rubix` WASM is ready, replace these hardcoded pieces in `index.html`:

| Hardcoded now | Replace with |
|---|---|
| Tile color arrays in `.face` HTML | `rubix.facelet.color(cube, face, row, col)` |
| Algorithm token strings | `rubix.cfop_cases.CaseDefinition.solution` |
| Case names in sidebar | `rubix.cfop_cases` catalog iterator |
| Timer logic (JS only) | hook into `rubix.trainer.Session` attempt start/stop |
| Progress dots | `rubix.progress.ProgressRecord` for the selected case |

Build entry point: `src/notation.zig` and `src/cfop_cases.zig` are the first modules needed for display. `src/trainer.zig` and `src/progress.zig` for the drill/session flow.

## Polish items (lower priority)

- Add AUF (Adjust U Face) rotation UI for recognition quiz mode
- Cube drag-to-rotate with mouse/touch
- Keyboard shortcuts overlay (matching the raylib desktop controls where applicable)
- Dark mode (swap `--bg`/`--s0` values, the cube colors hold fine as-is)
- Responsive layout for smaller screens (collapse sidebar to bottom nav)
