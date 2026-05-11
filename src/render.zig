const std = @import("std");
const cube_mod = @import("cube.zig");

const Color = cube_mod.Color;
const Cube = cube_mod.Cube;

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

pub fn printBlankRow() void {
    std.debug.print("      ", .{});
}

pub fn printFaceRow(face: [9]Color, row: usize) void {
    const index = 3 * row;
    for (0..3) |col| {
        const color = face[index + col];
        std.debug.print("{s}{c}\x1b[0m ", .{
            colorAnsi(color),
            colorChar(color),
        });
    }
}

pub fn printFace(face: [9]Color) void {
    for (0..3) |row| {
        for (0..3) |col| {
            const index = row * 3 + col;
            const color = face[index];

            std.debug.print("{s}{c}\x1b[0m ", .{
                colorAnsi(color),
                colorChar(color),
            });
        }
        std.debug.print("\n", .{});
    }
}

pub fn printCubeSplit(cube: Cube) void {
    std.debug.print("Up:\n", .{});
    printFace(cube.stickers[0]);

    std.debug.print("\nDown:\n", .{});
    printFace(cube.stickers[1]);

    std.debug.print("\nFront:\n", .{});
    printFace(cube.stickers[2]);

    std.debug.print("\nBack:\n", .{});
    printFace(cube.stickers[3]);

    std.debug.print("\nLeft:\n", .{});
    printFace(cube.stickers[4]);

    std.debug.print("\nRight:\n", .{});
    printFace(cube.stickers[5]);
}

pub fn printCubeCompact(cube: Cube) void {
    std.debug.print("{any}\n", .{cube.stickers});
    for (0..3) |row| {
        printBlankRow();
        printFaceRow(cube.stickers[0], row);
        std.debug.print("\n", .{});
    }

    for (0..3) |row| {
        printFaceRow(cube.stickers[4], row); // Left
        printFaceRow(cube.stickers[2], row); // Front
        printFaceRow(cube.stickers[5], row); // Right
        printFaceRow(cube.stickers[3], row); // Back
        std.debug.print("\n", .{});
    }

    for (0..3) |row| {
        printBlankRow();
        printFaceRow(cube.stickers[1], row);
        std.debug.print("\n", .{});
    }
    // print like this
    //     W W W
    //     W W W
    //     W W W
    //
    // O O O G G G R R R B B B
    // O O O G G G R R R B B B
    // O O O G G G R R R B B B
    //
    //     Y Y Y
    //     Y Y Y
    //     Y Y Y
}
