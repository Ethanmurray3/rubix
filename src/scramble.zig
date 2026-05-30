const std = @import("std");
const facelet = @import("facelet.zig");
const move_mod = @import("move.zig");

pub const scramble_length = 20;

pub const Scramble = struct {
    moves: [scramble_length]move_mod.Move,
};

pub fn generate(random: std.Random) Scramble {
    var result: Scramble = undefined;
    var previous: ?move_mod.Move = null;
    var second_previous: ?move_mod.Move = null;

    for (&result.moves) |*move| {
        while (true) {
            const candidate = random.enumValue(move_mod.Move);
            const candidate_axis = move_mod.moveAxis(candidate);
            const candidate_face = facelet.moveFace(candidate);

            if (previous) |prev| {
                if (candidate_face == facelet.moveFace(prev)) continue;

                if (second_previous) |prev2| {
                    if (candidate_axis == move_mod.moveAxis(prev) and candidate_axis == move_mod.moveAxis(prev2)) continue;
                }
            }

            move.* = candidate;
            break;
        }
        second_previous = previous;
        previous = move.*;
    }

    return result;
}
