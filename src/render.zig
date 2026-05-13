const std = @import("std");
const cube_mod = @import("cube.zig");

const Color = cube_mod.Color;
const Cube = cube_mod.Cube;
const Face = cube_mod.Face;

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
//help function for formatting cube to terminal
fn printBlankRow() void {
    std.debug.print("      ", .{});
}

fn printFaceRow(cube: Cube, face: Face, row: usize) void {
    const index = 3 * row;
    for (0..3) |col| {
        const color = cube.facelet(face, index + col);
        std.debug.print("{s}{c}\x1b[0m ", .{
            colorAnsi(color),
            colorChar(color),
        });
    }
}

pub fn printCube(cube: Cube) void {
    //print top of cube
    for (0..3) |row| {
        printBlankRow();
        printFaceRow(cube, .up, row);
        std.debug.print("\n", .{});
    }
    //print all for sides of cube
    for (0..3) |row| {
        printFaceRow(cube, .left, row);
        printFaceRow(cube, .front, row);
        printFaceRow(cube, .right, row);
        printFaceRow(cube, .back, row);
        std.debug.print("\n", .{});
    }
    //print bottom of cube
    for (0..3) |row| {
        printBlankRow();
        printFaceRow(cube, .down, row);
        std.debug.print("\n", .{});
    }
}
