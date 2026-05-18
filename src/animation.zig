const std = @import("std");
const cube_mod = @import("cube.zig");

const Cube = cube_mod.Cube;
const Face = cube_mod.Face;
const Move = cube_mod.Move;
const Scramble = cube_mod.Scramble;

pub const default_user_turn_duration: f32 = 0.105;
pub const default_scramble_turn_duration: f32 = 0.075;
pub const queue_capacity = 128;

pub const VisualTurn = struct {
    face: Face,
    angle_degrees: f32,
    layer_lift: f32,
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
    const clamped = std.math.clamp(progress, 0, 1);
    return .{
        .face = cube_mod.moveFace(move),
        .angle_degrees = targetAngle(move) * magneticProgress(clamped),
        .layer_lift = 0.055 * @sin(std.math.pi * clamped),
    };
}

fn magneticProgress(progress: f32) f32 {
    const overshoot: f32 = 1.04;
    const overshoot_time: f32 = 0.72;

    if (progress < overshoot_time) {
        return overshoot * easeOutCubic(progress / overshoot_time);
    }

    const settle = (progress - overshoot_time) / (1.0 - overshoot_time);
    return overshoot + (1.0 - overshoot) * easeOutCubic(settle);
}

fn easeOutCubic(value: f32) f32 {
    const inverse = 1.0 - value;
    return 1.0 - inverse * inverse * inverse;
}

fn targetAngle(move: Move) f32 {
    return switch (move) {
        .UPrime, .DPrime, .RPrime, .LPrime, .FPrime, .BPrime => 90,
        .U2, .D2, .R2, .L2, .F2, .B2 => -180,
        else => -90,
    };
}
