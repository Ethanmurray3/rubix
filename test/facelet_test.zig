const std = @import("std");
const rubix = @import("rubix");

const facelet = rubix.facelet;
const Face = facelet.Face;
const FaceletCoord = facelet.FaceletCoord;

fn expectFaceletMapping(face: Face, index: usize, expected: FaceletCoord) !void {
    const coord = facelet.faceletCoord(face, index);
    try std.testing.expectEqual(expected, coord);
    try std.testing.expectEqual(index, facelet.faceletIndex(face, expected));
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
