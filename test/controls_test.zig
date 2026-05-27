const std = @import("std");
const rubix = @import("rubix");

const camera_mod = rubix.camera;
const controls = rubix.controls;
const facelet = rubix.facelet;
const move_mod = rubix.move;
const render = rubix.render;

test "moveForFace covers all face and prime variants" {
    try std.testing.expectEqual(move_mod.Move.U, controls.moveForFace(.up, false));
    try std.testing.expectEqual(move_mod.Move.UPrime, controls.moveForFace(.up, true));
    try std.testing.expectEqual(move_mod.Move.D, controls.moveForFace(.down, false));
    try std.testing.expectEqual(move_mod.Move.DPrime, controls.moveForFace(.down, true));
    try std.testing.expectEqual(move_mod.Move.R, controls.moveForFace(.right, false));
    try std.testing.expectEqual(move_mod.Move.RPrime, controls.moveForFace(.right, true));
    try std.testing.expectEqual(move_mod.Move.L, controls.moveForFace(.left, false));
    try std.testing.expectEqual(move_mod.Move.LPrime, controls.moveForFace(.left, true));
    try std.testing.expectEqual(move_mod.Move.F, controls.moveForFace(.front, false));
    try std.testing.expectEqual(move_mod.Move.FPrime, controls.moveForFace(.front, true));
    try std.testing.expectEqual(move_mod.Move.B, controls.moveForFace(.back, false));
    try std.testing.expectEqual(move_mod.Move.BPrime, controls.moveForFace(.back, true));
}

test "identity orientation maps controls to visible faces" {
    const mapped = controls.fromViewAxes(.{
        .up = .positive_y,
        .right = .positive_x,
        .front = .positive_z,
    }, .{});

    try std.testing.expectEqual(facelet.Face.up, mapped.up);
    try std.testing.expectEqual(facelet.Face.down, mapped.down);
    try std.testing.expectEqual(facelet.Face.right, mapped.right);
    try std.testing.expectEqual(facelet.Face.left, mapped.left);
    try std.testing.expectEqual(facelet.Face.front, mapped.front);
    try std.testing.expectEqual(facelet.Face.back, mapped.back);
}

test "rotated orientation changes visible controls" {
    var orientation = render.Orientation{};
    orientation.rotateAroundWorldAxis(.positive_y, true);
    const mapped = controls.fromViewAxes(camera_mod.ViewAxes{
        .up = .positive_y,
        .right = .positive_x,
        .front = .positive_z,
    }, orientation);

    try std.testing.expectEqual(facelet.Face.up, mapped.up);
    try std.testing.expectEqual(facelet.Face.front, mapped.right);
    try std.testing.expectEqual(facelet.Face.left, mapped.front);
}
