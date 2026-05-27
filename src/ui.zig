const std = @import("std");
const facelet = @import("facelet.zig");
const move_mod = @import("move.zig");
const scramble_mod = @import("scramble.zig");

pub const LastAction = struct {
    status: [:0]const u8 = "Solved",
    scramble: [:0]const u8 = "",
};

pub fn moveNameZ(move: move_mod.Move) [:0]const u8 {
    return switch (move) {
        .U => "U",
        .UPrime => "U'",
        .U2 => "U2",
        .D => "D",
        .DPrime => "D'",
        .D2 => "D2",
        .R => "R",
        .RPrime => "R'",
        .R2 => "R2",
        .L => "L",
        .LPrime => "L'",
        .L2 => "L2",
        .F => "F",
        .FPrime => "F'",
        .F2 => "F2",
        .B => "B",
        .BPrime => "B'",
        .B2 => "B2",
    };
}

pub fn faceName(face: facelet.Face) []const u8 {
    return switch (face) {
        .up => "U",
        .down => "D",
        .right => "R",
        .left => "L",
        .front => "F",
        .back => "B",
    };
}

pub fn scrambleNotationZ(buffer: *[128]u8, scramble: scramble_mod.Scramble) [:0]const u8 {
    var position: usize = 0;

    for (scramble.moves, 0..) |move, index| {
        if (index != 0) {
            buffer[position] = ' ';
            position += 1;
        }

        const name = move_mod.moveName(move);
        std.mem.copyForwards(u8, buffer[position .. position + name.len], name);
        position += name.len;
    }

    buffer[position] = 0;
    return buffer[0..position :0];
}
