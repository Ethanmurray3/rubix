const std = @import("std");
const cube_mod = @import("rubix").cube;
const Cube = cube_mod.Cube;
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

test "scramble returns twenty moves and avoids adjacent axes" {
    var prng = std.Random.DefaultPrng.init(12345);
    const random = prng.random();

    var cube = Cube.solved();
    const scramble = cube.scrambleWithRandom(random);

    try std.testing.expectEqual(@as(usize, cube_mod.scramble_length), scramble.moves.len);
    try std.testing.expect(!cube.isSolved());

    for (scramble.moves[1..], 1..) |move, index| {
        try std.testing.expect(cube_mod.moveAxis(move) != cube_mod.moveAxis(scramble.moves[index - 1]));
    }
}
