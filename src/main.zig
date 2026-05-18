const std = @import("std");
const rl = @import("raylib");
const cube_mod = @import("cube.zig");
const render3d = @import("render3d.zig");

const Cube = cube_mod.Cube;
const Face = cube_mod.Face;
const Move = cube_mod.Move;

const CameraOrbit = struct {
    yaw: f32 = -0.75,
    pitch: f32 = 0.55,
    distance: f32 = 8.0,

    fn camera(self: CameraOrbit) rl.Camera3D {
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

const LastAction = struct {
    status: [:0]const u8 = "Solved",
    face: ?Face = null,
    highlight_time: f32 = 0,
};

const Axis = enum {
    positive_x,
    negative_x,
    positive_y,
    negative_y,
    positive_z,
    negative_z,
};

const ViewControls = struct {
    up: Face,
    down: Face,
    right: Face,
    left: Face,
    front: Face,
    back: Face,
};

const axes = [_]Axis{
    .positive_x,
    .negative_x,
    .positive_y,
    .negative_y,
    .positive_z,
    .negative_z,
};

pub fn main(init: std.process.Init) !void {
    var cube = Cube.solved();

    var seed: u64 = undefined;
    init.io.random(std.mem.asBytes(&seed));
    var prng = std.Random.DefaultPrng.init(seed);

    rl.setConfigFlags(.{
        .window_resizable = true,
        .msaa_4x_hint = true,
        .vsync_hint = true,
    });
    rl.initWindow(1280, 800, "Rubix");
    defer rl.closeWindow();
    rl.setTargetFPS(60);

    var orbit: CameraOrbit = .{};
    var last: LastAction = .{};

    while (!rl.windowShouldClose()) {
        updateCameraOrbit(&orbit);
        const controls = viewControls(orbit.camera());

        if (readMoveInput(controls)) |move| {
            cube.applyMove(move);
            last = .{
                .status = moveNameZ(move),
                .face = moveFace(move),
                .highlight_time = 0.18,
            };
        }

        if (rl.isKeyPressed(.tab)) {
            _ = cube.scrambleWithRandom(prng.random());
            last = .{
                .status = "Scrambled",
                .face = null,
                .highlight_time = 0.18,
            };
        }

        if (rl.isKeyPressed(.space)) {
            cube = Cube.solved();
            last = .{
                .status = "Solved",
                .face = null,
                .highlight_time = 0,
            };
        }

        if (cube.isSolved()) {
            last.status = "Solved";
        }

        last.highlight_time = @max(0, last.highlight_time - rl.getFrameTime());
        draw(cube, orbit.camera(), last, controls);
    }
}

fn updateCameraOrbit(orbit: *CameraOrbit) void {
    if (rl.isMouseButtonDown(.left)) {
        const delta = rl.getMouseDelta();
        orbit.yaw -= delta.x * 0.008;
        orbit.pitch += delta.y * 0.008;
        orbit.pitch = std.math.clamp(orbit.pitch, -1.2, 1.2);
    }

    const wheel = rl.getMouseWheelMove();
    if (wheel != 0) {
        orbit.distance = std.math.clamp(orbit.distance - wheel * 0.6, 4.8, 14.0);
    }
}

fn readMoveInput(controls: ViewControls) ?Move {
    inline for (.{ .w, .s, .d, .a, .q, .e }) |key| {
        if (turnKeyPressed(key)) {
            return moveForKey(key, controls, shiftDown());
        }
    }
    return null;
}

fn turnKeyPressed(key: rl.KeyboardKey) bool {
    return rl.isKeyPressed(key) or rl.isKeyPressedRepeat(key);
}

fn shiftDown() bool {
    return rl.isKeyDown(.left_shift) or rl.isKeyDown(.right_shift);
}

fn moveForKey(key: rl.KeyboardKey, controls: ViewControls, prime: bool) Move {
    const face = switch (key) {
        .w => controls.up,
        .s => controls.down,
        .d => controls.right,
        .a => controls.left,
        .q => controls.front,
        .e => controls.back,
        else => unreachable,
    };
    return moveForFace(face, prime);
}

fn moveForFace(face: Face, prime: bool) Move {
    return switch (face) {
        .up => if (prime) .UPrime else .U,
        .down => if (prime) .DPrime else .D,
        .right => if (prime) .RPrime else .R,
        .left => if (prime) .LPrime else .L,
        .front => if (prime) .FPrime else .F,
        .back => if (prime) .BPrime else .B,
    };
}

fn viewControls(camera: rl.Camera3D) ViewControls {
    const camera_axis = nearestAxis(camera.position);
    const forward = normalize(vec3Scale(camera.position, -1));
    const right = normalize(cross(.{ .x = 0, .y = 1, .z = 0 }, camera.position));
    const up = cross(right, forward);

    const front_axis = camera_axis;
    const right_axis = nearestAxisExcept(right, front_axis, null);
    const up_axis = nearestAxisExcept(up, front_axis, right_axis);

    return .{
        .up = faceForAxis(up_axis),
        .down = faceForAxis(oppositeAxis(up_axis)),
        .right = faceForAxis(right_axis),
        .left = faceForAxis(oppositeAxis(right_axis)),
        .front = faceForAxis(front_axis),
        .back = faceForAxis(oppositeAxis(front_axis)),
    };
}

fn nearestAxis(vector: rl.Vector3) Axis {
    var result: Axis = .positive_x;
    var best = -std.math.inf(f32);

    for (axes) |axis| {
        const score = dot(vector, axisVector(axis));
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

        const score = dot(vector, axisVector(axis));
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

fn oppositeAxis(axis: Axis) Axis {
    return switch (axis) {
        .positive_x => .negative_x,
        .negative_x => .positive_x,
        .positive_y => .negative_y,
        .negative_y => .positive_y,
        .positive_z => .negative_z,
        .negative_z => .positive_z,
    };
}

fn faceForAxis(axis: Axis) Face {
    return switch (axis) {
        .positive_x => .right,
        .negative_x => .left,
        .positive_y => .up,
        .negative_y => .down,
        .positive_z => .front,
        .negative_z => .back,
    };
}

fn axisVector(axis: Axis) rl.Vector3 {
    return switch (axis) {
        .positive_x => .{ .x = 1, .y = 0, .z = 0 },
        .negative_x => .{ .x = -1, .y = 0, .z = 0 },
        .positive_y => .{ .x = 0, .y = 1, .z = 0 },
        .negative_y => .{ .x = 0, .y = -1, .z = 0 },
        .positive_z => .{ .x = 0, .y = 0, .z = 1 },
        .negative_z => .{ .x = 0, .y = 0, .z = -1 },
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

fn moveFace(move: Move) Face {
    return switch (move) {
        .U, .UPrime, .U2 => .up,
        .D, .DPrime, .D2 => .down,
        .R, .RPrime, .R2 => .right,
        .L, .LPrime, .L2 => .left,
        .F, .FPrime, .F2 => .front,
        .B, .BPrime, .B2 => .back,
    };
}

fn moveNameZ(move: Move) [:0]const u8 {
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

fn draw(cube: Cube, camera: rl.Camera3D, last: LastAction, controls: ViewControls) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(rl.Color.init(18, 20, 24, 255));

    camera.begin();
    render3d.drawCube(cube, last.face, highlightAlpha(last.highlight_time));
    rl.drawGrid(10, 1.0);
    camera.end();

    drawOverlay(last.status, controls);
}

fn highlightAlpha(time_left: f32) u8 {
    const ratio = std.math.clamp(time_left / 0.18, 0, 1);
    return @intFromFloat(ratio * 90.0);
}

fn drawOverlay(status: [:0]const u8, controls: ViewControls) void {
    var controls_buffer: [160]u8 = undefined;
    const controls_text = std.fmt.bufPrintZ(
        &controls_buffer,
        "W:{s} S:{s} D:{s} A:{s} Q:{s} E:{s}    Shift: prime",
        .{
            faceName(controls.up),
            faceName(controls.down),
            faceName(controls.right),
            faceName(controls.left),
            faceName(controls.front),
            faceName(controls.back),
        },
    ) catch unreachable;

    const panel_color = rl.Color.init(12, 14, 18, 210);
    rl.drawRectangle(16, 16, 590, 112, panel_color);
    rl.drawRectangleLines(16, 16, 590, 112, rl.Color.init(70, 76, 88, 255));
    rl.drawText("Rubix", 32, 28, 28, rl.Color.ray_white);
    rl.drawText(controls_text, 32, 68, 16, rl.Color.light_gray);
    rl.drawText("Tab: scramble    Space: reset    Drag: orbit    Wheel: zoom    Esc: quit", 32, 94, 16, rl.Color.light_gray);

    const status_width = rl.measureText(status, 24);
    const x = rl.getScreenWidth() - status_width - 32;
    rl.drawText(status, x, 28, 24, rl.Color.ray_white);
}

fn faceName(face: Face) []const u8 {
    return switch (face) {
        .up => "U",
        .down => "D",
        .right => "R",
        .left => "L",
        .front => "F",
        .back => "B",
    };
}
