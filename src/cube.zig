const std = @import("std");
const move_mod = @import("move.zig");

pub const Color = enum {
    white,
    yellow,
    green,
    blue,
    orange,
    red,
};

pub const Face = enum(u3) {
    up,
    down,
    front,
    back,
    left,
    right,
};

pub const FaceletCoord = struct {
    x: i2,
    y: i2,
    z: i2,
};

pub const Corner = enum(u3) {
    ufr,
    urb,
    ubl,
    ulf,
    dfr,
    drb,
    dbl,
    dlf,
};

pub const Edge = enum(u4) {
    uf,
    ur,
    ub,
    ul,
    fr,
    br,
    bl,
    fl,
    df,
    dr,
    db,
    dl,
};

pub const CubeBits = u100;

pub const Move = move_mod.Move;
pub const MoveAxis = move_mod.MoveAxis;
pub const moveAxis = move_mod.moveAxis;
pub const inverseMove = move_mod.inverseMove;
pub const moveName = move_mod.moveName;

pub const ValidationError = error{
    DuplicateCorner,
    MissingCorner,
    InvalidCornerOrientation,
    InvalidCornerTwist,
    InvalidEdgePiece,
    DuplicateEdge,
    MissingEdge,
    InvalidEdgeFlip,
    MismatchedPermutationParity,
};

pub const scramble_length = 20;

pub const Scramble = struct {
    moves: [scramble_length]Move,
};

const chunk_size = 5;
const chunk_mask: CubeBits = 0b11111;

const Position = enum(u5) {
    ufr = 0,
    urb = 1,
    ubl = 2,
    ulf = 3,
    dfr = 4,
    drb = 5,
    dbl = 6,
    dlf = 7,

    uf = 8,
    ur = 9,
    ub = 10,
    ul = 11,
    fr = 12,
    br = 13,
    bl = 14,
    fl = 15,
    df = 16,
    dr = 17,
    db = 18,
    dl = 19,
};

const solved_bits: CubeBits = Cube.solved().bits;

pub const Cube = struct {
    bits: CubeBits,

    pub fn solved() Cube {
        var bits: CubeBits = 0;

        bits = setChunk(bits, .ufr, makeCornerChunk(.ufr, 0b00));
        bits = setChunk(bits, .urb, makeCornerChunk(.urb, 0b00));
        bits = setChunk(bits, .ubl, makeCornerChunk(.ubl, 0b00));
        bits = setChunk(bits, .ulf, makeCornerChunk(.ulf, 0b00));
        bits = setChunk(bits, .dfr, makeCornerChunk(.dfr, 0b00));
        bits = setChunk(bits, .drb, makeCornerChunk(.drb, 0b00));
        bits = setChunk(bits, .dbl, makeCornerChunk(.dbl, 0b00));
        bits = setChunk(bits, .dlf, makeCornerChunk(.dlf, 0b00));

        bits = setChunk(bits, .uf, makeEdgeChunk(.uf, 0b0));
        bits = setChunk(bits, .ur, makeEdgeChunk(.ur, 0b0));
        bits = setChunk(bits, .ub, makeEdgeChunk(.ub, 0b0));
        bits = setChunk(bits, .ul, makeEdgeChunk(.ul, 0b0));
        bits = setChunk(bits, .fr, makeEdgeChunk(.fr, 0b0));
        bits = setChunk(bits, .br, makeEdgeChunk(.br, 0b0));
        bits = setChunk(bits, .bl, makeEdgeChunk(.bl, 0b0));
        bits = setChunk(bits, .fl, makeEdgeChunk(.fl, 0b0));
        bits = setChunk(bits, .df, makeEdgeChunk(.df, 0b0));
        bits = setChunk(bits, .dr, makeEdgeChunk(.dr, 0b0));
        bits = setChunk(bits, .db, makeEdgeChunk(.db, 0b0));
        bits = setChunk(bits, .dl, makeEdgeChunk(.dl, 0b0));

        return .{ .bits = bits };
    }

    pub fn isSolved(self: Cube) bool {
        return self.bits == solved_bits;
    }

    pub fn validate(self: Cube) ValidationError!void {
        const corner_positions = [_]Position{
            .ufr,
            .urb,
            .ubl,
            .ulf,
            .dfr,
            .drb,
            .dbl,
            .dlf,
        };
        const edge_positions = [_]Position{
            .uf,
            .ur,
            .ub,
            .ul,
            .fr,
            .br,
            .bl,
            .fl,
            .df,
            .dr,
            .db,
            .dl,
        };

        var seen_corners: u8 = 0;
        var corner_orientation_sum: u8 = 0;
        var corner_permutation: [8]u4 = undefined;
        for (corner_positions, 0..) |position, index| {
            const chunk = getChunk(self.bits, position);
            const piece: u3 = @truncate(chunk & 0b00111);
            const orientation = cornerOrientation(chunk);
            if (orientation >= 3) return ValidationError.InvalidCornerOrientation;

            const piece_mask = @as(u8, 1) << piece;
            if ((seen_corners & piece_mask) != 0) return ValidationError.DuplicateCorner;
            seen_corners |= piece_mask;
            corner_orientation_sum += orientation;
            corner_permutation[index] = piece;
        }
        if (seen_corners != 0xff) return ValidationError.MissingCorner;
        if (corner_orientation_sum % 3 != 0) return ValidationError.InvalidCornerTwist;

        var seen_edges: u12 = 0;
        var edge_orientation_sum: u8 = 0;
        var edge_permutation: [12]u4 = undefined;
        for (edge_positions, 0..) |position, index| {
            const chunk = getChunk(self.bits, position);
            const piece: u4 = @truncate(chunk & 0b01111);
            if (piece >= 12) return ValidationError.InvalidEdgePiece;

            const orientation = edgeOrientation(chunk);
            const piece_mask = @as(u12, 1) << piece;
            if ((seen_edges & piece_mask) != 0) return ValidationError.DuplicateEdge;
            seen_edges |= piece_mask;
            edge_orientation_sum += orientation;
            edge_permutation[index] = piece;
        }
        if (seen_edges != 0xfff) return ValidationError.MissingEdge;
        if (edge_orientation_sum % 2 != 0) return ValidationError.InvalidEdgeFlip;
        if (permutationParity(&corner_permutation) != permutationParity(&edge_permutation)) {
            return ValidationError.MismatchedPermutationParity;
        }
    }

    pub fn scramble(random: std.Random) Scramble {
        var result: Scramble = undefined;
        var previous: ?Move = null;

        for (&result.moves) |*move| {
            while (true) {
                const candidate = random.enumValue(Move);
                if (previous == null or moveAxis(candidate) != moveAxis(previous.?)) {
                    move.* = candidate;
                    break;
                }
            }
            previous = move.*;
        }

        return result;
    }

    pub fn applyMoves(self: *Cube, moves: []const Move) void {
        for (moves) |move| {
            self.applyMove(move);
        }
    }

    pub fn applyMove(self: *Cube, move: Move) void {
        switch (move) {
            .U => self.turnU(),
            .UPrime => self.turnUPrime(),
            .U2 => {
                self.turnU();
                self.turnU();
            },
            .D => self.turnD(),
            .DPrime => self.turnDPrime(),
            .D2 => {
                self.turnD();
                self.turnD();
            },
            .R => self.turnR(),
            .RPrime => self.turnRPrime(),
            .R2 => {
                self.turnR();
                self.turnR();
            },
            .L => self.turnL(),
            .LPrime => self.turnLPrime(),
            .L2 => {
                self.turnL();
                self.turnL();
            },
            .F => self.turnF(),
            .FPrime => self.turnFPrime(),
            .F2 => {
                self.turnF();
                self.turnF();
            },
            .B => self.turnB(),
            .BPrime => self.turnBPrime(),
            .B2 => {
                self.turnB();
                self.turnB();
            },
        }
    }

    pub fn turnU(self: *Cube) void {
        const old = self.bits;
        var new = old;

        new = setChunk(new, .ul, getChunk(old, .uf));
        new = setChunk(new, .ub, getChunk(old, .ul));
        new = setChunk(new, .ur, getChunk(old, .ub));
        new = setChunk(new, .uf, getChunk(old, .ur));

        new = setChunk(new, .ulf, getChunk(old, .ufr));
        new = setChunk(new, .ubl, getChunk(old, .ulf));
        new = setChunk(new, .urb, getChunk(old, .ubl));
        new = setChunk(new, .ufr, getChunk(old, .urb));

        self.bits = new;
    }

    pub fn turnUPrime(self: *Cube) void {
        const old = self.bits;
        var new = old;

        new = setChunk(new, .ur, getChunk(old, .uf));
        new = setChunk(new, .ub, getChunk(old, .ur));
        new = setChunk(new, .ul, getChunk(old, .ub));
        new = setChunk(new, .uf, getChunk(old, .ul));

        new = setChunk(new, .urb, getChunk(old, .ufr));
        new = setChunk(new, .ubl, getChunk(old, .urb));
        new = setChunk(new, .ulf, getChunk(old, .ubl));
        new = setChunk(new, .ufr, getChunk(old, .ulf));

        self.bits = new;
    }

    pub fn turnD(self: *Cube) void {
        const old = self.bits;
        var new = old;

        new = setChunk(new, .dr, getChunk(old, .df));
        new = setChunk(new, .db, getChunk(old, .dr));
        new = setChunk(new, .dl, getChunk(old, .db));
        new = setChunk(new, .df, getChunk(old, .dl));

        new = setChunk(new, .drb, getChunk(old, .dfr));
        new = setChunk(new, .dbl, getChunk(old, .drb));
        new = setChunk(new, .dlf, getChunk(old, .dbl));
        new = setChunk(new, .dfr, getChunk(old, .dlf));

        self.bits = new;
    }

    pub fn turnDPrime(self: *Cube) void {
        const old = self.bits;
        var new = old;

        new = setChunk(new, .dl, getChunk(old, .df));
        new = setChunk(new, .db, getChunk(old, .dl));
        new = setChunk(new, .dr, getChunk(old, .db));
        new = setChunk(new, .df, getChunk(old, .dr));

        new = setChunk(new, .dlf, getChunk(old, .dfr));
        new = setChunk(new, .dbl, getChunk(old, .dlf));
        new = setChunk(new, .drb, getChunk(old, .dbl));
        new = setChunk(new, .dfr, getChunk(old, .drb));

        self.bits = new;
    }

    pub fn turnR(self: *Cube) void {
        const old = self.bits;
        var new = old;

        new = setChunk(new, .br, getChunk(old, .ur));
        new = setChunk(new, .dr, getChunk(old, .br));
        new = setChunk(new, .fr, getChunk(old, .dr));
        new = setChunk(new, .ur, getChunk(old, .fr));

        new = setChunk(new, .urb, twistCornerChunk(getChunk(old, .ufr), 1));
        new = setChunk(new, .drb, twistCornerChunk(getChunk(old, .urb), 2));
        new = setChunk(new, .dfr, twistCornerChunk(getChunk(old, .drb), 1));
        new = setChunk(new, .ufr, twistCornerChunk(getChunk(old, .dfr), 2));

        self.bits = new;
    }

    pub fn turnRPrime(self: *Cube) void {
        const old = self.bits;
        var new = old;

        new = setChunk(new, .fr, getChunk(old, .ur));
        new = setChunk(new, .dr, getChunk(old, .fr));
        new = setChunk(new, .br, getChunk(old, .dr));
        new = setChunk(new, .ur, getChunk(old, .br));

        new = setChunk(new, .dfr, twistCornerChunk(getChunk(old, .ufr), 1));
        new = setChunk(new, .drb, twistCornerChunk(getChunk(old, .dfr), 2));
        new = setChunk(new, .urb, twistCornerChunk(getChunk(old, .drb), 1));
        new = setChunk(new, .ufr, twistCornerChunk(getChunk(old, .urb), 2));

        self.bits = new;
    }

    pub fn turnL(self: *Cube) void {
        const old = self.bits;
        var new = old;

        new = setChunk(new, .fl, getChunk(old, .ul));
        new = setChunk(new, .dl, getChunk(old, .fl));
        new = setChunk(new, .bl, getChunk(old, .dl));
        new = setChunk(new, .ul, getChunk(old, .bl));

        new = setChunk(new, .dlf, twistCornerChunk(getChunk(old, .ulf), 2));
        new = setChunk(new, .dbl, twistCornerChunk(getChunk(old, .dlf), 1));
        new = setChunk(new, .ubl, twistCornerChunk(getChunk(old, .dbl), 2));
        new = setChunk(new, .ulf, twistCornerChunk(getChunk(old, .ubl), 1));

        self.bits = new;
    }

    pub fn turnLPrime(self: *Cube) void {
        const old = self.bits;
        var new = old;

        new = setChunk(new, .bl, getChunk(old, .ul));
        new = setChunk(new, .dl, getChunk(old, .bl));
        new = setChunk(new, .fl, getChunk(old, .dl));
        new = setChunk(new, .ul, getChunk(old, .fl));

        new = setChunk(new, .ubl, twistCornerChunk(getChunk(old, .ulf), 2));
        new = setChunk(new, .dbl, twistCornerChunk(getChunk(old, .ubl), 1));
        new = setChunk(new, .dlf, twistCornerChunk(getChunk(old, .dbl), 2));
        new = setChunk(new, .ulf, twistCornerChunk(getChunk(old, .dlf), 1));

        self.bits = new;
    }

    pub fn turnF(self: *Cube) void {
        const old = self.bits;
        var new = old;

        new = setChunk(new, .fr, flipEdgeChunk(getChunk(old, .uf)));
        new = setChunk(new, .df, flipEdgeChunk(getChunk(old, .fr)));
        new = setChunk(new, .fl, flipEdgeChunk(getChunk(old, .df)));
        new = setChunk(new, .uf, flipEdgeChunk(getChunk(old, .fl)));

        new = setChunk(new, .dfr, twistCornerChunk(getChunk(old, .ufr), 2));
        new = setChunk(new, .dlf, twistCornerChunk(getChunk(old, .dfr), 1));
        new = setChunk(new, .ulf, twistCornerChunk(getChunk(old, .dlf), 2));
        new = setChunk(new, .ufr, twistCornerChunk(getChunk(old, .ulf), 1));

        self.bits = new;
    }

    pub fn turnFPrime(self: *Cube) void {
        const old = self.bits;
        var new = old;

        new = setChunk(new, .fl, flipEdgeChunk(getChunk(old, .uf)));
        new = setChunk(new, .df, flipEdgeChunk(getChunk(old, .fl)));
        new = setChunk(new, .fr, flipEdgeChunk(getChunk(old, .df)));
        new = setChunk(new, .uf, flipEdgeChunk(getChunk(old, .fr)));

        new = setChunk(new, .ulf, twistCornerChunk(getChunk(old, .ufr), 2));
        new = setChunk(new, .dlf, twistCornerChunk(getChunk(old, .ulf), 1));
        new = setChunk(new, .dfr, twistCornerChunk(getChunk(old, .dlf), 2));
        new = setChunk(new, .ufr, twistCornerChunk(getChunk(old, .dfr), 1));

        self.bits = new;
    }

    pub fn turnB(self: *Cube) void {
        const old = self.bits;
        var new = old;

        new = setChunk(new, .bl, flipEdgeChunk(getChunk(old, .ub)));
        new = setChunk(new, .db, flipEdgeChunk(getChunk(old, .bl)));
        new = setChunk(new, .br, flipEdgeChunk(getChunk(old, .db)));
        new = setChunk(new, .ub, flipEdgeChunk(getChunk(old, .br)));

        new = setChunk(new, .ubl, twistCornerChunk(getChunk(old, .urb), 1));
        new = setChunk(new, .dbl, twistCornerChunk(getChunk(old, .ubl), 2));
        new = setChunk(new, .drb, twistCornerChunk(getChunk(old, .dbl), 1));
        new = setChunk(new, .urb, twistCornerChunk(getChunk(old, .drb), 2));

        self.bits = new;
    }

    pub fn turnBPrime(self: *Cube) void {
        const old = self.bits;
        var new = old;

        new = setChunk(new, .br, flipEdgeChunk(getChunk(old, .ub)));
        new = setChunk(new, .db, flipEdgeChunk(getChunk(old, .br)));
        new = setChunk(new, .bl, flipEdgeChunk(getChunk(old, .db)));
        new = setChunk(new, .ub, flipEdgeChunk(getChunk(old, .bl)));

        new = setChunk(new, .drb, twistCornerChunk(getChunk(old, .urb), 1));
        new = setChunk(new, .dbl, twistCornerChunk(getChunk(old, .drb), 2));
        new = setChunk(new, .ubl, twistCornerChunk(getChunk(old, .dbl), 1));
        new = setChunk(new, .urb, twistCornerChunk(getChunk(old, .ubl), 2));

        self.bits = new;
    }

    pub fn facelet(self: Cube, face: Face, index: usize) Color {
        std.debug.assert(index < 9);

        return switch (face) {
            .up => switch (index) {
                0 => cornerColor(.ubl, getChunk(self.bits, .ubl), face),
                1 => edgeColor(.ub, getChunk(self.bits, .ub), face),
                2 => cornerColor(.urb, getChunk(self.bits, .urb), face),
                3 => edgeColor(.ul, getChunk(self.bits, .ul), face),
                4 => .white,
                5 => edgeColor(.ur, getChunk(self.bits, .ur), face),
                6 => cornerColor(.ulf, getChunk(self.bits, .ulf), face),
                7 => edgeColor(.uf, getChunk(self.bits, .uf), face),
                8 => cornerColor(.ufr, getChunk(self.bits, .ufr), face),
                else => unreachable,
            },
            .down => switch (index) {
                0 => cornerColor(.dlf, getChunk(self.bits, .dlf), face),
                1 => edgeColor(.df, getChunk(self.bits, .df), face),
                2 => cornerColor(.dfr, getChunk(self.bits, .dfr), face),
                3 => edgeColor(.dl, getChunk(self.bits, .dl), face),
                4 => .yellow,
                5 => edgeColor(.dr, getChunk(self.bits, .dr), face),
                6 => cornerColor(.dbl, getChunk(self.bits, .dbl), face),
                7 => edgeColor(.db, getChunk(self.bits, .db), face),
                8 => cornerColor(.drb, getChunk(self.bits, .drb), face),
                else => unreachable,
            },
            .front => switch (index) {
                0 => cornerColor(.ulf, getChunk(self.bits, .ulf), face),
                1 => edgeColor(.uf, getChunk(self.bits, .uf), face),
                2 => cornerColor(.ufr, getChunk(self.bits, .ufr), face),
                3 => edgeColor(.fl, getChunk(self.bits, .fl), face),
                4 => .green,
                5 => edgeColor(.fr, getChunk(self.bits, .fr), face),
                6 => cornerColor(.dlf, getChunk(self.bits, .dlf), face),
                7 => edgeColor(.df, getChunk(self.bits, .df), face),
                8 => cornerColor(.dfr, getChunk(self.bits, .dfr), face),
                else => unreachable,
            },
            .back => switch (index) {
                0 => cornerColor(.urb, getChunk(self.bits, .urb), face),
                1 => edgeColor(.ub, getChunk(self.bits, .ub), face),
                2 => cornerColor(.ubl, getChunk(self.bits, .ubl), face),
                3 => edgeColor(.br, getChunk(self.bits, .br), face),
                4 => .blue,
                5 => edgeColor(.bl, getChunk(self.bits, .bl), face),
                6 => cornerColor(.drb, getChunk(self.bits, .drb), face),
                7 => edgeColor(.db, getChunk(self.bits, .db), face),
                8 => cornerColor(.dbl, getChunk(self.bits, .dbl), face),
                else => unreachable,
            },
            .left => switch (index) {
                0 => cornerColor(.ubl, getChunk(self.bits, .ubl), face),
                1 => edgeColor(.ul, getChunk(self.bits, .ul), face),
                2 => cornerColor(.ulf, getChunk(self.bits, .ulf), face),
                3 => edgeColor(.bl, getChunk(self.bits, .bl), face),
                4 => .orange,
                5 => edgeColor(.fl, getChunk(self.bits, .fl), face),
                6 => cornerColor(.dbl, getChunk(self.bits, .dbl), face),
                7 => edgeColor(.dl, getChunk(self.bits, .dl), face),
                8 => cornerColor(.dlf, getChunk(self.bits, .dlf), face),
                else => unreachable,
            },
            .right => switch (index) {
                0 => cornerColor(.ufr, getChunk(self.bits, .ufr), face),
                1 => edgeColor(.ur, getChunk(self.bits, .ur), face),
                2 => cornerColor(.urb, getChunk(self.bits, .urb), face),
                3 => edgeColor(.fr, getChunk(self.bits, .fr), face),
                4 => .red,
                5 => edgeColor(.br, getChunk(self.bits, .br), face),
                6 => cornerColor(.dfr, getChunk(self.bits, .dfr), face),
                7 => edgeColor(.dr, getChunk(self.bits, .dr), face),
                8 => cornerColor(.drb, getChunk(self.bits, .drb), face),
                else => unreachable,
            },
        };
    }
};

fn getChunk(bits: CubeBits, position: Position) u5 {
    const shift: u7 = @as(u7, @intFromEnum(position)) * chunk_size;
    return @truncate((bits >> shift) & chunk_mask);
}

fn setChunk(bits: CubeBits, position: Position, chunk: u5) CubeBits {
    const shift: u7 = @as(u7, @intFromEnum(position)) * chunk_size;
    const clear_mask = ~(chunk_mask << shift);
    return (bits & clear_mask) | (@as(CubeBits, chunk) << shift);
}

pub fn moveFace(move: Move) Face {
    return switch (move) {
        .U, .UPrime, .U2 => .up,
        .D, .DPrime, .D2 => .down,
        .R, .RPrime, .R2 => .right,
        .L, .LPrime, .L2 => .left,
        .F, .FPrime, .F2 => .front,
        .B, .BPrime, .B2 => .back,
    };
}

pub fn faceletCoord(face: Face, index: usize) FaceletCoord {
    std.debug.assert(index < 9);

    const row = index / 3;
    const col = index % 3;
    const x = axisCoordFromGrid(col);
    const y = axisCoordFromGrid(2 - row);
    const z = axisCoordFromGrid(2 - row);

    return switch (face) {
        .up => .{
            .x = x,
            .y = 1,
            .z = axisCoordFromGrid(row),
        },
        .down => .{
            .x = x,
            .y = -1,
            .z = z,
        },
        .front => .{
            .x = x,
            .y = y,
            .z = 1,
        },
        .back => .{
            .x = axisCoordFromGrid(2 - col),
            .y = y,
            .z = -1,
        },
        .left => .{
            .x = -1,
            .y = y,
            .z = x,
        },
        .right => .{
            .x = 1,
            .y = y,
            .z = axisCoordFromGrid(2 - col),
        },
    };
}

pub fn faceletIndex(face: Face, coord: FaceletCoord) usize {
    assertAxisCoord(coord.x);
    assertAxisCoord(coord.y);
    assertAxisCoord(coord.z);

    return switch (face) {
        .up => block: {
            std.debug.assert(coord.y == 1);
            break :block faceletIndexFromRowCol(gridFromAxisCoord(coord.z), gridFromAxisCoord(coord.x));
        },
        .down => block: {
            std.debug.assert(coord.y == -1);
            break :block faceletIndexFromRowCol(gridFromAxisCoord(-coord.z), gridFromAxisCoord(coord.x));
        },
        .front => block: {
            std.debug.assert(coord.z == 1);
            break :block faceletIndexFromRowCol(gridFromAxisCoord(-coord.y), gridFromAxisCoord(coord.x));
        },
        .back => block: {
            std.debug.assert(coord.z == -1);
            break :block faceletIndexFromRowCol(gridFromAxisCoord(-coord.y), gridFromAxisCoord(-coord.x));
        },
        .left => block: {
            std.debug.assert(coord.x == -1);
            break :block faceletIndexFromRowCol(gridFromAxisCoord(-coord.y), gridFromAxisCoord(coord.z));
        },
        .right => block: {
            std.debug.assert(coord.x == 1);
            break :block faceletIndexFromRowCol(gridFromAxisCoord(-coord.y), gridFromAxisCoord(-coord.z));
        },
    };
}

fn axisCoordFromGrid(value: usize) i2 {
    std.debug.assert(value < 3);
    return @intCast(@as(isize, @intCast(value)) - 1);
}

fn gridFromAxisCoord(value: i2) usize {
    assertAxisCoord(value);
    return @intCast(@as(isize, value) + 1);
}

fn faceletIndexFromRowCol(row: usize, col: usize) usize {
    std.debug.assert(row < 3);
    std.debug.assert(col < 3);
    return row * 3 + col;
}

fn assertAxisCoord(value: i2) void {
    std.debug.assert(value >= -1 and value <= 1);
}

fn makeCornerChunk(piece: Corner, orientation: u2) u5 {
    return @as(u5, @intFromEnum(piece)) | (@as(u5, orientation) << 3);
}

fn makeEdgeChunk(piece: Edge, orientation: u1) u5 {
    return @as(u5, @intFromEnum(piece)) | (@as(u5, orientation) << 4);
}

fn twistCornerChunk(chunk: u5, amount: u2) u5 {
    const orientation = @as(u3, cornerOrientation(chunk)) + @as(u3, amount);
    return makeCornerChunk(cornerFromChunk(chunk), @intCast(orientation % 3));
}

fn flipEdgeChunk(chunk: u5) u5 {
    return makeEdgeChunk(edgeFromChunk(chunk), edgeOrientation(chunk) ^ 1);
}

fn cornerFromChunk(chunk: u5) Corner {
    return @enumFromInt(@as(u3, @truncate(chunk & 0b00111)));
}

fn cornerOrientation(chunk: u5) u2 {
    return @truncate(chunk >> 3);
}

fn edgeFromChunk(chunk: u5) Edge {
    return @enumFromInt(@as(u4, @truncate(chunk & 0b01111)));
}

fn edgeOrientation(chunk: u5) u1 {
    return @truncate(chunk >> 4);
}

fn permutationParity(permutation: []const u4) bool {
    var odd = false;
    for (permutation, 0..) |piece, index| {
        for (permutation[index + 1 ..]) |later_piece| {
            if (piece > later_piece) odd = !odd;
        }
    }
    return odd;
}

fn cornerColor(position: Position, chunk: u5, face: Face) Color {
    const faces = cornerPositionFaces(position);
    const colors = cornerColors(cornerFromChunk(chunk));
    const position_index = indexOfCornerFace(faces, face);
    const color_index = (@as(u3, position_index) + @as(u3, cornerOrientation(chunk))) % 3;
    return colors[@intCast(color_index)];
}

fn edgeColor(position: Position, chunk: u5, face: Face) Color {
    const faces = edgePositionFaces(position);
    const colors = edgeColors(edgeFromChunk(chunk));
    const position_index = indexOfEdgeFace(faces, face);
    const color_index = position_index ^ edgeOrientation(chunk);
    return colors[@intCast(color_index)];
}

fn indexOfCornerFace(faces: [3]Face, face: Face) u2 {
    for (faces, 0..) |candidate, index| {
        if (candidate == face) return @intCast(index);
    }
    unreachable;
}

fn indexOfEdgeFace(faces: [2]Face, face: Face) u1 {
    for (faces, 0..) |candidate, index| {
        if (candidate == face) return @intCast(index);
    }
    unreachable;
}

fn cornerPositionFaces(position: Position) [3]Face {
    return switch (position) {
        .ufr => .{ .up, .front, .right },
        .urb => .{ .up, .right, .back },
        .ubl => .{ .up, .back, .left },
        .ulf => .{ .up, .left, .front },
        .dfr => .{ .down, .right, .front },
        .drb => .{ .down, .back, .right },
        .dbl => .{ .down, .left, .back },
        .dlf => .{ .down, .front, .left },
        else => unreachable,
    };
}

fn cornerColors(corner: Corner) [3]Color {
    return switch (corner) {
        .ufr => .{ .white, .green, .red },
        .urb => .{ .white, .red, .blue },
        .ubl => .{ .white, .blue, .orange },
        .ulf => .{ .white, .orange, .green },
        .dfr => .{ .yellow, .red, .green },
        .drb => .{ .yellow, .blue, .red },
        .dbl => .{ .yellow, .orange, .blue },
        .dlf => .{ .yellow, .green, .orange },
    };
}

fn edgePositionFaces(position: Position) [2]Face {
    return switch (position) {
        .uf => .{ .up, .front },
        .ur => .{ .up, .right },
        .ub => .{ .up, .back },
        .ul => .{ .up, .left },
        .fr => .{ .front, .right },
        .br => .{ .back, .right },
        .bl => .{ .back, .left },
        .fl => .{ .front, .left },
        .df => .{ .down, .front },
        .dr => .{ .down, .right },
        .db => .{ .down, .back },
        .dl => .{ .down, .left },
        else => unreachable,
    };
}

fn edgeColors(edge: Edge) [2]Color {
    return switch (edge) {
        .uf => .{ .white, .green },
        .ur => .{ .white, .red },
        .ub => .{ .white, .blue },
        .ul => .{ .white, .orange },
        .fr => .{ .green, .red },
        .br => .{ .blue, .red },
        .bl => .{ .blue, .orange },
        .fl => .{ .green, .orange },
        .df => .{ .yellow, .green },
        .dr => .{ .yellow, .red },
        .db => .{ .yellow, .blue },
        .dl => .{ .yellow, .orange },
    };
}
