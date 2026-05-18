const std = @import("std");
const cube_mod = @import("cube.zig");

const Color = cube_mod.Color;
const Cube = cube_mod.Cube;
const Face = cube_mod.Face;

pub const cube_width = 24;
pub const cube_height = 9;

fn colorChar(color: Color) u8 {
    return switch (color) {
        .white => 'W',
        .yellow => 'Y',
        .green => 'G',
        .blue => 'B',
        .orange => 'O',
        .red => 'R',
    };
}

fn colorAnsi(color: Color) []const u8 {
    return switch (color) {
        .white => "\x1b[97m",
        .yellow => "\x1b[93m",
        .green => "\x1b[92m",
        .blue => "\x1b[94m",
        .orange => "\x1b[38;5;208m",
        .red => "\x1b[91m",
    };
}

fn writeBlankFace(writer: *std.Io.Writer) !void {
    try writer.writeAll("      ");
}

fn writeFaceRow(writer: *std.Io.Writer, cube: Cube, face: Face, row: usize) !void {
    const index = 3 * row;
    for (0..3) |col| {
        const color = cube.facelet(face, index + col);
        try writer.print("{s}{c}\x1b[0m ", .{
            colorAnsi(color),
            colorChar(color),
        });
    }
}

pub fn writeCubeLine(writer: *std.Io.Writer, cube: Cube, line: usize) !void {
    std.debug.assert(line < cube_height);

    if (line < 3) {
        try writeBlankFace(writer);
        try writeFaceRow(writer, cube, .up, line);
    } else if (line < 6) {
        const row = line - 3;
        try writeFaceRow(writer, cube, .left, row);
        try writeFaceRow(writer, cube, .front, row);
        try writeFaceRow(writer, cube, .right, row);
        try writeFaceRow(writer, cube, .back, row);
    } else {
        try writeBlankFace(writer);
        try writeFaceRow(writer, cube, .down, line - 6);
    }
}

pub fn writeCube(writer: *std.Io.Writer, cube: Cube) !void {
    for (0..cube_height) |line| {
        try writeCubeLine(writer, cube, line);
        try writer.writeAll("\n");
    }
}

pub fn printCube(cube: Cube) void {
    for (0..cube_height) |line| {
        var buffer: [256]u8 = undefined;
        var writer = std.Io.Writer.fixed(&buffer);
        writeCubeLine(&writer, cube, line) catch unreachable;
        std.debug.print("{s}\n", .{writer.buffered()});
    }
}
