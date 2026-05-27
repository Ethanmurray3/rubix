const std = @import("std");
const rubix = @import("rubix");

const facelet = rubix.facelet;
const move_mod = rubix.move;
const scramble_mod = rubix.scramble;
const ui = rubix.ui;

test "moveNameZ matches move names" {
    inline for (std.meta.fields(move_mod.Move)) |field| {
        const move: move_mod.Move = @enumFromInt(field.value);
        try std.testing.expectEqualStrings(move_mod.moveName(move), ui.moveNameZ(move));
    }
}

test "faceName covers all faces" {
    try std.testing.expectEqualStrings("U", ui.faceName(.up));
    try std.testing.expectEqualStrings("D", ui.faceName(.down));
    try std.testing.expectEqualStrings("R", ui.faceName(.right));
    try std.testing.expectEqualStrings("L", ui.faceName(.left));
    try std.testing.expectEqualStrings("F", ui.faceName(.front));
    try std.testing.expectEqualStrings("B", ui.faceName(.back));
    _ = facelet.Face.up;
}

test "scrambleNotationZ formats moves with spaces and sentinel" {
    var buffer: [128]u8 = undefined;
    var moves = [_]move_mod.Move{.L} ** scramble_mod.scramble_length;
    moves[0] = .R;
    moves[1] = .U;
    moves[2] = .FPrime;
    moves[3] = .D2;
    const scramble = scramble_mod.Scramble{ .moves = moves };
    const text = ui.scrambleNotationZ(&buffer, scramble);

    try std.testing.expect(std.mem.startsWith(u8, text, "R U F' D2 L"));
    try std.testing.expectEqual(@as(u8, 0), buffer[text.len]);
}
