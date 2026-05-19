const std = @import("std");
const cube_mod = @import("cube.zig");

const Cube = cube_mod.Cube;
const Face = cube_mod.Face;
const Move = cube_mod.Move;
const Scramble = cube_mod.Scramble;

pub const default_user_turn_duration: f32 = 0.16;
pub const default_scramble_turn_duration: f32 = 0.115;
pub const queue_capacity = 128;

pub const VisualTurn = struct {
    face: Face,
    angle_degrees: f32,
    layer_lift: f32,
    neighbor_give_degrees: f32 = 0,
};

const QueuedMove = struct {
    move: Move,
    duration: f32,
};

const ActiveTurn = struct {
    move: Move,
    elapsed: f32,
    duration: f32,
};

pub const Animator = struct {
    queue: [queue_capacity]QueuedMove = undefined,
    head: usize = 0,
    len: usize = 0,
    active: ?ActiveTurn = null,
    user_turn_duration: f32 = default_user_turn_duration,
    scramble_turn_duration: f32 = default_scramble_turn_duration,

    pub fn enqueue(self: *Animator, move: Move) bool {
        return self.enqueueWithDuration(move, self.user_turn_duration);
    }

    pub fn enqueueScramble(self: *Animator, scramble: Scramble) void {
        for (scramble.moves) |move| {
            _ = self.enqueueWithDuration(move, self.scramble_turn_duration);
        }
    }

    pub fn update(self: *Animator, dt: f32, cube: *Cube) ?Move {
        if (self.active == null) self.startNext();
        if (self.active == null) return null;

        self.active.?.elapsed += @max(0, dt);
        if (self.active.?.elapsed < self.active.?.duration) return null;

        const move = self.active.?.move;
        cube.applyMove(move);
        self.active = null;
        return move;
    }

    pub fn visualTurn(self: Animator) ?VisualTurn {
        const active = self.active orelse return null;
        const progress = if (active.duration <= 0)
            1
        else
            std.math.clamp(active.elapsed / active.duration, 0, 1);
        return visualTurnForProgress(active.move, progress);
    }

    pub fn activeMove(self: Animator) ?Move {
        if (self.active) |active| return active.move;
        return null;
    }

    pub fn queuedCount(self: Animator) usize {
        return self.len;
    }

    pub fn isIdle(self: Animator) bool {
        return self.active == null and self.len == 0;
    }

    pub fn clear(self: *Animator) void {
        self.head = 0;
        self.len = 0;
        self.active = null;
    }

    fn enqueueWithDuration(self: *Animator, move: Move, duration: f32) bool {
        if (self.len == self.queue.len) return false;
        const index = (self.head + self.len) % self.queue.len;
        self.queue[index] = .{
            .move = move,
            .duration = duration,
        };
        self.len += 1;
        return true;
    }

    fn startNext(self: *Animator) void {
        if (self.len == 0) return;

        const queued = self.queue[self.head];
        self.head = (self.head + 1) % self.queue.len;
        self.len -= 1;
        self.active = .{
            .move = queued.move,
            .elapsed = 0,
            .duration = queued.duration,
        };
    }
};

pub fn visualTurnForProgress(move: Move, progress: f32) VisualTurn {
    const clamped = clampProgress(progress);
    const spring = magneticProgress(clamped);
    const lift = bellProgress(clamped);
    return .{
        .face = cube_mod.moveFace(move),
        .angle_degrees = targetAngle(move) * spring,
        .layer_lift = 0.055 * lift,
        .neighbor_give_degrees = 2.2 * lift * (1.0 - 0.18 * clamped),
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

fn bellProgress(progress: f32) f32 {
    if (progress <= 0 or progress >= 1) return 0;
    return @max(0, @sin(std.math.pi * progress));
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
