const std = @import("std");
const rubix = @import("rubix");

const facelet = rubix.facelet;
const move_mod = rubix.move;
const scramble_mod = rubix.scramble;

test "generate returns twenty moves and avoids adjacent same-face moves" {
    var prng = std.Random.DefaultPrng.init(12345);
    const scramble = scramble_mod.generate(prng.random());

    try std.testing.expectEqual(@as(usize, scramble_mod.scramble_length), scramble.moves.len);

    for (scramble.moves[1..], 1..) |move, index| {
        try std.testing.expect(facelet.moveFace(move) != facelet.moveFace(scramble.moves[index - 1]));
    }
}

test "generate avoids triple same-axis moves" {
    var prng = std.Random.DefaultPrng.init(12345);
    const random = prng.random();

    var i: usize = 0;
    while (i < 100) : (i += 1) {
        const scramble = scramble_mod.generate(random);
        for (scramble.moves[2..], 2..) |move, index| {
            const m1 = scramble.moves[index - 1];
            const m2 = scramble.moves[index - 2];
            const axis = move_mod.moveAxis(move);
            if (axis == move_mod.moveAxis(m1) and axis == move_mod.moveAxis(m2)) {
                return error.TestExpectedTripleSameAxisRejection;
            }
        }
    }
}
