const std = @import("std");
const rubix = @import("rubix");
const cube = rubix.cube;
const notation = rubix.notation;

test "parseMove accepts standard quarter prime and double turns" {
    try std.testing.expectEqual(cube.Move.R, try notation.parseMove("R"));
    try std.testing.expectEqual(cube.Move.RPrime, try notation.parseMove("R'"));
    try std.testing.expectEqual(cube.Move.R2, try notation.parseMove("R2"));
    try std.testing.expectEqual(cube.Move.U, try notation.parseMove("U"));
    try std.testing.expectEqual(cube.Move.DPrime, try notation.parseMove("D'"));
    try std.testing.expectEqual(cube.Move.F2, try notation.parseMove("F2"));
    try std.testing.expectEqual(cube.Move.BPrime, try notation.parseMove("B'"));
    try std.testing.expectEqual(cube.Move.L2, try notation.parseMove("L2"));
}

test "parseMove rejects empty invalid face and invalid suffix tokens" {
    try std.testing.expectError(error.EmptyMove, notation.parseMove(""));
    try std.testing.expectError(error.InvalidFace, notation.parseMove("M"));
    try std.testing.expectError(error.InvalidSuffix, notation.parseMove("R3"));
    try std.testing.expectError(error.InvalidSuffix, notation.parseMove("R''"));
}

test "parseMove round trips move names" {
    inline for (std.meta.fields(cube.Move)) |field| {
        const move: cube.Move = @enumFromInt(field.value);
        try std.testing.expectEqual(move, try notation.parseMove(cube.moveName(move)));
        try std.testing.expectEqualStrings(cube.moveName(move), notation.formatMove(move));
    }
}

test "parseAlgorithm allocates a move slice from notation" {
    const moves = try notation.parseAlgorithm(std.testing.allocator, "R U R' U'");
    defer std.testing.allocator.free(moves);

    try std.testing.expectEqualSlices(cube.Move, &.{ .R, .U, .RPrime, .UPrime }, moves);

    var state = cube.Cube.solved();
    state.applyMoves(moves);
    try std.testing.expect(!state.isSolved());
}

test "parseAlgorithm handles extra whitespace and double moves" {
    const moves = try notation.parseAlgorithm(std.testing.allocator, "  R2\tF\nB'   L D2  ");
    defer std.testing.allocator.free(moves);

    try std.testing.expectEqualSlices(cube.Move, &.{ .R2, .F, .BPrime, .L, .D2 }, moves);
}

test "parseAlgorithmInto parses without allocation" {
    var buffer: [8]cube.Move = undefined;
    const moves = try notation.parseAlgorithmInto("F R U R' U' F'", &buffer);

    try std.testing.expectEqualSlices(cube.Move, &.{ .F, .R, .U, .RPrime, .UPrime, .FPrime }, moves);
}

test "parseAlgorithmInto rejects empty input and undersized output" {
    var buffer: [2]cube.Move = undefined;

    try std.testing.expectError(error.EmptyAlgorithm, notation.parseAlgorithmInto(" \t\n", &buffer));
    try std.testing.expectError(error.OutputTooSmall, notation.parseAlgorithmInto("R U R'", &buffer));
}

test "sexy move repeated six times returns solved" {
    const moves = try notation.parseAlgorithm(std.testing.allocator, "R U R' U'");
    defer std.testing.allocator.free(moves);

    var state = cube.Cube.solved();
    for (0..6) |_| {
        state.applyMoves(moves);
    }

    try std.testing.expect(state.isSolved());
    try state.validate();
}
