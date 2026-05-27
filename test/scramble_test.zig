const std = @import("std");
const rubix = @import("rubix");

const move_mod = rubix.move;
const scramble_mod = rubix.scramble;

test "generate returns twenty moves and avoids adjacent axes" {
    var prng = std.Random.DefaultPrng.init(12345);
    const scramble = scramble_mod.generate(prng.random());

    try std.testing.expectEqual(@as(usize, scramble_mod.scramble_length), scramble.moves.len);

    for (scramble.moves[1..], 1..) |move, index| {
        try std.testing.expect(move_mod.moveAxis(move) != move_mod.moveAxis(scramble.moves[index - 1]));
    }
}
