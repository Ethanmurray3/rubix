const std = @import("std");
const rubix_desktop = @import("rubix_desktop");

const camera_mod = rubix_desktop.camera;
const render = rubix_desktop.render;

test "default orbit produces expected camera shape" {
    const orbit = camera_mod.Orbit{};
    const camera = orbit.camera();

    try std.testing.expectApproxEqAbs(@as(f32, 8.0), @sqrt(camera.position.x * camera.position.x + camera.position.y * camera.position.y + camera.position.z * camera.position.z), 0.0001);
    try std.testing.expectEqual(@as(f32, 0), camera.target.x);
    try std.testing.expectEqual(@as(f32, 0), camera.target.y);
    try std.testing.expectEqual(@as(f32, 0), camera.target.z);
    try std.testing.expectEqual(@as(f32, 45), camera.fovy);
}

test "orbit delta clamps pitch and distance" {
    var orbit = camera_mod.Orbit{};
    camera_mod.applyOrbitDelta(&orbit, .{ .x = 0, .y = 1000 }, -1000);
    try std.testing.expectEqual(@as(f32, 1.2), orbit.pitch);
    try std.testing.expectEqual(@as(f32, 14.0), orbit.distance);

    camera_mod.applyOrbitDelta(&orbit, .{ .x = 0, .y = -1000 }, 1000);
    try std.testing.expectEqual(@as(f32, -1.2), orbit.pitch);
    try std.testing.expectEqual(@as(f32, 4.8), orbit.distance);
}

test "view axes use three distinct axis lines" {
    const axes = camera_mod.viewAxes(.{
        .position = .{ .x = 4, .y = 3, .z = 6 },
        .target = .{ .x = 0, .y = 0, .z = 0 },
        .up = .{ .x = 0, .y = 1, .z = 0 },
        .fovy = 45,
        .projection = .perspective,
    });

    try std.testing.expect(!sameAxisLine(axes.up, axes.right));
    try std.testing.expect(!sameAxisLine(axes.up, axes.front));
    try std.testing.expect(!sameAxisLine(axes.right, axes.front));
}

fn sameAxisLine(a: render.Axis, b: render.Axis) bool {
    return switch (a) {
        .positive_x, .negative_x => b == .positive_x or b == .negative_x,
        .positive_y, .negative_y => b == .positive_y or b == .negative_y,
        .positive_z, .negative_z => b == .positive_z or b == .negative_z,
    };
}
