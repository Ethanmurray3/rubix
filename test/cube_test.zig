const std = @import("std");
const rubix = @import("rubix");
const cube_mod = rubix.cube;
const Cube = cube_mod.Cube;
const Face = cube_mod.Face;
const FaceletCoord = cube_mod.FaceletCoord;
const Move = cube_mod.Move;

fn expectSolved(cube: Cube) !void {
    try std.testing.expect(cube.isSolved());
    try std.testing.expectEqual(Cube.solved().bits, cube.bits);
}

fn expectOneTurnUnsolved(comptime turn: fn (*Cube) void) !void {
    var cube = Cube.solved();
    turn(&cube);
    try std.testing.expect(!cube.isSolved());
}

fn expectFourTurnsSolved(comptime turn: fn (*Cube) void) !void {
    var cube = Cube.solved();

    turn(&cube);
    turn(&cube);
    turn(&cube);
    turn(&cube);

    try expectSolved(cube);
}

fn expectMoveThenInverseSolved(
    comptime turn: fn (*Cube) void,
    comptime inverse: fn (*Cube) void,
) !void {
    var cube = Cube.solved();

    turn(&cube);
    inverse(&cube);

    try expectSolved(cube);
}

fn expectDoubleMove(comptime move: Move, comptime turn: fn (*Cube) void) !void {
    var from_move = Cube.solved();
    var from_turns = Cube.solved();

    from_move.applyMove(move);
    turn(&from_turns);
    turn(&from_turns);

    try std.testing.expectEqual(from_turns.bits, from_move.bits);
}

fn expectFaceletMapping(face: Face, index: usize, expected: FaceletCoord) !void {
    const coord = cube_mod.faceletCoord(face, index);
    try std.testing.expectEqual(expected, coord);
    try std.testing.expectEqual(index, cube_mod.faceletIndex(face, expected));
}

test "solved cube reports solved" {
    try expectSolved(Cube.solved());
}

test "one face turn does not report solved" {
    try expectOneTurnUnsolved(Cube.turnU);
    try expectOneTurnUnsolved(Cube.turnD);
    try expectOneTurnUnsolved(Cube.turnR);
    try expectOneTurnUnsolved(Cube.turnL);
    try expectOneTurnUnsolved(Cube.turnF);
    try expectOneTurnUnsolved(Cube.turnB);
}

test "four quarter turns return to solved" {
    try expectFourTurnsSolved(Cube.turnU);
    try expectFourTurnsSolved(Cube.turnUPrime);
    try expectFourTurnsSolved(Cube.turnD);
    try expectFourTurnsSolved(Cube.turnDPrime);
    try expectFourTurnsSolved(Cube.turnR);
    try expectFourTurnsSolved(Cube.turnRPrime);
    try expectFourTurnsSolved(Cube.turnL);
    try expectFourTurnsSolved(Cube.turnLPrime);
    try expectFourTurnsSolved(Cube.turnF);
    try expectFourTurnsSolved(Cube.turnFPrime);
    try expectFourTurnsSolved(Cube.turnB);
    try expectFourTurnsSolved(Cube.turnBPrime);
}

test "turn followed by inverse returns to solved" {
    try expectMoveThenInverseSolved(Cube.turnU, Cube.turnUPrime);
    try expectMoveThenInverseSolved(Cube.turnUPrime, Cube.turnU);
    try expectMoveThenInverseSolved(Cube.turnD, Cube.turnDPrime);
    try expectMoveThenInverseSolved(Cube.turnDPrime, Cube.turnD);
    try expectMoveThenInverseSolved(Cube.turnR, Cube.turnRPrime);
    try expectMoveThenInverseSolved(Cube.turnRPrime, Cube.turnR);
    try expectMoveThenInverseSolved(Cube.turnL, Cube.turnLPrime);
    try expectMoveThenInverseSolved(Cube.turnLPrime, Cube.turnL);
    try expectMoveThenInverseSolved(Cube.turnF, Cube.turnFPrime);
    try expectMoveThenInverseSolved(Cube.turnFPrime, Cube.turnF);
    try expectMoveThenInverseSolved(Cube.turnB, Cube.turnBPrime);
    try expectMoveThenInverseSolved(Cube.turnBPrime, Cube.turnB);
}

test "double moves match two turns" {
    try expectDoubleMove(.U2, Cube.turnU);
    try expectDoubleMove(.D2, Cube.turnD);
    try expectDoubleMove(.R2, Cube.turnR);
    try expectDoubleMove(.L2, Cube.turnL);
    try expectDoubleMove(.F2, Cube.turnF);
    try expectDoubleMove(.B2, Cube.turnB);
}

test "move names use standard notation" {
    try std.testing.expectEqualStrings("R", cube_mod.moveName(.R));
    try std.testing.expectEqualStrings("R'", cube_mod.moveName(.RPrime));
    try std.testing.expectEqualStrings("R2", cube_mod.moveName(.R2));
}

test "facelet coordinates round trip for every facelet" {
    const faces = [_]Face{
        .up,
        .down,
        .front,
        .back,
        .left,
        .right,
    };

    for (faces) |face| {
        for (0..9) |index| {
            const coord = cube_mod.faceletCoord(face, index);
            try std.testing.expectEqual(index, cube_mod.faceletIndex(face, coord));
            try std.testing.expectEqual(coord, cube_mod.faceletCoord(face, cube_mod.faceletIndex(face, coord)));
        }
    }
}

test "facelet coordinates preserve mirrored down back and right layouts" {
    try expectFaceletMapping(.down, 0, .{ .x = -1, .y = -1, .z = 1 });
    try expectFaceletMapping(.down, 2, .{ .x = 1, .y = -1, .z = 1 });
    try expectFaceletMapping(.down, 6, .{ .x = -1, .y = -1, .z = -1 });
    try expectFaceletMapping(.down, 8, .{ .x = 1, .y = -1, .z = -1 });

    try expectFaceletMapping(.back, 0, .{ .x = 1, .y = 1, .z = -1 });
    try expectFaceletMapping(.back, 2, .{ .x = -1, .y = 1, .z = -1 });
    try expectFaceletMapping(.back, 6, .{ .x = 1, .y = -1, .z = -1 });
    try expectFaceletMapping(.back, 8, .{ .x = -1, .y = -1, .z = -1 });

    try expectFaceletMapping(.right, 0, .{ .x = 1, .y = 1, .z = 1 });
    try expectFaceletMapping(.right, 2, .{ .x = 1, .y = 1, .z = -1 });
    try expectFaceletMapping(.right, 6, .{ .x = 1, .y = -1, .z = 1 });
    try expectFaceletMapping(.right, 8, .{ .x = 1, .y = -1, .z = -1 });
}

test "facelet coordinates cover the visible cubies and stickers" {
    const faces = [_]Face{
        .up,
        .down,
        .front,
        .back,
        .left,
        .right,
    };
    var visible_cubies = [_]bool{false} ** 27;
    var sticker_count: usize = 0;

    for (faces) |face| {
        for (0..9) |index| {
            const coord = cube_mod.faceletCoord(face, index);
            const x: usize = @intCast(@as(isize, coord.x) + 1);
            const y: usize = @intCast(@as(isize, coord.y) + 1);
            const z: usize = @intCast(@as(isize, coord.z) + 1);
            visible_cubies[x * 9 + y * 3 + z] = true;
            sticker_count += 1;
        }
    }

    var cubie_count: usize = 0;
    for (visible_cubies) |visible| {
        if (visible) cubie_count += 1;
    }

    try std.testing.expectEqual(@as(usize, 26), cubie_count);
    try std.testing.expectEqual(@as(usize, 54), sticker_count);
    try std.testing.expect(!visible_cubies[13]);
}

test "scramble returns twenty moves and avoids adjacent axes" {
    var prng = std.Random.DefaultPrng.init(12345);
    const random = prng.random();

    const scramble = Cube.scramble(random);

    try std.testing.expectEqual(@as(usize, cube_mod.scramble_length), scramble.moves.len);

    for (scramble.moves[1..], 1..) |move, index| {
        try std.testing.expect(cube_mod.moveAxis(move) != cube_mod.moveAxis(scramble.moves[index - 1]));
    }
}

test "scramble can be applied explicitly to a cube" {
    var prng = std.Random.DefaultPrng.init(12345);
    const random = prng.random();

    const scramble = Cube.scramble(random);
    var cube = Cube.solved();
    for (scramble.moves) |move| {
        cube.applyMove(move);
    }

    try std.testing.expect(!cube.isSolved());
}
