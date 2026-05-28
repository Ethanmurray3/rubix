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

pub const ExpansionError = error{
    OutputTooSmall,
    UnsupportedExecutableToken,
};

pub const FormatError = error{
    OutputTooSmall,
};

pub const TurnAmount = enum {
    quarter,
    prime,
    double,
};

pub const TokenBase = enum {
    U,
    D,
    R,
    L,
    F,
    B,
    x,
    y,
    z,
    M,
    E,
    S,
    u,
    d,
    r,
    l,
    f,
    b,
};

pub const Token = struct {
    base: TokenBase,
    amount: TurnAmount = .quarter,

    pub fn isFaceTurn(self: Token) bool {
        return switch (self.base) {
            .U, .D, .R, .L, .F, .B => true,
            else => false,
        };
    }

    pub fn isRotation(self: Token) bool {
        return switch (self.base) {
            .x, .y, .z => true,
            else => false,
        };
    }

    pub fn isSliceOrWide(self: Token) bool {
        return switch (self.base) {
            .M, .E, .S, .u, .d, .r, .l, .f, .b => true,
            else => false,
        };
    }
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

pub fn parseToken(input: []const u8) ParseError!Token {
    if (input.len == 0) return ParseError.EmptyMove;
    if (input.len > 2) return ParseError.InvalidSuffix;

    const amount = if (input.len == 1)
        TurnAmount.quarter
    else switch (input[1]) {
        '\'' => TurnAmount.prime,
        '2' => TurnAmount.double,
        else => return ParseError.InvalidSuffix,
    };

    const base = switch (input[0]) {
        'U' => TokenBase.U,
        'D' => TokenBase.D,
        'R' => TokenBase.R,
        'L' => TokenBase.L,
        'F' => TokenBase.F,
        'B' => TokenBase.B,
        'x' => TokenBase.x,
        'y' => TokenBase.y,
        'z' => TokenBase.z,
        'M' => TokenBase.M,
        'E' => TokenBase.E,
        'S' => TokenBase.S,
        'u' => TokenBase.u,
        'd' => TokenBase.d,
        'r' => TokenBase.r,
        'l' => TokenBase.l,
        'f' => TokenBase.f,
        'b' => TokenBase.b,
        else => return ParseError.InvalidFace,
    };

    return .{
        .base = base,
        .amount = amount,
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

pub fn parseTokens(allocator: std.mem.Allocator, input: []const u8) ParseError![]Token {
    const count = countTokens(input);
    if (count == 0) return ParseError.EmptyAlgorithm;

    const tokens = try allocator.alloc(Token, count);
    errdefer allocator.free(tokens);

    const parsed = try parseTokensInto(input, tokens);
    std.debug.assert(parsed.len == count);
    return tokens;
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

pub fn parseTokensInto(input: []const u8, out: []Token) ParseError![]Token {
    var tokens_written: usize = 0;
    var tokens = std.mem.tokenizeAny(u8, input, " \t\r\n");
    while (tokens.next()) |token| {
        if (tokens_written == out.len) return ParseError.OutputTooSmall;
        out[tokens_written] = try parseToken(token);
        tokens_written += 1;
    }

    if (tokens_written == 0) return ParseError.EmptyAlgorithm;
    return out[0..tokens_written];
}

pub fn parseExecutableAlgorithm(allocator: std.mem.Allocator, input: []const u8) ![]move_mod.Move {
    const tokens = try parseTokens(allocator, input);
    defer allocator.free(tokens);

    const moves = try allocator.alloc(move_mod.Move, tokens.len);
    errdefer allocator.free(moves);

    const expanded = try expandTokensInto(tokens, moves);
    if (expanded.len == moves.len) return expanded;
    return try allocator.realloc(moves, expanded.len);
}

pub fn expandTokensInto(tokens: []const Token, out: []move_mod.Move) ExpansionError![]move_mod.Move {
    var frame = FaceFrame{};
    var moves_written: usize = 0;

    for (tokens) |token| {
        if (token.isRotation()) {
            frame.rotate(token.base, token.amount);
            continue;
        }
        if (!token.isFaceTurn()) return ExpansionError.UnsupportedExecutableToken;
        if (moves_written == out.len) return ExpansionError.OutputTooSmall;
        out[moves_written] = moveForFace(frame.map(token.base), token.amount);
        moves_written += 1;
    }

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

const Face = enum {
    up,
    down,
    right,
    left,
    front,
    back,
};

const FaceFrame = struct {
    up: Face = .up,
    down: Face = .down,
    right: Face = .right,
    left: Face = .left,
    front: Face = .front,
    back: Face = .back,

    fn map(self: FaceFrame, base: TokenBase) Face {
        return switch (base) {
            .U => self.up,
            .D => self.down,
            .R => self.right,
            .L => self.left,
            .F => self.front,
            .B => self.back,
            else => unreachable,
        };
    }

    fn rotate(self: *FaceFrame, base: TokenBase, amount: TurnAmount) void {
        const turns: u2 = switch (amount) {
            .quarter => 1,
            .double => 2,
            .prime => 3,
        };
        for (0..turns) |_| {
            self.rotateQuarter(base);
        }
    }

    fn rotateQuarter(self: *FaceFrame, base: TokenBase) void {
        const old = self.*;
        switch (base) {
            .x => {
                self.up = old.front;
                self.front = old.down;
                self.down = old.back;
                self.back = old.up;
            },
            .y => {
                self.front = old.left;
                self.right = old.front;
                self.back = old.right;
                self.left = old.back;
            },
            .z => {
                self.up = old.left;
                self.right = old.up;
                self.down = old.right;
                self.left = old.down;
            },
            else => unreachable,
        }
    }
};

fn moveForFace(face: Face, amount: TurnAmount) move_mod.Move {
    return switch (face) {
        .up => switch (amount) {
            .quarter => .U,
            .prime => .UPrime,
            .double => .U2,
        },
        .down => switch (amount) {
            .quarter => .D,
            .prime => .DPrime,
            .double => .D2,
        },
        .right => switch (amount) {
            .quarter => .R,
            .prime => .RPrime,
            .double => .R2,
        },
        .left => switch (amount) {
            .quarter => .L,
            .prime => .LPrime,
            .double => .L2,
        },
        .front => switch (amount) {
            .quarter => .F,
            .prime => .FPrime,
            .double => .F2,
        },
        .back => switch (amount) {
            .quarter => .B,
            .prime => .BPrime,
            .double => .B2,
        },
    };
}

fn countTokens(input: []const u8) usize {
    var count: usize = 0;
    var tokens = std.mem.tokenizeAny(u8, input, " \t\r\n");
    while (tokens.next()) |_| {
        count += 1;
    }
    return count;
}
