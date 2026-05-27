const std = @import("std");
const cube = @import("cube.zig");

pub const ParseError = error{
    EmptyMove,
    EmptyAlgorithm,
    InvalidFace,
    InvalidSuffix,
    OutputTooSmall,
    OutOfMemory,
};

pub fn parseMove(token: []const u8) ParseError!cube.Move {
    if (token.len == 0) return ParseError.EmptyMove;
    if (token.len > 2) return ParseError.InvalidSuffix;

    const face = token[0];
    const suffix: u8 = if (token.len == 1) 0 else token[1];
    if (suffix != 0 and suffix != '\'' and suffix != '2') return ParseError.InvalidSuffix;

    return switch (face) {
        'U' => switch (suffix) {
            0 => .U,
            '\'' => .UPrime,
            '2' => .U2,
            else => unreachable,
        },
        'D' => switch (suffix) {
            0 => .D,
            '\'' => .DPrime,
            '2' => .D2,
            else => unreachable,
        },
        'R' => switch (suffix) {
            0 => .R,
            '\'' => .RPrime,
            '2' => .R2,
            else => unreachable,
        },
        'L' => switch (suffix) {
            0 => .L,
            '\'' => .LPrime,
            '2' => .L2,
            else => unreachable,
        },
        'F' => switch (suffix) {
            0 => .F,
            '\'' => .FPrime,
            '2' => .F2,
            else => unreachable,
        },
        'B' => switch (suffix) {
            0 => .B,
            '\'' => .BPrime,
            '2' => .B2,
            else => unreachable,
        },
        else => ParseError.InvalidFace,
    };
}

pub fn parseAlgorithm(allocator: std.mem.Allocator, input: []const u8) ParseError![]cube.Move {
    const count = countTokens(input);
    if (count == 0) return ParseError.EmptyAlgorithm;

    const moves = try allocator.alloc(cube.Move, count);
    errdefer allocator.free(moves);

    const parsed = try parseAlgorithmInto(input, moves);
    std.debug.assert(parsed.len == count);
    return moves;
}

pub fn parseAlgorithmInto(input: []const u8, out: []cube.Move) ParseError![]cube.Move {
    var moves_written: usize = 0;
    var tokens = std.mem.tokenizeAny(u8, input, " \t\r\n");
    while (tokens.next()) |token| {
        if (moves_written == out.len) return ParseError.OutputTooSmall;
        out[moves_written] = try parseMove(token);
        moves_written += 1;
    }

    if (moves_written == 0) return ParseError.EmptyAlgorithm;
    return out[0..moves_written];
}

pub fn formatMove(move: cube.Move) []const u8 {
    return cube.moveName(move);
}

fn countTokens(input: []const u8) usize {
    var count: usize = 0;
    var tokens = std.mem.tokenizeAny(u8, input, " \t\r\n");
    while (tokens.next()) |_| {
        count += 1;
    }
    return count;
}
