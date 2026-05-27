const std = @import("std");
const move_mod = @import("move.zig");

pub const ParseError = error{
    EmptyMove,
    EmptyAlgorithm,
    InvalidFace,
    InvalidSuffix,
    OutputTooSmall,
    OutOfMemory,
};

pub const FormatError = error{
    OutputTooSmall,
};

pub fn parseMove(token: []const u8) ParseError!move_mod.Move {
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

pub fn parseAlgorithm(allocator: std.mem.Allocator, input: []const u8) ParseError![]move_mod.Move {
    const count = countTokens(input);
    if (count == 0) return ParseError.EmptyAlgorithm;

    const moves = try allocator.alloc(move_mod.Move, count);
    errdefer allocator.free(moves);

    const parsed = try parseAlgorithmInto(input, moves);
    std.debug.assert(parsed.len == count);
    return moves;
}

pub fn parseAlgorithmInto(input: []const u8, out: []move_mod.Move) ParseError![]move_mod.Move {
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

pub fn formatMove(move: move_mod.Move) []const u8 {
    return move_mod.moveName(move);
}

pub fn formatAlgorithmInto(buffer: []u8, moves: []const move_mod.Move) FormatError![]const u8 {
    var position: usize = 0;
    for (moves, 0..) |move, index| {
        const separator_len: usize = if (index == 0) 0 else 1;
        const name = formatMove(move);
        if (position + separator_len + name.len > buffer.len) return FormatError.OutputTooSmall;

        if (separator_len != 0) {
            buffer[position] = ' ';
            position += 1;
        }
        std.mem.copyForwards(u8, buffer[position .. position + name.len], name);
        position += name.len;
    }

    return buffer[0..position];
}

pub fn inverseAlgorithmInto(moves: []const move_mod.Move, out: []move_mod.Move) FormatError![]move_mod.Move {
    if (out.len < moves.len) return FormatError.OutputTooSmall;

    if (moves.ptr == out.ptr) {
        var left: usize = 0;
        var right = moves.len;
        while (left < right) {
            right -= 1;

            const left_move = out[left];
            out[left] = move_mod.inverseMove(out[right]);
            out[right] = move_mod.inverseMove(left_move);

            left += 1;
        }
        return out[0..moves.len];
    }

    for (moves, 0..) |move, index| {
        out[moves.len - 1 - index] = move_mod.inverseMove(move);
    }

    return out[0..moves.len];
}

fn countTokens(input: []const u8) usize {
    var count: usize = 0;
    var tokens = std.mem.tokenizeAny(u8, input, " \t\r\n");
    while (tokens.next()) |_| {
        count += 1;
    }
    return count;
}
