const std = @import("std");
const rl = @import("raylib");
const camera_mod = @import("camera.zig");
const controls_mod = @import("controls.zig");
const gui = @import("gui.zig");
const rubix = @import("rubix");
const render = @import("render.zig");
const animation = rubix.animation;
const cfop_cases = rubix.cfop_cases;
const cube_mod = rubix.cube;
const progress = rubix.progress;
const scramble_mod = rubix.scramble;
const trainer = rubix.trainer;
const ui = rubix.ui;

const Cube = cube_mod.Cube;
const AlgorithmAnimator = animation.AlgorithmAnimator;
const PlayerAnimator = animation.PlayerAnimator;
const ScrambleAnimator = animation.ScrambleAnimator;

const AppState = struct {
    cube: Cube = Cube.solved(),
    orbit: camera_mod.Orbit = .{},
    orientation: render.Orientation = .{},
    player_animator: PlayerAnimator = .{},
    scramble_animator: ScrambleAnimator = .{},
    algorithm_animator: AlgorithmAnimator = .{},
    trainer_session: trainer.Session,
    progress_book: progress.Book = .{},
    trainer_case_index: usize = 0,
    trainer_case_buffer: [96]u8 = undefined,
    trainer_mode_buffer: [120]u8 = undefined,
    trainer_setup_buffer: [260]u8 = undefined,
    trainer_solution_buffer: [260]u8 = undefined,
    trainer_progress_buffer: [160]u8 = undefined,
    last: ui.LastAction = .{},
    scramble_buffer: [128]u8 = undefined,

    fn init() AppState {
        return .{
            .trainer_session = trainer.Session.init(.reference, &cfop_cases.two_look_cases[0]),
        };
    }
};

pub fn run(init: std.process.Init) !void {
    var seed: u64 = undefined;
    init.io.random(std.mem.asBytes(&seed));
    var prng = std.Random.DefaultPrng.init(seed);

    gui.initWindow();
    defer rl.closeWindow();

    var state = AppState.init();

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
            state.algorithm_animator.clear();
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
            state.algorithm_animator.clear();
            state.last = .{
                .status = "Solved",
                .scramble = "",
            };
        }

        handleTrainerInput(&state);
        state.trainer_session.tick(@intFromFloat(@max(0, frame_time) * 1000));

        const visual_turn: ?animation.VisualTurn = if (state.algorithm_animator.isRunning()) algorithm: {
            if (state.algorithm_animator.update(frame_time, &state.cube)) |move| {
                state.last.status = ui.moveNameZ(move);
            } else if (state.algorithm_animator.activeMove()) |move| {
                state.last.status = ui.moveNameZ(move);
            }
            break :algorithm state.algorithm_animator.visualTurn();
        } else if (state.scramble_animator.isRunning()) scramble: {
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

        recordCompletedDrill(&state);

        if (state.cube.isSolved() and state.player_animator.isIdle() and state.scramble_animator.isIdle()) {
            state.last.status = "Solved";
        }

        gui.drawFrame(state.cube, camera, state.orientation, state.last, view_controls, trainerOverlay(&state), visual_turn);
    }
}

fn handleTrainerInput(state: *AppState) void {
    if (rl.isKeyPressed(.n)) chooseTrainerCase(state, 1);
    if (rl.isKeyPressed(.p)) chooseTrainerCase(state, -1);

    if (rl.isKeyPressed(.one)) setTrainerMode(state, .reference);
    if (rl.isKeyPressed(.two)) setTrainerMode(state, .drill);
    if (rl.isKeyPressed(.three)) setTrainerMode(state, .recognition_quiz);

    if (rl.isKeyPressed(.h)) {
        state.trainer_session.showHint();
        state.last.status = "Hint";
    }

    if (rl.isKeyPressed(.backspace)) {
        const request = state.trainer_session.playSetup();
        state.cube = Cube.solved();
        startTrainerPlayback(state, request);
    }

    if (rl.isKeyPressed(.enter)) {
        const request = state.trainer_session.playSolution();
        state.cube = state.trainer_session.prompt_cube;
        startTrainerPlayback(state, request);
    }

    if (rl.isKeyPressed(.t)) {
        state.trainer_session.startAttempt() catch return;
        state.cube = state.trainer_session.prompt_cube;
        state.player_animator.clear();
        state.scramble_animator.clear();
        state.algorithm_animator.clear();
        state.last.status = "Drill started";
    }
}

fn chooseTrainerCase(state: *AppState, delta: isize) void {
    const len: isize = @intCast(cfop_cases.two_look_cases.len);
    const current: isize = @intCast(state.trainer_case_index);
    const next = @mod(current + delta, len);
    state.trainer_case_index = @intCast(next);
    state.trainer_session.chooseCase(&cfop_cases.two_look_cases[state.trainer_case_index]);
    state.cube = state.trainer_session.prompt_cube;
    state.player_animator.clear();
    state.scramble_animator.clear();
    state.algorithm_animator.clear();
    state.last.status = "Case selected";
}

fn setTrainerMode(state: *AppState, mode: trainer.Mode) void {
    state.trainer_session.setMode(mode);
    state.last.status = "Trainer mode";
}

fn startTrainerPlayback(state: *AppState, request: trainer.PlaybackRequest) void {
    state.player_animator.clear();
    state.scramble_animator.clear();
    state.algorithm_animator.start(request.moves) catch {
        state.last.status = "Algorithm too long";
        return;
    };
    state.last.status = switch (request.kind) {
        .setup => "Setup playback",
        .solution => "Solution playback",
    };
}

fn recordCompletedDrill(state: *AppState) void {
    if (state.trainer_session.mode != .drill) return;
    if (state.trainer_session.attempt_state != .running) return;
    if (!state.cube.isSolved()) return;
    if (!state.player_animator.isIdle() or !state.algorithm_animator.isIdle() or !state.scramble_animator.isIdle()) return;

    _ = state.trainer_session.completeAttempt(true) catch return;
    _ = state.progress_book.recordAttempt(.{
        .case_id = state.trainer_session.selected_case.id,
        .kind = .drill,
        .success = true,
        .elapsed_ms = state.trainer_session.elapsed_ms,
    }) catch {};
    state.last.status = "Drill complete";
}

fn trainerOverlay(state: *AppState) gui.TrainerOverlay {
    const case = state.trainer_session.selected_case;
    const stats = state.progress_book.statsFor(case.id);
    const attempts: u32 = if (stats) |value| value.attempts else 0;
    const successes: u32 = if (stats) |value| value.successes else 0;

    return .{
        .case_line = std.fmt.bufPrintZ(&state.trainer_case_buffer, "{d}/{d} {s}", .{
            state.trainer_case_index + 1,
            cfop_cases.two_look_cases.len,
            case.name,
        }) catch unreachable,
        .mode_line = std.fmt.bufPrintZ(&state.trainer_mode_buffer, "Mode: {s}    Attempt: {s}", .{
            modeName(state.trainer_session.mode),
            attemptName(state.trainer_session.attempt_state),
        }) catch unreachable,
        .setup_line = std.fmt.bufPrintZ(&state.trainer_setup_buffer, "Setup: {s}", .{case.setup.display}) catch unreachable,
        .solution_line = std.fmt.bufPrintZ(&state.trainer_solution_buffer, "Solution: {s}", .{case.solution.display}) catch unreachable,
        .progress_line = std.fmt.bufPrintZ(&state.trainer_progress_buffer, "Progress: {d}/{d} correct", .{ successes, attempts }) catch unreachable,
        .hint_visible = state.trainer_session.hint_visible,
    };
}

fn modeName(mode: trainer.Mode) []const u8 {
    return switch (mode) {
        .reference => "Reference",
        .drill => "Drill",
        .recognition_quiz => "Recognition quiz",
    };
}

fn attemptName(state: trainer.AttemptState) []const u8 {
    return switch (state) {
        .idle => "Idle",
        .running => "Running",
        .succeeded => "Succeeded",
        .failed => "Failed",
    };
}
