const std = @import("std");
const rl = @import("raylib");
const animation = @import("animation.zig");
const camera_mod = @import("camera.zig");
const controls_mod = @import("controls.zig");
const cube_mod = @import("cube.zig");
const gui = @import("gui.zig");
const render = @import("render.zig");
const scramble_mod = @import("scramble.zig");
const ui = @import("ui.zig");

const Cube = cube_mod.Cube;
const PlayerAnimator = animation.PlayerAnimator;
const ScrambleAnimator = animation.ScrambleAnimator;

const AppState = struct {
    cube: Cube = Cube.solved(),
    orbit: camera_mod.Orbit = .{},
    orientation: render.Orientation = .{},
    player_animator: PlayerAnimator = .{},
    scramble_animator: ScrambleAnimator = .{},
    last: ui.LastAction = .{},
    scramble_buffer: [128]u8 = undefined,
};

pub fn run(init: std.process.Init) !void {
    var seed: u64 = undefined;
    init.io.random(std.mem.asBytes(&seed));
    var prng = std.Random.DefaultPrng.init(seed);

    gui.initWindow();
    defer rl.closeWindow();

    var state: AppState = .{};

    while (!rl.windowShouldClose()) {
        const frame_time = rl.getFrameTime();
        camera_mod.updateOrbitFromRaylibInput(&state.orbit);
        const camera = state.orbit.camera();
        const view_axes = camera_mod.viewAxes(camera);
        var view_controls = controls_mod.fromViewAxes(view_axes, state.orientation);

        if (controls_mod.readOrientationInput(&state.orientation, view_axes)) {
            view_controls = controls_mod.fromViewAxes(view_axes, state.orientation);
            state.last = .{
                .status = "Reoriented",
                .scramble = state.last.scramble,
            };
        }

        if (rl.isKeyPressed(.tab)) {
            state.cube = Cube.solved();
            state.player_animator.clear();
            state.scramble_animator.clear();
            const scramble = scramble_mod.generate(prng.random());
            state.scramble_animator.start(scramble);
            const notation = ui.scrambleNotationZ(&state.scramble_buffer, scramble);
            rl.setClipboardText(notation);
            state.last = .{
                .status = "Scrambling",
                .scramble = notation,
            };
        }

        if (rl.isKeyPressed(.space)) {
            state.cube = Cube.solved();
            state.orientation = .{};
            state.player_animator.clear();
            state.scramble_animator.clear();
            state.last = .{
                .status = "Solved",
                .scramble = "",
            };
        }

        const visual_turn: ?animation.VisualTurn = if (state.scramble_animator.isRunning()) scramble: {
            if (state.scramble_animator.update(frame_time, &state.cube)) |move| {
                state.last.status = ui.moveNameZ(move);
            } else if (state.scramble_animator.activeMove()) |move| {
                state.last.status = ui.moveNameZ(move);
            }
            break :scramble state.scramble_animator.visualTurn();
        } else player: {
            if (controls_mod.readMoveInput(view_controls)) |move| {
                state.player_animator.submit(move);
                state.last = .{
                    .status = ui.moveNameZ(move),
                    .scramble = "",
                };
            }

            if (state.player_animator.update(frame_time, &state.cube)) |move| {
                state.last.status = ui.moveNameZ(move);
            } else if (state.player_animator.activeMove()) |move| {
                state.last.status = ui.moveNameZ(move);
            }

            break :player state.player_animator.visualTurn();
        };

        if (state.cube.isSolved() and state.player_animator.isIdle() and state.scramble_animator.isIdle()) {
            state.last.status = "Solved";
        }

        gui.drawFrame(state.cube, camera, state.orientation, state.last, view_controls, visual_turn);
    }
}
