const cfop = @import("cfop.zig");
const cfop_cases = @import("cfop_cases.zig");
const cube_mod = @import("cube.zig");

pub const Auf = enum(u2) {
    none = 0,
    u = 1,
    u2 = 2,
    u_prime = 3,
};

pub const KnownCase = struct {
    case: *const cfop_cases.CaseDefinition,
    auf: Auf,
};

pub const Result = union(enum) {
    solved: Auf,
    known: KnownCase,
    unsupported,
};

pub fn recognizeTwoLook(cube: cube_mod.Cube) Result {
    if (!isF2LSolved(cube)) return .unsupported;

    if (solvedAuf(cube)) |auf| return .{ .solved = auf };

    const stage = if (cube.isUpLayerOriented()) cfop.Stage.pll else cfop.Stage.oll;
    const target = lastLayerSignature(cube);

    for (&cfop_cases.two_look_cases) |*case| {
        if (case.stage != stage) continue;

        var candidate = cube_mod.Cube.solved();
        case.setup.apply(&candidate);

        if (matchingAuf(target, candidate)) |auf| {
            return .{ .known = .{ .case = case, .auf = auf } };
        }
    }

    return .unsupported;
}

fn matchingAuf(target: LastLayerSignature, candidate: cube_mod.Cube) ?Auf {
    inline for (.{ Auf.none, .u, .u2, .u_prime }) |auf| {
        var variant = candidate;
        applyAuf(&variant, auf);
        if (target.eql(lastLayerSignature(variant))) return auf;
    }
    return null;
}

fn solvedAuf(cube: cube_mod.Cube) ?Auf {
    inline for (.{ Auf.none, .u, .u2, .u_prime }) |auf| {
        var variant = cube;
        applyAuf(&variant, auf);
        if (variant.isSolved()) return auf;
    }
    return null;
}

fn applyAuf(cube: *cube_mod.Cube, auf: Auf) void {
    switch (auf) {
        .none => {},
        .u => cube.applyMove(.U),
        .u2 => cube.applyMove(.U2),
        .u_prime => cube.applyMove(.UPrime),
    }
}

fn isF2LSolved(cube: cube_mod.Cube) bool {
    inline for (.{ cube_mod.CornerPosition.dfr, .drb, .dbl, .dlf }) |position| {
        if (!cube.isCornerSolved(position)) return false;
    }
    inline for (.{
        cube_mod.EdgePosition.fr,
        .br,
        .bl,
        .fl,
        .df,
        .dr,
        .db,
        .dl,
    }) |position| {
        if (!cube.isEdgeSolved(position)) return false;
    }
    return true;
}

const LastLayerSignature = struct {
    corners: [4]cube_mod.CornerState,
    edges: [4]cube_mod.EdgeState,

    fn eql(self: LastLayerSignature, other: LastLayerSignature) bool {
        for (self.corners, other.corners) |left, right| {
            if (left.piece != right.piece or left.orientation != right.orientation) return false;
        }
        for (self.edges, other.edges) |left, right| {
            if (left.piece != right.piece or left.orientation != right.orientation) return false;
        }
        return true;
    }
};

fn lastLayerSignature(cube: cube_mod.Cube) LastLayerSignature {
    return .{
        .corners = .{
            cube.cornerAt(.ufr),
            cube.cornerAt(.urb),
            cube.cornerAt(.ubl),
            cube.cornerAt(.ulf),
        },
        .edges = .{
            cube.edgeAt(.uf),
            cube.edgeAt(.ur),
            cube.edgeAt(.ub),
            cube.edgeAt(.ul),
        },
    };
}
