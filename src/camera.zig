const std = @import("std");
const rl = @import("raylib");
const render = @import("render.zig");

const Axis = render.Axis;

pub const Orbit = struct {
    yaw: f32 = -0.75,
    pitch: f32 = 0.55,
    distance: f32 = 8.0,

    pub fn camera(self: Orbit) rl.Camera3D {
        const cos_pitch = @cos(self.pitch);
        return .{
            .position = .{
                .x = self.distance * cos_pitch * @sin(self.yaw),
                .y = self.distance * @sin(self.pitch),
                .z = self.distance * cos_pitch * @cos(self.yaw),
            },
            .target = .{ .x = 0, .y = 0, .z = 0 },
            .up = .{ .x = 0, .y = 1, .z = 0 },
            .fovy = 45,
            .projection = .perspective,
        };
    }
};

pub const ViewAxes = struct {
    up: Axis,
    right: Axis,
    front: Axis,
};

const axes = [_]Axis{
    .positive_x,
    .negative_x,
    .positive_y,
    .negative_y,
    .positive_z,
    .negative_z,
};

pub fn updateOrbitFromRaylibInput(orbit: *Orbit) void {
    if (rl.isMouseButtonDown(.left)) {
        applyOrbitDelta(orbit, rl.getMouseDelta(), 0);
    }
    applyOrbitDelta(orbit, .{ .x = 0, .y = 0 }, rl.getMouseWheelMove());
}

pub fn applyOrbitDelta(orbit: *Orbit, mouse_delta: rl.Vector2, wheel: f32) void {
    orbit.yaw -= mouse_delta.x * 0.008;
    orbit.pitch += mouse_delta.y * 0.008;
    orbit.pitch = std.math.clamp(orbit.pitch, -1.2, 1.2);

    if (wheel != 0) {
        orbit.distance = std.math.clamp(orbit.distance - wheel * 0.6, 4.8, 14.0);
    }
}

pub fn viewAxes(camera_value: rl.Camera3D) ViewAxes {
    const camera_axis = nearestAxis(camera_value.position);
    const forward = normalize(vec3Scale(camera_value.position, -1));
    const right = normalize(cross(.{ .x = 0, .y = 1, .z = 0 }, camera_value.position));
    const up = cross(right, forward);

    const front_axis = camera_axis;
    const right_axis = nearestAxisExcept(right, front_axis, null);
    const up_axis = nearestAxisExcept(up, front_axis, right_axis);

    return .{
        .up = up_axis,
        .right = right_axis,
        .front = front_axis,
    };
}

fn nearestAxis(vector: rl.Vector3) Axis {
    var result: Axis = .positive_x;
    var best = -std.math.inf(f32);

    for (axes) |axis| {
        const score = dot(vector, render.axisVector(axis));
        if (score > best) {
            best = score;
            result = axis;
        }
    }

    return result;
}

fn nearestAxisExcept(vector: rl.Vector3, first_blocked: Axis, second_blocked: ?Axis) Axis {
    var result: Axis = .positive_x;
    var best = -std.math.inf(f32);

    for (axes) |axis| {
        if (sameAxisLine(axis, first_blocked)) continue;
        if (second_blocked) |blocked| {
            if (sameAxisLine(axis, blocked)) continue;
        }

        const score = dot(vector, render.axisVector(axis));
        if (score > best) {
            best = score;
            result = axis;
        }
    }

    return result;
}

fn sameAxisLine(a: Axis, b: Axis) bool {
    return switch (a) {
        .positive_x, .negative_x => b == .positive_x or b == .negative_x,
        .positive_y, .negative_y => b == .positive_y or b == .negative_y,
        .positive_z, .negative_z => b == .positive_z or b == .negative_z,
    };
}

fn normalize(vector: rl.Vector3) rl.Vector3 {
    const length = @sqrt(dot(vector, vector));
    if (length == 0) return .{ .x = 0, .y = 0, .z = 0 };
    return .{
        .x = vector.x / length,
        .y = vector.y / length,
        .z = vector.z / length,
    };
}

fn vec3Scale(vector: rl.Vector3, amount: f32) rl.Vector3 {
    return .{
        .x = vector.x * amount,
        .y = vector.y * amount,
        .z = vector.z * amount,
    };
}

fn cross(a: rl.Vector3, b: rl.Vector3) rl.Vector3 {
    return .{
        .x = a.y * b.z - a.z * b.y,
        .y = a.z * b.x - a.x * b.z,
        .z = a.x * b.y - a.y * b.x,
    };
}

fn dot(a: rl.Vector3, b: rl.Vector3) f32 {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}
