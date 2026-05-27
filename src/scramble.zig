const std = @import("std");
const move_mod = @import("move.zig");

pub const scramble_length = 20;

pub const Scramble = struct {
    moves: [scramble_length]move_mod.Move,
};

pub fn generate(random: std.Random) Scramble {
    var result: Scramble = undefined;
    var previous: ?move_mod.Move = null;

    for (&result.moves) |*move| {
        while (true) {
            const candidate = random.enumValue(move_mod.Move);
            if (previous == null or move_mod.moveAxis(candidate) != move_mod.moveAxis(previous.?)) {
                move.* = candidate;
                break;
            }
        }
        previous = move.*;
    }

    return result;
}
