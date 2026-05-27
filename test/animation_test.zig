const std = @import("std");
const rubix = @import("rubix");

const animation = rubix.animation;
const cube_mod = rubix.cube;
const move_mod = rubix.move;
const scramble_mod = rubix.scramble;
const Cube = cube_mod.Cube;
const Face = cube_mod.Face;
const Move = move_mod.Move;
const PlayerAnimator = animation.PlayerAnimator;
const ScrambleAnimator = animation.ScrambleAnimator;

test "visual turn starts at zero and finishes exactly on target" {
    const start = animation.visualTurnForProgress(.R, 0);
    try std.testing.expectEqual(Face.right, start.face);
    try std.testing.expectEqual(@as(f32, -0.0), start.angle_degrees);

    const finish = animation.visualTurnForProgress(.R, 1);
    try std.testing.expectEqual(Face.right, finish.face);
    try std.testing.expectEqual(@as(f32, -90), finish.angle_degrees);

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
        try std.testing.expect(@abs(visual.angle_degrees) <= 94);
    }
}

test "player animator starts one move immediately and buffers latest input while active" {
    var animator = PlayerAnimator{ .turn_duration = 0.1 };

    try std.testing.expect(animator.isIdle());
    animator.submit(.R);
    try std.testing.expectEqual(@as(?Move, .R), animator.activeMove());
    try std.testing.expect(!animator.isIdle());

    animator.submit(.U);
    animator.submit(.F);
    try std.testing.expectEqual(@as(?Move, .R), animator.activeMove());
}

test "player animator commits active move then immediately starts pending move" {
    var cube = Cube.solved();
    const solved_bits = cube.bits;
    var animator = PlayerAnimator{ .turn_duration = 0.1 };

    animator.submit(.R);
    animator.submit(.U);
    try std.testing.expectEqual(@as(?Move, null), animator.update(0.099, &cube));
    try std.testing.expectEqual(solved_bits, cube.bits);

    try std.testing.expectEqual(@as(?Move, .R), animator.update(0.001, &cube));
    const after_r = cube.bits;
    try std.testing.expect(after_r != solved_bits);
    try std.testing.expectEqual(@as(?Move, .U), animator.activeMove());

    try std.testing.expectEqual(@as(?Move, null), animator.update(0.099, &cube));
    try std.testing.expectEqual(after_r, cube.bits);

    try std.testing.expectEqual(@as(?Move, .U), animator.update(0.001, &cube));
    try std.testing.expect(cube.bits != after_r);
    try std.testing.expect(animator.isIdle());
}

test "player animator keeps latest pending move" {
    var cube = Cube.solved();
    var expected = Cube.solved();
    var animator = PlayerAnimator{ .turn_duration = 0.1 };

    animator.submit(.R);
    animator.submit(.U);
    animator.submit(.F);

    try std.testing.expectEqual(@as(?Move, .R), animator.update(0.1, &cube));
    try std.testing.expectEqual(@as(?Move, .F), animator.activeMove());

    try std.testing.expectEqual(@as(?Move, .F), animator.update(0.1, &cube));
    expected.applyMove(.R);
    expected.applyMove(.F);
    try std.testing.expectEqual(expected.bits, cube.bits);
}

test "player animator visual turn clears after finishing or clearing" {
    var cube = Cube.solved();
    var animator = PlayerAnimator{ .turn_duration = 0.1 };

    animator.submit(.U);
    try std.testing.expect(animator.visualTurn() != null);
    _ = animator.update(0.1, &cube);
    try std.testing.expectEqual(@as(?animation.VisualTurn, null), animator.visualTurn());

    animator.submit(.F);
    animator.submit(.R);
    animator.clear();
    try std.testing.expectEqual(@as(?Move, null), animator.activeMove());
    try std.testing.expect(animator.isIdle());
    try std.testing.expectEqual(@as(?animation.VisualTurn, null), animator.visualTurn());
}

test "scramble animator applies moves in order at configured interval" {
    var cube = Cube.solved();
    const solved_bits = cube.bits;
    var animator = ScrambleAnimator{ .turn_duration = 0.1 };
    var moves = [_]Move{.R} ** scramble_mod.scramble_length;
    moves[1] = .U;
    const scramble = scramble_mod.Scramble{ .moves = moves };

    animator.start(scramble);
    try std.testing.expect(!animator.isIdle());

    try std.testing.expectEqual(@as(?Move, null), animator.update(0.099, &cube));
    try std.testing.expectEqual(solved_bits, cube.bits);
    try std.testing.expectEqual(@as(?Move, .R), animator.update(0.001, &cube));
    const after_first = cube.bits;
    try std.testing.expect(after_first != solved_bits);

    try std.testing.expectEqual(@as(?Move, null), animator.update(0, &cube));
    try std.testing.expectEqual(@as(?Move, .U), animator.activeMove());
    try std.testing.expectEqual(@as(?Move, .U), animator.update(0.1, &cube));
    try std.testing.expect(cube.bits != after_first);
}

test "scramble animator reports idle after all moves finish" {
    var cube = Cube.solved();
    var animator = ScrambleAnimator{ .turn_duration = 0.01 };
    const scramble = scramble_mod.Scramble{
        .moves = [_]Move{.R} ** scramble_mod.scramble_length,
    };

    animator.start(scramble);
    for (0..scramble_mod.scramble_length) |_| {
        try std.testing.expect(animator.update(0.01, &cube) != null);
    }

    try std.testing.expect(animator.isIdle());
    try std.testing.expectEqual(@as(?Move, null), animator.activeMove());
    try std.testing.expectEqual(@as(?animation.VisualTurn, null), animator.visualTurn());
}

test "scramble animator clear stops playback without committing extra moves" {
    var cube = Cube.solved();
    const solved_bits = cube.bits;
    var animator = ScrambleAnimator{ .turn_duration = 0.1 };
    const scramble = scramble_mod.Scramble{
        .moves = [_]Move{.R} ** scramble_mod.scramble_length,
    };

    animator.start(scramble);
    try std.testing.expectEqual(@as(?Move, null), animator.update(0.05, &cube));
    animator.clear();

    try std.testing.expect(animator.isIdle());
    try std.testing.expectEqual(solved_bits, cube.bits);
    try std.testing.expectEqual(@as(?Move, null), animator.update(0.1, &cube));
    try std.testing.expectEqual(solved_bits, cube.bits);
}
