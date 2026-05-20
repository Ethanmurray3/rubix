const std = @import("std");
const rl = @import("raylib");
const animation = @import("animation.zig");
const cube_mod = @import("cube.zig");
const render = @import("render.zig");

const PlayerAnimator = animation.PlayerAnimator;
const ScrambleAnimator = animation.ScrambleAnimator;
const Cube = cube_mod.Cube;
const Face = cube_mod.Face;
const Move = cube_mod.Move;
const Axis = render.Axis;
const Orientation = render.Orientation;

const render_target_fps = 240;

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
    scramble: [:0]const u8 = "",
};

const ViewControls = struct {
    up: Face,
    down: Face,
    right: Face,
    left: Face,
    front: Face,
    back: Face,
};

const ViewAxes = struct {
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
    rl.setTargetFPS(render_target_fps);

    var orbit: CameraOrbit = .{};
    var orientation: Orientation = .{};
    var player_animator: PlayerAnimator = .{};
    var scramble_animator: ScrambleAnimator = .{};
    var last: LastAction = .{};
    var scramble_buffer: [128]u8 = undefined;

    while (!rl.windowShouldClose()) {
        const frame_time = rl.getFrameTime();
        updateCameraOrbit(&orbit);
        const camera = orbit.camera();
        const view_axes = cameraViewAxes(camera);
        var controls = viewControls(view_axes, orientation);

        if (readOrientationInput(&orientation, view_axes)) {
            controls = viewControls(view_axes, orientation);
            last = .{
                .status = "Reoriented",
                .scramble = last.scramble,
            };
        }

        if (rl.isKeyPressed(.tab)) {
            cube = Cube.solved();
            player_animator.clear();
            scramble_animator.clear();
            const scramble = Cube.scramble(prng.random());
            scramble_animator.start(scramble);
            const notation = scrambleNotationZ(&scramble_buffer, scramble);
            rl.setClipboardText(notation);
            last = .{
                .status = "Scrambling",
                .scramble = notation,
            };
        }

        if (rl.isKeyPressed(.space)) {
            cube = Cube.solved();
            orientation = .{};
            player_animator.clear();
            scramble_animator.clear();
            last = .{
                .status = "Solved",
                .scramble = "",
            };
        }

        const visual_turn: ?animation.VisualTurn = if (scramble_animator.isRunning()) scramble: {
            if (scramble_animator.update(frame_time, &cube)) |move| {
                last.status = moveNameZ(move);
            } else if (scramble_animator.activeMove()) |move| {
                last.status = moveNameZ(move);
            }
            break :scramble scramble_animator.visualTurn();
        } else player: {
            if (readMoveInput(controls)) |move| {
                player_animator.submit(move);
                last = .{
                    .status = moveNameZ(move),
                    .scramble = "",
                };
            }

            if (player_animator.update(frame_time, &cube)) |move| {
                last.status = moveNameZ(move);
            } else if (player_animator.activeMove()) |move| {
                last.status = moveNameZ(move);
            }

            break :player player_animator.visualTurn();
        };

        if (cube.isSolved() and player_animator.isIdle() and scramble_animator.isIdle()) {
            last.status = "Solved";
        }

        draw(cube, camera, orientation, last, controls, visual_turn);
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

fn readOrientationInput(orientation: *Orientation, view_axes: ViewAxes) bool {
    if (rl.isKeyPressed(.up)) {
        orientation.rotateAroundWorldAxis(view_axes.right, false);
        return true;
    }
    if (rl.isKeyPressed(.down)) {
        orientation.rotateAroundWorldAxis(view_axes.right, true);
        return true;
    }
    if (rl.isKeyPressed(.left)) {
        orientation.rotateAroundWorldAxis(view_axes.up, false);
        return true;
    }
    if (rl.isKeyPressed(.right)) {
        orientation.rotateAroundWorldAxis(view_axes.up, true);
        return true;
    }
    if (rl.isKeyPressed(.z)) {
        orientation.rotateAroundWorldAxis(view_axes.front, false);
        return true;
    }
    if (rl.isKeyPressed(.x)) {
        orientation.rotateAroundWorldAxis(view_axes.front, true);
        return true;
    }
    if (rl.isKeyPressed(.c)) {
        orientation.rotateAroundWorldAxis(view_axes.right, true);
        orientation.rotateAroundWorldAxis(view_axes.right, true);
        return true;
    }
    if (rl.isKeyPressed(.zero)) {
        orientation.* = .{};
        return true;
    }

    return false;
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

fn cameraViewAxes(camera: rl.Camera3D) ViewAxes {
    const camera_axis = nearestAxis(camera.position);
    const forward = normalize(vec3Scale(camera.position, -1));
    const right = normalize(cross(.{ .x = 0, .y = 1, .z = 0 }, camera.position));
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

fn viewControls(view_axes: ViewAxes, orientation: Orientation) ViewControls {
    return .{
        .up = orientation.faceOnWorldAxis(view_axes.up),
        .down = orientation.faceOnWorldAxis(render.oppositeAxis(view_axes.up)),
        .right = orientation.faceOnWorldAxis(view_axes.right),
        .left = orientation.faceOnWorldAxis(render.oppositeAxis(view_axes.right)),
        .front = orientation.faceOnWorldAxis(view_axes.front),
        .back = orientation.faceOnWorldAxis(render.oppositeAxis(view_axes.front)),
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

fn draw(
    cube: Cube,
    camera: rl.Camera3D,
    orientation: Orientation,
    last: LastAction,
    controls: ViewControls,
    visual_turn: ?animation.VisualTurn,
) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(rl.Color.init(180, 221, 245, 255));

    camera.begin();
    render.drawCube(cube, orientation, visual_turn);
    camera.end();

    drawOverlay(last, controls);
}

fn drawOverlay(last: LastAction, controls: ViewControls) void {
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

    const panel_height: i32 = if (last.scramble.len == 0) 136 else 164;
    const panel_color = rl.Color.init(255, 255, 255, 218);
    const text_color = rl.Color.init(42, 48, 58, 255);
    const muted_color = rl.Color.init(80, 91, 107, 255);

    rl.drawRectangle(16, 16, 720, panel_height, panel_color);
    rl.drawRectangleLines(16, 16, 720, panel_height, rl.Color.init(135, 169, 190, 255));
    rl.drawText("Rubix", 32, 28, 28, text_color);
    rl.drawText(controls_text, 32, 68, 16, muted_color);
    rl.drawText("Arrows/Z/X: rotate cube    C: flip    0: reset orientation", 32, 94, 16, muted_color);
    rl.drawText("Tab: scramble    Space: reset    Drag: orbit    Wheel: zoom    Esc: quit", 32, 120, 16, muted_color);
    if (last.scramble.len != 0) {
        rl.drawText(last.scramble, 32, 146, 16, text_color);
    }

    const status_width = rl.measureText(last.status, 24);
    const x = @max(32, rl.getScreenWidth() - status_width - 32);
    rl.drawText(last.status, x, 28, 24, text_color);
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

fn scrambleNotationZ(buffer: *[128]u8, scramble: cube_mod.Scramble) [:0]const u8 {
    var position: usize = 0;

    for (scramble.moves, 0..) |move, index| {
        if (index != 0) {
            buffer[position] = ' ';
            position += 1;
        }

        const name = cube_mod.moveName(move);
        std.mem.copyForwards(u8, buffer[position .. position + name.len], name);
        position += name.len;
    }

    buffer[position] = 0;
    return buffer[0..position :0];
}
