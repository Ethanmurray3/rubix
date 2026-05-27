const std = @import("std");
const rubix = @import("rubix");
const move_mod = rubix.move;

test "move module names every move with standard notation" {
    try std.testing.expectEqualStrings("U", move_mod.moveName(.U));
    try std.testing.expectEqualStrings("U'", move_mod.moveName(.UPrime));
    try std.testing.expectEqualStrings("U2", move_mod.moveName(.U2));
    try std.testing.expectEqualStrings("D", move_mod.moveName(.D));
    try std.testing.expectEqualStrings("D'", move_mod.moveName(.DPrime));
    try std.testing.expectEqualStrings("D2", move_mod.moveName(.D2));
    try std.testing.expectEqualStrings("R", move_mod.moveName(.R));
    try std.testing.expectEqualStrings("R'", move_mod.moveName(.RPrime));
    try std.testing.expectEqualStrings("R2", move_mod.moveName(.R2));
    try std.testing.expectEqualStrings("L", move_mod.moveName(.L));
    try std.testing.expectEqualStrings("L'", move_mod.moveName(.LPrime));
    try std.testing.expectEqualStrings("L2", move_mod.moveName(.L2));
    try std.testing.expectEqualStrings("F", move_mod.moveName(.F));
    try std.testing.expectEqualStrings("F'", move_mod.moveName(.FPrime));
    try std.testing.expectEqualStrings("F2", move_mod.moveName(.F2));
    try std.testing.expectEqualStrings("B", move_mod.moveName(.B));
    try std.testing.expectEqualStrings("B'", move_mod.moveName(.BPrime));
    try std.testing.expectEqualStrings("B2", move_mod.moveName(.B2));
}

test "move module inverts every move symmetrically" {
    inline for (std.meta.fields(move_mod.Move)) |field| {
        const move: move_mod.Move = @enumFromInt(field.value);
        try std.testing.expectEqual(move, move_mod.inverseMove(move_mod.inverseMove(move)));
    }
}

test "move module groups moves by axis" {
    try std.testing.expectEqual(move_mod.MoveAxis.up_down, move_mod.moveAxis(.U));
    try std.testing.expectEqual(move_mod.MoveAxis.up_down, move_mod.moveAxis(.DPrime));
    try std.testing.expectEqual(move_mod.MoveAxis.right_left, move_mod.moveAxis(.R2));
    try std.testing.expectEqual(move_mod.MoveAxis.right_left, move_mod.moveAxis(.L));
    try std.testing.expectEqual(move_mod.MoveAxis.front_back, move_mod.moveAxis(.FPrime));
    try std.testing.expectEqual(move_mod.MoveAxis.front_back, move_mod.moveAxis(.B2));
}
