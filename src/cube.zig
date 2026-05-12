const std = @import("std");

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
        return self.bits == Cube.solved().bits;
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

fn cornerColor(position: Position, chunk: u5, face: Face) Color {
    const faces = cornerPositionFaces(position);
    const colors = cornerColors(cornerFromChunk(chunk));
    const position_index = indexOfCornerFace(faces, face);
    const color_index = (position_index + cornerOrientation(chunk)) % 3;
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

comptime {
    std.debug.assert(@bitSizeOf(CubeBits) == 100);
    std.debug.assert(@sizeOf(Cube) == @sizeOf(CubeBits));
}
