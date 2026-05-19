const std = @import("std");
const rubix = @import("rubix");

const animation = rubix.animation;
const cube_mod = rubix.cube;
const Animator = animation.Animator;
const Cube = cube_mod.Cube;
const Face = cube_mod.Face;
const Move = cube_mod.Move;

test "visual turn starts at zero and finishes exactly on target" {
    const start = animation.visualTurnForProgress(.R, 0);
    try std.testing.expectEqual(Face.right, start.face);
    try std.testing.expectEqual(@as(f32, -0.0), start.angle_degrees);
    try std.testing.expectEqual(@as(f32, 0), start.layer_lift);
    try std.testing.expectEqual(@as(f32, 0), start.neighbor_give_degrees);

    const finish = animation.visualTurnForProgress(.R, 1);
    try std.testing.expectEqual(Face.right, finish.face);
    try std.testing.expectEqual(@as(f32, -90), finish.angle_degrees);
    try std.testing.expectEqual(@as(f32, 0), finish.layer_lift);
    try std.testing.expectEqual(@as(f32, 0), finish.neighbor_give_degrees);

    const double = animation.visualTurnForProgress(.U2, 1);
    try std.testing.expectEqual(@as(f32, -180), double.angle_degrees);
}

test "magnetic easing overshoots mildly before settling" {
    const mid = animation.visualTurnForProgress(.R, 0.68);
    try std.testing.expect(mid.angle_degrees < -90);
    try std.testing.expect(mid.angle_degrees > -94);

    const prime = animation.visualTurnForProgress(.RPrime, 0.68);
    try std.testing.expect(prime.angle_degrees > 90);
    try std.testing.expect(prime.angle_degrees < 94);
}

test "visual values stay finite and bounded for invalid progress inputs" {
    const cases = [_]f32{
        -10,
        0,
        0.25,
        0.5,
        0.75,
        1,
        10,
        std.math.nan(f32),
        std.math.inf(f32),
        -std.math.inf(f32),
    };

    for (cases) |progress| {
        const visual = animation.visualTurnForProgress(.F, progress);
        try std.testing.expect(std.math.isFinite(visual.angle_degrees));
        try std.testing.expect(std.math.isFinite(visual.layer_lift));
        try std.testing.expect(std.math.isFinite(visual.neighbor_give_degrees));
        try std.testing.expect(@abs(visual.angle_degrees) <= 94);
        try std.testing.expect(visual.layer_lift >= 0);
        try std.testing.expect(visual.layer_lift <= 0.055);
        try std.testing.expect(visual.neighbor_give_degrees >= 0);
        try std.testing.expect(visual.neighbor_give_degrees <= 2.2);
    }
}

test "animator commits active move once after visual turn finishes" {
    var cube = Cube.solved();
    const solved_bits = cube.bits;
    var animator = Animator{};

    try std.testing.expect(animator.enqueue(.R));
    try std.testing.expectEqual(@as(?Move, null), animator.update(0.05, &cube));
    try std.testing.expectEqual(solved_bits, cube.bits);
    try std.testing.expectEqual(@as(?Move, .R), animator.activeMove());

    try std.testing.expectEqual(@as(?Move, .R), animator.update(animation.default_user_turn_duration, &cube));
    const turned_bits = cube.bits;
    try std.testing.expect(turned_bits != solved_bits);
    try std.testing.expectEqual(@as(?Move, null), animator.activeMove());

    try std.testing.expectEqual(@as(?Move, null), animator.update(animation.default_user_turn_duration, &cube));
    try std.testing.expectEqual(turned_bits, cube.bits);
}

test "animator preserves move order" {
    var animator: Animator = .{ .user_turn_duration = 0.1 };
    var cube = Cube.solved();

    try std.testing.expect(animator.enqueue(.R));
    try std.testing.expect(animator.enqueue(.U));

    try std.testing.expectEqual(@as(?Move, null), animator.update(0.05, &cube));
    try std.testing.expectEqual(@as(?Move, .R), animator.activeMove());
    try std.testing.expectEqual(@as(?Move, .R), animator.update(0.05, &cube));

    try std.testing.expectEqual(@as(?Move, null), animator.update(0, &cube));
    try std.testing.expectEqual(@as(?Move, .U), animator.activeMove());
    try std.testing.expectEqual(@as(?Move, .U), animator.update(0.1, &cube));
}

test "animator commits moves only after duration completes" {
    var animator: Animator = .{ .user_turn_duration = 0.1 };
    var cube = Cube.solved();
    const solved_bits = cube.bits;

    try std.testing.expect(animator.enqueue(.R));
    try std.testing.expectEqual(@as(?Move, null), animator.update(0.099, &cube));
    try std.testing.expectEqual(solved_bits, cube.bits);

    try std.testing.expectEqual(@as(?Move, .R), animator.update(0.001, &cube));
    try std.testing.expect(cube.bits != solved_bits);
}

test "active animation reaches final target angle at completion progress" {
    const visual = animation.visualTurnForProgress(.R, 1.0);

    try std.testing.expectEqual(.right, visual.face);
    try std.testing.expectApproxEqAbs(@as(f32, -90), visual.angle_degrees, 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 0), visual.layer_lift, 0.001);
}

test "animator clear leaves no active move and no queued moves" {
    var animator: Animator = .{};
    var cube = Cube.solved();

    try std.testing.expect(animator.enqueue(.R));
    try std.testing.expect(animator.enqueue(.U));
    _ = animator.update(0.01, &cube);

    animator.clear();

    try std.testing.expectEqual(@as(?Move, null), animator.activeMove());
    try std.testing.expectEqual(@as(usize, 0), animator.queuedCount());
    try std.testing.expect(animator.isIdle());
}
