const std = @import("std");
const rubix = @import("rubix");
const cube_mod = rubix.cube;
const move_mod = rubix.move;
const scramble_mod = rubix.scramble;
const Cube = cube_mod.Cube;
const Move = move_mod.Move;

fn expectSolved(cube: Cube) !void {
    try std.testing.expect(cube.isSolved());
    try std.testing.expectEqual(Cube.solved().bits, cube.bits);
    try cube.validate();
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

fn setRawChunk(bits: cube_mod.CubeBits, position_index: u7, chunk: u5) cube_mod.CubeBits {
    const chunk_size = 5;
    const chunk_mask: cube_mod.CubeBits = 0b11111;
    const shift = position_index * chunk_size;
    const clear_mask = ~(chunk_mask << shift);
    return (bits & clear_mask) | (@as(cube_mod.CubeBits, chunk) << shift);
}

fn swapRawChunks(bits: cube_mod.CubeBits, a: u7, b: u7) cube_mod.CubeBits {
    const chunk_size = 5;
    const chunk_mask: cube_mod.CubeBits = 0b11111;
    const a_shift = a * chunk_size;
    const b_shift = b * chunk_size;
    const a_chunk: u5 = @truncate((bits >> a_shift) & chunk_mask);
    const b_chunk: u5 = @truncate((bits >> b_shift) & chunk_mask);
    return setRawChunk(setRawChunk(bits, a, b_chunk), b, a_chunk);
}

test "solved cube reports solved" {
    try expectSolved(Cube.solved());
}

test "inspection APIs expose solved cubie state" {
    const cube = Cube.solved();

    try std.testing.expectEqual(cube_mod.Corner.ufr, cube.cornerAt(.ufr).piece);
    try std.testing.expectEqual(@as(u2, 0), cube.cornerAt(.ufr).orientation);
    try std.testing.expect(cube.cornerAt(.ufr).isOriented());
    try std.testing.expect(cube.isCornerSolved(.ufr));

    try std.testing.expectEqual(cube_mod.Edge.uf, cube.edgeAt(.uf).piece);
    try std.testing.expectEqual(@as(u1, 0), cube.edgeAt(.uf).orientation);
    try std.testing.expect(cube.edgeAt(.uf).isOriented());
    try std.testing.expect(!cube.edgeAt(.uf).isFlipped());
    try std.testing.expect(cube.isEdgeSolved(.uf));

    try std.testing.expect(cube.isUpLayerOriented());
    try std.testing.expect(cube.isUpLayerPermutationSolved());
    try std.testing.expect(cube.isUpLayerSolved());
}

test "inspection APIs expose moved cubie state without reading bits" {
    var cube = Cube.solved();
    cube.applyMove(.R);

    const ufr = cube.cornerAt(.ufr);
    try std.testing.expectEqual(cube_mod.Corner.dfr, ufr.piece);
    try std.testing.expectEqual(@as(u2, 2), ufr.orientation);
    try std.testing.expect(!cube.isCornerSolved(.ufr));

    const ur = cube.edgeAt(.ur);
    try std.testing.expectEqual(cube_mod.Edge.fr, ur.piece);
    try std.testing.expect(ur.isOriented());
    try std.testing.expect(!cube.isEdgeSolved(.ur));

    try std.testing.expect(!cube.isUpLayerOriented());
    try std.testing.expect(!cube.isUpLayerPermutationSolved());
    try std.testing.expect(!cube.isUpLayerSolved());
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

test "moves can be applied with their inverse" {
    inline for (std.meta.fields(Move)) |field| {
        const move: Move = @enumFromInt(field.value);
        var cube = Cube.solved();

        cube.applyMove(move);
        cube.applyMove(move_mod.inverseMove(move));

        try expectSolved(cube);
    }
}

test "applyMoves applies an algorithm slice in order" {
    const algorithm = [_]Move{ .R, .U, .RPrime, .UPrime };
    var from_helper = Cube.solved();
    var from_loop = Cube.solved();

    from_helper.applyMoves(&algorithm);
    for (algorithm) |move| {
        from_loop.applyMove(move);
    }

    try std.testing.expectEqual(from_loop.bits, from_helper.bits);
    try std.testing.expect(!from_helper.isSolved());
}

test "scramble followed by inverse sequence returns solved" {
    var prng = std.Random.DefaultPrng.init(12345);
    const random = prng.random();
    const scramble = scramble_mod.generate(random);

    var inverse: [scramble_mod.scramble_length]Move = undefined;
    for (scramble.moves, 0..) |move, index| {
        inverse[scramble_mod.scramble_length - 1 - index] = move_mod.inverseMove(move);
    }

    var cube = Cube.solved();
    cube.applyMoves(&scramble.moves);
    try std.testing.expect(!cube.isSolved());

    cube.applyMoves(&inverse);
    try expectSolved(cube);
}

test "inspection APIs are useful on scrambled cubes" {
    var prng = std.Random.DefaultPrng.init(12345);
    const scramble = scramble_mod.generate(prng.random());

    var cube = Cube.solved();
    cube.applyMoves(&scramble.moves);
    try cube.validate();

    var solved_slot_count: usize = 0;
    inline for (std.meta.fields(cube_mod.CornerPosition)) |field| {
        const position: cube_mod.CornerPosition = @enumFromInt(field.value);
        const state = cube.cornerAt(position);
        _ = state.isOriented();
        if (cube.isCornerSolved(position)) solved_slot_count += 1;
    }
    inline for (std.meta.fields(cube_mod.EdgePosition)) |field| {
        const position: cube_mod.EdgePosition = @enumFromInt(field.value);
        const state = cube.edgeAt(position);
        _ = state.isFlipped();
        if (cube.isEdgeSolved(position)) solved_slot_count += 1;
    }

    try std.testing.expect(solved_slot_count < 20);
}

test "validation accepts solved cube moves and scrambles" {
    try Cube.solved().validate();

    inline for (std.meta.fields(Move)) |field| {
        const move: Move = @enumFromInt(field.value);
        var cube = Cube.solved();
        cube.applyMove(move);
        try cube.validate();
    }

    var prng = std.Random.DefaultPrng.init(12345);
    const random = prng.random();
    const scramble = scramble_mod.generate(random);
    var cube = Cube.solved();
    for (scramble.moves) |move| {
        cube.applyMove(move);
        try cube.validate();
    }
}

test "validation rejects malformed cube bits" {
    const solved = Cube.solved();

    var invalid_corner_orientation = solved;
    invalid_corner_orientation.bits = setRawChunk(invalid_corner_orientation.bits, 0, 0b11000);
    try std.testing.expectError(error.InvalidCornerOrientation, invalid_corner_orientation.validate());

    var duplicate_corner = solved;
    duplicate_corner.bits = setRawChunk(duplicate_corner.bits, 1, 0b00000);
    try std.testing.expectError(error.DuplicateCorner, duplicate_corner.validate());

    var invalid_edge_piece = solved;
    invalid_edge_piece.bits = setRawChunk(invalid_edge_piece.bits, 8, 0b01100);
    try std.testing.expectError(error.InvalidEdgePiece, invalid_edge_piece.validate());

    var duplicate_edge = solved;
    duplicate_edge.bits = setRawChunk(duplicate_edge.bits, 9, 0b00000);
    try std.testing.expectError(error.DuplicateEdge, duplicate_edge.validate());
}

test "checked inspection rejects malformed raw states" {
    const solved = Cube.solved();

    var invalid_corner_orientation = solved;
    invalid_corner_orientation.bits = setRawChunk(invalid_corner_orientation.bits, 0, 0b11000);
    try std.testing.expectError(error.InvalidCornerOrientation, invalid_corner_orientation.checkedCornerAt(.ufr));

    var invalid_edge_piece = solved;
    invalid_edge_piece.bits = setRawChunk(invalid_edge_piece.bits, 8, 0b01100);
    try std.testing.expectError(error.InvalidEdgePiece, invalid_edge_piece.checkedEdgeAt(.uf));
}

test "validation rejects mismatched corner and edge permutation parity" {
    const solved = Cube.solved();

    var swapped_corners = solved;
    swapped_corners.bits = swapRawChunks(swapped_corners.bits, 0, 1);
    try std.testing.expectError(error.MismatchedPermutationParity, swapped_corners.validate());

    var swapped_edges = solved;
    swapped_edges.bits = swapRawChunks(swapped_edges.bits, 8, 9);
    try std.testing.expectError(error.MismatchedPermutationParity, swapped_edges.validate());

    var matching_parity = solved;
    matching_parity.bits = swapRawChunks(matching_parity.bits, 0, 1);
    matching_parity.bits = swapRawChunks(matching_parity.bits, 8, 9);
    try matching_parity.validate();
}

test "scramble can be applied explicitly to a cube" {
    var prng = std.Random.DefaultPrng.init(12345);
    const random = prng.random();

    const scramble = scramble_mod.generate(random);
    var cube = Cube.solved();
    for (scramble.moves) |move| {
        cube.applyMove(move);
    }

    try std.testing.expect(!cube.isSolved());
}
