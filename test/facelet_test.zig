const std = @import("std");
const rubix = @import("rubix");

const cube_mod = rubix.cube;
const facelet = rubix.facelet;
const move_mod = rubix.move;
const Face = facelet.Face;
const FaceletCoord = facelet.FaceletCoord;

const face_order = [_]Face{ .up, .right, .front, .down, .left, .back };

fn expectFaceletMapping(face: Face, index: usize, expected: FaceletCoord) !void {
    const coord = facelet.faceletCoord(face, index);
    try std.testing.expectEqual(expected, coord);
    try std.testing.expectEqual(index, facelet.faceletIndex(face, expected));
}

fn colorChar(color: facelet.Color) u8 {
    return switch (color) {
        .white => 'W',
        .yellow => 'Y',
        .green => 'G',
        .blue => 'B',
        .orange => 'O',
        .red => 'R',
    };
}

fn expectFaceletString(cube: cube_mod.Cube, expected: []const u8) !void {
    var actual: [54]u8 = undefined;
    var position: usize = 0;

    for (face_order) |face| {
        for (0..9) |index| {
            actual[position] = colorChar(facelet.color(cube, face, index));
            position += 1;
        }
    }

    try std.testing.expectEqualStrings(expected, &actual);
}

test "facelet coordinates round trip for every facelet" {
    for (face_order) |face| {
        for (0..9) |index| {
            const coord = facelet.faceletCoord(face, index);
            try std.testing.expectEqual(index, facelet.faceletIndex(face, coord));
            try std.testing.expectEqual(coord, facelet.faceletCoord(face, facelet.faceletIndex(face, coord)));
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

test "checked facelet indices reject invalid coordinates and off-face coordinates" {
    try std.testing.expectError(
        facelet.FaceletIndexError.InvalidAxisCoord,
        facelet.faceletIndexChecked(.up, .{ .x = -2, .y = 1, .z = 0 }),
    );
    try std.testing.expectError(
        facelet.FaceletIndexError.NotOnFace,
        facelet.faceletIndexChecked(.up, .{ .x = 0, .y = 0, .z = 0 }),
    );
    try std.testing.expectEqual(@as(usize, 4), try facelet.faceletIndexChecked(.front, .{ .x = 0, .y = 0, .z = 1 }));
}

test "facelet coordinates cover the visible cubies and stickers" {
    var visible_cubies = [_]bool{false} ** 27;
    var sticker_count: usize = 0;

    for (face_order) |face| {
        for (0..9) |index| {
            const coord = facelet.faceletCoord(face, index);
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

test "facelet projection pins known move cases" {
    const fixtures = .{
        .{ move_mod.Move.U, "WWWWWWWWWBBBRRRRRRRRRGGGGGGYYYYYYYYYGGGOOOOOOOOOBBBBBB" },
        .{ move_mod.Move.UPrime, "WWWWWWWWWGGGRRRRRROOOGGGGGGYYYYYYYYYBBBOOOOOORRRBBBBBB" },
        .{ move_mod.Move.U2, "WWWWWWWWWOOORRRRRRBBBGGGGGGYYYYYYYYYRRROOOOOOGGGBBBBBB" },
        .{ move_mod.Move.D, "WWWWWWWWWRRRRRRGGGGGGGGGOOOYYYYYYYYYOOOOOOBBBBBBBBBRRR" },
        .{ move_mod.Move.DPrime, "WWWWWWWWWRRRRRRBBBGGGGGGRRRYYYYYYYYYOOOOOOGGGBBBBBBOOO" },
        .{ move_mod.Move.D2, "WWWWWWWWWRRRRRROOOGGGGGGBBBYYYYYYYYYOOOOOORRRBBBBBBGGG" },
        .{ move_mod.Move.R, "WWGWWGWWGRRRRRRRRRGGYGGYGGYYYBYYBYYBOOOOOOOOOWBBWBBWBB" },
        .{ move_mod.Move.RPrime, "WWBWWBWWBRRRRRRRRRGGWGGWGGWYYGYYGYYGOOOOOOOOOYBBYBBYBB" },
        .{ move_mod.Move.R2, "WWYWWYWWYRRRRRRRRRGGBGGBGGBYYWYYWYYWOOOOOOOOOGBBGBBGBB" },
        .{ move_mod.Move.L, "BWWBWWBWWRRRRRRRRRWGGWGGWGGGYYGYYGYYOOOOOOOOOBBYBBYBBY" },
        .{ move_mod.Move.LPrime, "GWWGWWGWWRRRRRRRRRYGGYGGYGGBYYBYYBYYOOOOOOOOOBBWBBWBBW" },
        .{ move_mod.Move.L2, "YWWYWWYWWRRRRRRRRRBGGBGGBGGWYYWYYWYYOOOOOOOOOBBGBBGBBG" },
        .{ move_mod.Move.F, "WWWWWWOOOWRRWRRWRRGGGGGGGGGRRRYYYYYYOOYOOYOOYBBBBBBBBB" },
        .{ move_mod.Move.FPrime, "WWWWWWRRRYRRYRRYRRGGGGGGGGGOOOYYYYYYOOWOOWOOWBBBBBBBBB" },
        .{ move_mod.Move.F2, "WWWWWWYYYORRORRORRGGGGGGGGGWWWYYYYYYOOROOROORBBBBBBBBB" },
        .{ move_mod.Move.B, "RRRWWWWWWRRYRRYRRYGGGGGGGGGYYYYYYOOOWOOWOOWOOBBBBBBBBB" },
        .{ move_mod.Move.BPrime, "OOOWWWWWWRRWRRWRRWGGGGGGGGGYYYYYYRRRYOOYOOYOOBBBBBBBBB" },
        .{ move_mod.Move.B2, "YYYWWWWWWRRORRORROGGGGGGGGGYYYYYYWWWROOROOROOBBBBBBBBB" },
    };

    try expectFaceletString(cube_mod.Cube.solved(), "WWWWWWWWWRRRRRRRRRGGGGGGGGGYYYYYYYYYOOOOOOOOOBBBBBBBBB");

    inline for (fixtures) |fixture| {
        var cube = cube_mod.Cube.solved();
        cube.applyMove(fixture[0]);
        try expectFaceletString(cube, fixture[1]);
    }
}

test "facelet projection pins known algorithm cases" {
    const sexy = [_]move_mod.Move{ .R, .U, .RPrime, .UPrime };
    var cube = cube_mod.Cube.solved();
    cube.applyMoves(&sexy);

    try expectFaceletString(cube, "WWOWWGWWGRRWBRRWRRGGYGGWGGGYYRYYYYYYBOOOOOOOOBRRBBBBBB");

    const sledge = [_]move_mod.Move{ .RPrime, .F, .R, .FPrime };
    cube = cube_mod.Cube.solved();
    cube.applyMoves(&sledge);

    try expectFaceletString(cube, "WWGWWGBRRYWWRRRRRRRGGGGWGGWYYGYYYYYYOOWOOOOOOOBBBBBBBB");
}
