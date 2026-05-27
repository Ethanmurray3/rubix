const std = @import("std");
const cube_mod = @import("cube.zig");
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

const chunk_size = 5;
const chunk_mask: cube_mod.CubeBits = 0b11111;

pub fn color(cube: cube_mod.Cube, face: Face, index: usize) Color {
    std.debug.assert(index < 9);

    return switch (face) {
        .up => switch (index) {
            0 => cornerColor(cube, .ubl, face),
            1 => edgeColor(cube, .ub, face),
            2 => cornerColor(cube, .urb, face),
            3 => edgeColor(cube, .ul, face),
            4 => .white,
            5 => edgeColor(cube, .ur, face),
            6 => cornerColor(cube, .ulf, face),
            7 => edgeColor(cube, .uf, face),
            8 => cornerColor(cube, .ufr, face),
            else => unreachable,
        },
        .down => switch (index) {
            0 => cornerColor(cube, .dlf, face),
            1 => edgeColor(cube, .df, face),
            2 => cornerColor(cube, .dfr, face),
            3 => edgeColor(cube, .dl, face),
            4 => .yellow,
            5 => edgeColor(cube, .dr, face),
            6 => cornerColor(cube, .dbl, face),
            7 => edgeColor(cube, .db, face),
            8 => cornerColor(cube, .drb, face),
            else => unreachable,
        },
        .front => switch (index) {
            0 => cornerColor(cube, .ulf, face),
            1 => edgeColor(cube, .uf, face),
            2 => cornerColor(cube, .ufr, face),
            3 => edgeColor(cube, .fl, face),
            4 => .green,
            5 => edgeColor(cube, .fr, face),
            6 => cornerColor(cube, .dlf, face),
            7 => edgeColor(cube, .df, face),
            8 => cornerColor(cube, .dfr, face),
            else => unreachable,
        },
        .back => switch (index) {
            0 => cornerColor(cube, .urb, face),
            1 => edgeColor(cube, .ub, face),
            2 => cornerColor(cube, .ubl, face),
            3 => edgeColor(cube, .br, face),
            4 => .blue,
            5 => edgeColor(cube, .bl, face),
            6 => cornerColor(cube, .drb, face),
            7 => edgeColor(cube, .db, face),
            8 => cornerColor(cube, .dbl, face),
            else => unreachable,
        },
        .left => switch (index) {
            0 => cornerColor(cube, .ubl, face),
            1 => edgeColor(cube, .ul, face),
            2 => cornerColor(cube, .ulf, face),
            3 => edgeColor(cube, .bl, face),
            4 => .orange,
            5 => edgeColor(cube, .fl, face),
            6 => cornerColor(cube, .dbl, face),
            7 => edgeColor(cube, .dl, face),
            8 => cornerColor(cube, .dlf, face),
            else => unreachable,
        },
        .right => switch (index) {
            0 => cornerColor(cube, .ufr, face),
            1 => edgeColor(cube, .ur, face),
            2 => cornerColor(cube, .urb, face),
            3 => edgeColor(cube, .fr, face),
            4 => .red,
            5 => edgeColor(cube, .br, face),
            6 => cornerColor(cube, .dfr, face),
            7 => edgeColor(cube, .dr, face),
            8 => cornerColor(cube, .drb, face),
            else => unreachable,
        },
    };
}

pub fn moveFace(move: move_mod.Move) Face {
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

fn getChunk(bits: cube_mod.CubeBits, position: Position) u5 {
    const shift: u7 = @as(u7, @intFromEnum(position)) * chunk_size;
    return @truncate((bits >> shift) & chunk_mask);
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

fn cornerFromChunk(chunk: u5) cube_mod.Corner {
    return @enumFromInt(@as(u3, @truncate(chunk & 0b00111)));
}

fn cornerOrientation(chunk: u5) u2 {
    return @truncate(chunk >> 3);
}

fn edgeFromChunk(chunk: u5) cube_mod.Edge {
    return @enumFromInt(@as(u4, @truncate(chunk & 0b01111)));
}

fn edgeOrientation(chunk: u5) u1 {
    return @truncate(chunk >> 4);
}

fn cornerColor(cube: cube_mod.Cube, position: Position, face: Face) Color {
    const chunk = getChunk(cube.bits, position);
    const faces = cornerPositionFaces(position);
    const colors = cornerColors(cornerFromChunk(chunk));
    const position_index = indexOfCornerFace(faces, face);
    const color_index = (@as(u3, position_index) + @as(u3, cornerOrientation(chunk))) % 3;
    return colors[@intCast(color_index)];
}

fn edgeColor(cube: cube_mod.Cube, position: Position, face: Face) Color {
    const chunk = getChunk(cube.bits, position);
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

fn cornerColors(corner: cube_mod.Corner) [3]Color {
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

fn edgeColors(edge: cube_mod.Edge) [2]Color {
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
