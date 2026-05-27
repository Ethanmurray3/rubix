const std = @import("std");
const rubix = @import("rubix");
const cube = rubix.cube;
const move_mod = rubix.move;
const notation = rubix.notation;

test "parseMove accepts standard quarter prime and double turns" {
    try std.testing.expectEqual(move_mod.Move.R, try notation.parseMove("R"));
    try std.testing.expectEqual(move_mod.Move.RPrime, try notation.parseMove("R'"));
    try std.testing.expectEqual(move_mod.Move.R2, try notation.parseMove("R2"));
    try std.testing.expectEqual(move_mod.Move.U, try notation.parseMove("U"));
    try std.testing.expectEqual(move_mod.Move.DPrime, try notation.parseMove("D'"));
    try std.testing.expectEqual(move_mod.Move.F2, try notation.parseMove("F2"));
    try std.testing.expectEqual(move_mod.Move.BPrime, try notation.parseMove("B'"));
    try std.testing.expectEqual(move_mod.Move.L2, try notation.parseMove("L2"));
}

test "parseMove rejects empty invalid face and invalid suffix tokens" {
    try std.testing.expectError(error.EmptyMove, notation.parseMove(""));
    try std.testing.expectError(error.InvalidFace, notation.parseMove("M"));
    try std.testing.expectError(error.InvalidSuffix, notation.parseMove("R3"));
    try std.testing.expectError(error.InvalidSuffix, notation.parseMove("R''"));
}

test "parseMove round trips move names" {
    inline for (std.meta.fields(move_mod.Move)) |field| {
        const move: move_mod.Move = @enumFromInt(field.value);
        try std.testing.expectEqual(move, try notation.parseMove(move_mod.moveName(move)));
        try std.testing.expectEqualStrings(move_mod.moveName(move), notation.formatMove(move));
    }
}

test "parseAlgorithm allocates a move slice from notation" {
    const moves = try notation.parseAlgorithm(std.testing.allocator, "R U R' U'");
    defer std.testing.allocator.free(moves);

    try std.testing.expectEqualSlices(move_mod.Move, &.{ .R, .U, .RPrime, .UPrime }, moves);

    var state = cube.Cube.solved();
    state.applyMoves(moves);
    try std.testing.expect(!state.isSolved());
}

test "parseAlgorithm handles extra whitespace and double moves" {
    const moves = try notation.parseAlgorithm(std.testing.allocator, "  R2\tF\nB'   L D2  ");
    defer std.testing.allocator.free(moves);

    try std.testing.expectEqualSlices(move_mod.Move, &.{ .R2, .F, .BPrime, .L, .D2 }, moves);
}

test "formatAlgorithmInto writes normalized notation" {
    var buffer: [32]u8 = undefined;
    const text = try notation.formatAlgorithmInto(&buffer, &.{ .R, .U, .RPrime, .UPrime });

    try std.testing.expectEqualStrings("R U R' U'", text);
}

test "formatAlgorithmInto supports empty algorithms and rejects undersized buffers" {
    var empty_buffer: [0]u8 = .{};
    const empty = try notation.formatAlgorithmInto(&empty_buffer, &.{});
    try std.testing.expectEqualStrings("", empty);

    var short_buffer: [4]u8 = undefined;
    try std.testing.expectError(error.OutputTooSmall, notation.formatAlgorithmInto(&short_buffer, &.{ .R, .U, .RPrime }));
}

test "parseAlgorithmInto parses without allocation" {
    var buffer: [8]move_mod.Move = undefined;
    const moves = try notation.parseAlgorithmInto("F R U R' U' F'", &buffer);

    try std.testing.expectEqualSlices(move_mod.Move, &.{ .F, .R, .U, .RPrime, .UPrime, .FPrime }, moves);
}

test "parseAlgorithmInto rejects empty input and undersized output" {
    var buffer: [2]move_mod.Move = undefined;

    try std.testing.expectError(error.EmptyAlgorithm, notation.parseAlgorithmInto(" \t\n", &buffer));
    try std.testing.expectError(error.OutputTooSmall, notation.parseAlgorithmInto("R U R'", &buffer));
}

test "inverseAlgorithmInto reverses order and inverts each move" {
    const moves = [_]move_mod.Move{ .R, .U, .RPrime, .UPrime };
    var inverse_buffer: [moves.len]move_mod.Move = undefined;
    const inverse = try notation.inverseAlgorithmInto(&moves, &inverse_buffer);

    try std.testing.expectEqualSlices(move_mod.Move, &.{ .U, .R, .UPrime, .RPrime }, inverse);

    var state = cube.Cube.solved();
    state.applyMoves(&moves);
    state.applyMoves(inverse);
    try std.testing.expect(state.isSolved());
}

test "inverseAlgorithmInto supports exact in-place output" {
    var moves = [_]move_mod.Move{ .R, .U, .RPrime, .UPrime };
    const inverse = try notation.inverseAlgorithmInto(&moves, &moves);

    try std.testing.expectEqualSlices(move_mod.Move, &.{ .U, .R, .UPrime, .RPrime }, inverse);
    try std.testing.expectEqualSlices(move_mod.Move, inverse, &moves);
}

test "inverseAlgorithmInto rejects undersized output" {
    var buffer: [2]move_mod.Move = undefined;
    try std.testing.expectError(error.OutputTooSmall, notation.inverseAlgorithmInto(&.{ .R, .U, .RPrime }, &buffer));
}

test "parse format and inverse algorithm helpers round trip together" {
    const moves = try notation.parseAlgorithm(std.testing.allocator, "R2 F B' L D2");
    defer std.testing.allocator.free(moves);

    var format_buffer: [32]u8 = undefined;
    const formatted = try notation.formatAlgorithmInto(&format_buffer, moves);
    try std.testing.expectEqualStrings("R2 F B' L D2", formatted);

    var inverse_buffer: [5]move_mod.Move = undefined;
    const inverse = try notation.inverseAlgorithmInto(moves, &inverse_buffer);
    const inverse_text = try notation.formatAlgorithmInto(&format_buffer, inverse);
    try std.testing.expectEqualStrings("D2 L' B F' R2", inverse_text);
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
