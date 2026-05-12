const std = @import("std");
const Cube = @import("rubix").cube.Cube;

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
