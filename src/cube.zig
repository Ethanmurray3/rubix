const move_mod = @import("move.zig");

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

pub const CornerPosition = enum(u3) {
    ufr,
    urb,
    ubl,
    ulf,
    dfr,
    drb,
    dbl,
    dlf,
};

pub const EdgePosition = enum(u4) {
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

pub const CornerState = struct {
    piece: Corner,
    orientation: u2,

    pub fn isOriented(self: CornerState) bool {
        return self.orientation == 0;
    }
};

pub const EdgeState = struct {
    piece: Edge,
    orientation: u1,

    pub fn isOriented(self: EdgeState) bool {
        return self.orientation == 0;
    }

    pub fn isFlipped(self: EdgeState) bool {
        return self.orientation != 0;
    }
};

pub const CubeBits = u100;

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

const up_corner_positions = [_]CornerPosition{ .ufr, .urb, .ubl, .ulf };
const up_edge_positions = [_]EdgePosition{ .uf, .ur, .ub, .ul };

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

    pub fn cornerAt(self: Cube, position: CornerPosition) CornerState {
        return self.checkedCornerAt(position) catch unreachable;
    }

    pub fn checkedCornerAt(self: Cube, position: CornerPosition) ValidationError!CornerState {
        const chunk = getChunk(self.bits, cornerPosition(position));
        const orientation = cornerOrientation(chunk);
        if (orientation >= 3) return ValidationError.InvalidCornerOrientation;

        return .{
            .piece = cornerFromChunk(chunk),
            .orientation = orientation,
        };
    }

    pub fn edgeAt(self: Cube, position: EdgePosition) EdgeState {
        return self.checkedEdgeAt(position) catch unreachable;
    }

    pub fn checkedEdgeAt(self: Cube, position: EdgePosition) ValidationError!EdgeState {
        const chunk = getChunk(self.bits, edgePosition(position));
        const piece: u4 = @truncate(chunk & 0b01111);
        if (piece >= 12) return ValidationError.InvalidEdgePiece;

        return .{
            .piece = @enumFromInt(piece),
            .orientation = edgeOrientation(chunk),
        };
    }

    pub fn isCornerSolved(self: Cube, position: CornerPosition) bool {
        const state = self.cornerAt(position);
        return state.piece == cornerPieceForPosition(position) and state.isOriented();
    }

    pub fn isEdgeSolved(self: Cube, position: EdgePosition) bool {
        const state = self.edgeAt(position);
        return state.piece == edgePieceForPosition(position) and state.isOriented();
    }

    pub fn isUpLayerOriented(self: Cube) bool {
        inline for (up_corner_positions) |position| {
            if (!self.cornerAt(position).isOriented()) return false;
        }
        inline for (up_edge_positions) |position| {
            if (!self.edgeAt(position).isOriented()) return false;
        }
        return true;
    }

    pub fn isUpLayerPermutationSolved(self: Cube) bool {
        inline for (up_corner_positions) |position| {
            if (self.cornerAt(position).piece != cornerPieceForPosition(position)) return false;
        }
        inline for (up_edge_positions) |position| {
            if (self.edgeAt(position).piece != edgePieceForPosition(position)) return false;
        }
        return true;
    }

    pub fn isUpLayerSolved(self: Cube) bool {
        inline for (up_corner_positions) |position| {
            if (!self.isCornerSolved(position)) return false;
        }
        inline for (up_edge_positions) |position| {
            if (!self.isEdgeSolved(position)) return false;
        }
        return true;
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

    pub fn applyMoves(self: *Cube, moves: []const move_mod.Move) void {
        for (moves) |move| {
            self.applyMove(move);
        }
    }

    pub fn applyMove(self: *Cube, move: move_mod.Move) void {
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
};

fn getChunk(bits: CubeBits, position: Position) u5 {
    const shift: u7 = @as(u7, @intFromEnum(position)) * chunk_size;
    return @truncate((bits >> shift) & chunk_mask);
}

fn cornerPosition(position: CornerPosition) Position {
    return switch (position) {
        .ufr => .ufr,
        .urb => .urb,
        .ubl => .ubl,
        .ulf => .ulf,
        .dfr => .dfr,
        .drb => .drb,
        .dbl => .dbl,
        .dlf => .dlf,
    };
}

fn edgePosition(position: EdgePosition) Position {
    return switch (position) {
        .uf => .uf,
        .ur => .ur,
        .ub => .ub,
        .ul => .ul,
        .fr => .fr,
        .br => .br,
        .bl => .bl,
        .fl => .fl,
        .df => .df,
        .dr => .dr,
        .db => .db,
        .dl => .dl,
    };
}

fn cornerPieceForPosition(position: CornerPosition) Corner {
    return @enumFromInt(@intFromEnum(position));
}

fn edgePieceForPosition(position: EdgePosition) Edge {
    return @enumFromInt(@intFromEnum(position));
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

fn permutationParity(permutation: []const u4) bool {
    var odd = false;
    for (permutation, 0..) |piece, index| {
        for (permutation[index + 1 ..]) |later_piece| {
            if (piece > later_piece) odd = !odd;
        }
    }
    return odd;
}
