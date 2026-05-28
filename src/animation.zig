const std = @import("std");
const cube_mod = @import("cube.zig");
const facelet = @import("facelet.zig");
const move_mod = @import("move.zig");
const scramble_mod = @import("scramble.zig");

const Cube = cube_mod.Cube;
const Face = facelet.Face;
const Move = move_mod.Move;
const Scramble = scramble_mod.Scramble;

pub const default_user_turn_duration: f32 = 0.16;
pub const default_scramble_turn_duration: f32 = 0.115;
pub const max_algorithm_moves = 32;

pub const AnimationError = error{
    TooManyMoves,
};

pub const VisualTurn = struct {
    face: Face,
    angle_degrees: f32,
};

const ActiveTurn = struct {
    move: Move,
    elapsed: f32,
    duration: f32,

    fn progress(self: ActiveTurn) f32 {
        if (self.duration <= 0) return 1;
        return std.math.clamp(self.elapsed / self.duration, 0, 1);
    }
};

pub const PlayerAnimator = struct {
    active: ?ActiveTurn = null,
    pending: ?Move = null,
    turn_duration: f32 = default_user_turn_duration,

    pub fn submit(self: *PlayerAnimator, move: Move) void {
        if (self.tryStart(move)) return;
        self.pending = move;
    }

    fn tryStart(self: *PlayerAnimator, move: Move) bool {
        if (self.active != null) return false;

        self.active = .{
            .move = move,
            .elapsed = 0,
            .duration = self.turn_duration,
        };
        return true;
    }

    pub fn update(self: *PlayerAnimator, dt: f32, cube: *Cube) ?Move {
        if (self.active == null) return null;

        self.active.?.elapsed += @max(0, dt);
        if (self.active.?.elapsed < self.active.?.duration) return null;

        const move = self.active.?.move;
        cube.applyMove(move);
        self.active = null;
        self.startPending();
        return move;
    }

    pub fn visualTurn(self: PlayerAnimator) ?VisualTurn {
        const active = self.active orelse return null;
        return visualTurnForProgress(active.move, active.progress());
    }

    pub fn activeMove(self: PlayerAnimator) ?Move {
        if (self.active) |active| return active.move;
        return null;
    }

    pub fn isIdle(self: PlayerAnimator) bool {
        return self.active == null and self.pending == null;
    }

    pub fn clear(self: *PlayerAnimator) void {
        self.active = null;
        self.pending = null;
    }

    fn startPending(self: *PlayerAnimator) void {
        const pending = self.pending orelse return;
        self.pending = null;
        _ = self.tryStart(pending);
    }
};

pub const ScrambleAnimator = struct {
    scramble: ?Scramble = null,
    index: usize = 0,
    active: ?ActiveTurn = null,
    turn_duration: f32 = default_scramble_turn_duration,

    pub fn start(self: *ScrambleAnimator, scramble: Scramble) void {
        self.scramble = scramble;
        self.index = 0;
        self.active = null;
    }

    pub fn update(self: *ScrambleAnimator, dt: f32, cube: *Cube) ?Move {
        self.startNextIfIdle();
        if (self.active == null) return null;

        self.active.?.elapsed += @max(0, dt);
        if (self.active.?.elapsed < self.active.?.duration) return null;

        const move = self.active.?.move;
        cube.applyMove(move);
        self.active = null;
        if (self.index == scramble_mod.scramble_length) {
            self.scramble = null;
        }
        return move;
    }

    pub fn visualTurn(self: ScrambleAnimator) ?VisualTurn {
        const active = self.active orelse return null;
        return visualTurnForProgress(active.move, active.progress());
    }

    pub fn activeMove(self: ScrambleAnimator) ?Move {
        if (self.active) |active| return active.move;
        return null;
    }

    pub fn isIdle(self: ScrambleAnimator) bool {
        return self.scramble == null and self.active == null;
    }

    pub fn isRunning(self: ScrambleAnimator) bool {
        return !self.isIdle();
    }

    pub fn clear(self: *ScrambleAnimator) void {
        self.scramble = null;
        self.index = 0;
        self.active = null;
    }

    fn startNextIfIdle(self: *ScrambleAnimator) void {
        if (self.active != null) return;
        const scramble = self.scramble orelse return;
        if (self.index >= scramble.moves.len) {
            self.scramble = null;
            return;
        }

        self.active = .{
            .move = scramble.moves[self.index],
            .elapsed = 0,
            .duration = self.turn_duration,
        };
        self.index += 1;
    }
};

pub const AlgorithmAnimator = struct {
    moves: [max_algorithm_moves]Move = undefined,
    len: usize = 0,
    index: usize = 0,
    active: ?ActiveTurn = null,
    turn_duration: f32 = default_scramble_turn_duration,

    pub fn start(self: *AlgorithmAnimator, moves: []const Move) AnimationError!void {
        if (moves.len > self.moves.len) return AnimationError.TooManyMoves;

        @memcpy(self.moves[0..moves.len], moves);
        self.len = moves.len;
        self.index = 0;
        self.active = null;
    }

    pub fn update(self: *AlgorithmAnimator, dt: f32, cube: *Cube) ?Move {
        self.startNextIfIdle();
        if (self.active == null) return null;

        self.active.?.elapsed += @max(0, dt);
        if (self.active.?.elapsed < self.active.?.duration) return null;

        const move = self.active.?.move;
        cube.applyMove(move);
        self.active = null;
        if (self.index == self.len) self.len = 0;
        return move;
    }

    pub fn visualTurn(self: AlgorithmAnimator) ?VisualTurn {
        const active = self.active orelse return null;
        return visualTurnForProgress(active.move, active.progress());
    }

    pub fn activeMove(self: AlgorithmAnimator) ?Move {
        if (self.active) |active| return active.move;
        return null;
    }

    pub fn isIdle(self: AlgorithmAnimator) bool {
        return self.len == 0 and self.active == null;
    }

    pub fn isRunning(self: AlgorithmAnimator) bool {
        return !self.isIdle();
    }

    pub fn clear(self: *AlgorithmAnimator) void {
        self.len = 0;
        self.index = 0;
        self.active = null;
    }

    fn startNextIfIdle(self: *AlgorithmAnimator) void {
        if (self.active != null) return;
        if (self.index >= self.len) {
            self.len = 0;
            return;
        }

        self.active = .{
            .move = self.moves[self.index],
            .elapsed = 0,
            .duration = self.turn_duration,
        };
        self.index += 1;
    }
};

pub fn visualTurnForProgress(move: Move, progress: f32) VisualTurn {
    const clamped = clampProgress(progress);
    const spring = magneticProgress(clamped);
    return .{
        .face = facelet.moveFace(move),
        .angle_degrees = targetAngle(move) * spring,
    };
}

fn magneticProgress(progress: f32) f32 {
    if (progress <= 0) return 0;
    if (progress >= 1) return 1;

    const tension: f32 = 0.78;
    const c3 = tension + 1.0;
    const t = progress - 1.0;
    return 1.0 + c3 * t * t * t + tension * t * t;
}

fn clampProgress(progress: f32) f32 {
    if (std.math.isNan(progress)) return 0;
    if (progress <= 0) return 0;
    if (progress >= 1) return 1;
    return progress;
}

fn targetAngle(move: Move) f32 {
    return switch (move) {
        .UPrime, .DPrime, .RPrime, .LPrime, .FPrime, .BPrime => 90,
        .U2, .D2, .R2, .L2, .F2, .B2 => -180,
        else => -90,
    };
}
