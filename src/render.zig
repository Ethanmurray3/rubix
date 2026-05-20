const rl = @import("raylib");
const animation = @import("animation.zig");
const cube_mod = @import("cube.zig");

const Cube = cube_mod.Cube;
const CubeColor = cube_mod.Color;
const Face = cube_mod.Face;
const FaceletCoord = cube_mod.FaceletCoord;

pub const Axis = enum {
    positive_x,
    negative_x,
    positive_y,
    negative_y,
    positive_z,
    negative_z,
};

pub const Orientation = struct {
    right: Axis = .positive_x,
    up: Axis = .positive_y,
    front: Axis = .positive_z,

    pub fn rotateAroundWorldAxis(self: *Orientation, axis: Axis, positive: bool) void {
        self.right = rotateAxis(self.right, axis, positive);
        self.up = rotateAxis(self.up, axis, positive);
        self.front = rotateAxis(self.front, axis, positive);
    }

    pub fn faceOnWorldAxis(self: Orientation, axis: Axis) Face {
        if (self.right == axis) return .right;
        if (oppositeAxis(self.right) == axis) return .left;
        if (self.up == axis) return .up;
        if (oppositeAxis(self.up) == axis) return .down;
        if (self.front == axis) return .front;
        if (oppositeAxis(self.front) == axis) return .back;
        unreachable;
    }

    fn transformPosition(self: Orientation, position: rl.Vector3) rl.Vector3 {
        const x_axis = axisVector(self.right);
        const y_axis = axisVector(self.up);
        const z_axis = axisVector(self.front);

        return .{
            .x = position.x * x_axis.x + position.y * y_axis.x + position.z * z_axis.x,
            .y = position.x * x_axis.y + position.y * y_axis.y + position.z * z_axis.y,
            .z = position.x * x_axis.z + position.y * y_axis.z + position.z * z_axis.z,
        };
    }

    fn transformSize(self: Orientation, size: rl.Vector3) rl.Vector3 {
        const x_axis = axisVector(self.right);
        const y_axis = axisVector(self.up);
        const z_axis = axisVector(self.front);

        return .{
            .x = size.x * absAxisComponent(x_axis.x) + size.y * absAxisComponent(y_axis.x) + size.z * absAxisComponent(z_axis.x),
            .y = size.x * absAxisComponent(x_axis.y) + size.y * absAxisComponent(y_axis.y) + size.z * absAxisComponent(z_axis.y),
            .z = size.x * absAxisComponent(x_axis.z) + size.y * absAxisComponent(y_axis.z) + size.z * absAxisComponent(z_axis.z),
        };
    }
};

const cubie_spacing: f32 = 1.04;
const cubie_size: f32 = 0.94;
const sticker_size: f32 = 0.74;
const sticker_thickness: f32 = 0.055;
const sticker_offset: f32 = (cubie_size + sticker_thickness) * 0.5 + 0.012;
const coord_values = [_]i2{ -1, 0, 1 };

pub fn drawCube(
    cube: Cube,
    orientation: Orientation,
    visual_turn: ?animation.VisualTurn,
) void {
    for (coord_values) |x| {
        for (coord_values) |y| {
            for (coord_values) |z| {
                if (x == 0 and y == 0 and z == 0) continue;
                drawCubie(
                    cube,
                    orientation,
                    visual_turn,
                    .{ .x = x, .y = y, .z = z },
                );
            }
        }
    }
}

fn drawCubie(
    cube: Cube,
    orientation: Orientation,
    visual_turn: ?animation.VisualTurn,
    coord: FaceletCoord,
) void {
    if (visual_turn) |turn| {
        if (cubieInMovingLayer(coord, turn.face)) {
            drawTransformedCubie(cube, orientation, coord, turn.face, turn.angle_degrees);
            return;
        }
    }

    drawStaticCubie(cube, orientation, coord);
}

fn drawStaticCubie(cube: Cube, orientation: Orientation, coord: FaceletCoord) void {
    drawCubieBody(
        orientation.transformPosition(cubieCenter(coord)),
        orientation.transformSize(vec3(cubie_size, cubie_size, cubie_size)),
    );

    inline for (.{ Face.up, Face.down, Face.front, Face.back, Face.left, Face.right }) |face| {
        if (coordOnFace(coord, face)) {
            const sticker = stickerTransform(coord, face);
            const index = cube_mod.faceletIndex(face, coord);
            drawSticker(
                orientation.transformPosition(sticker.position),
                orientation.transformSize(sticker.size),
                rayColor(cube.facelet(face, index)),
            );
        }
    }
}

fn drawTransformedCubie(
    cube: Cube,
    orientation: Orientation,
    coord: FaceletCoord,
    turn_face: Face,
    angle_degrees: f32,
) void {
    const normal = faceNormal(turn_face);

    rl.gl.rlPushMatrix();
    defer rl.gl.rlPopMatrix();

    applyOrientation(orientation);
    rl.gl.rlRotatef(angle_degrees, normal.x, normal.y, normal.z);

    drawCubieBody(cubieCenter(coord), vec3(cubie_size, cubie_size, cubie_size));

    inline for (.{ Face.up, Face.down, Face.front, Face.back, Face.left, Face.right }) |face| {
        if (coordOnFace(coord, face)) {
            const sticker = stickerTransform(coord, face);
            const index = cube_mod.faceletIndex(face, coord);
            drawSticker(sticker.position, sticker.size, rayColor(cube.facelet(face, index)));
        }
    }
}

fn drawCubieBody(position: rl.Vector3, size: rl.Vector3) void {
    rl.drawCubeV(position, size, rl.Color.init(38, 42, 48, 255));
    rl.drawCubeWiresV(position, size, rl.Color.init(21, 24, 29, 190));
}

fn drawSticker(position: rl.Vector3, size: rl.Vector3, color: rl.Color) void {
    rl.drawCubeV(position, size, color);
    rl.drawCubeWiresV(position, size, rl.Color.init(22, 24, 28, 210));
}

const StickerTransform = struct {
    position: rl.Vector3,
    size: rl.Vector3,
};

fn cubieCenter(coord: FaceletCoord) rl.Vector3 {
    return vec3(
        @as(f32, @floatFromInt(coord.x)) * cubie_spacing,
        @as(f32, @floatFromInt(coord.y)) * cubie_spacing,
        @as(f32, @floatFromInt(coord.z)) * cubie_spacing,
    );
}

fn stickerTransform(coord: FaceletCoord, face: Face) StickerTransform {
    const center = cubieCenter(coord);
    const normal = faceNormal(face);

    return switch (face) {
        .up => .{
            .position = add(center, scale(normal, sticker_offset)),
            .size = vec3(sticker_size, sticker_thickness, sticker_size),
        },
        .down => .{
            .position = add(center, scale(normal, sticker_offset)),
            .size = vec3(sticker_size, sticker_thickness, sticker_size),
        },
        .front => .{
            .position = add(center, scale(normal, sticker_offset)),
            .size = vec3(sticker_size, sticker_size, sticker_thickness),
        },
        .back => .{
            .position = add(center, scale(normal, sticker_offset)),
            .size = vec3(sticker_size, sticker_size, sticker_thickness),
        },
        .left => .{
            .position = add(center, scale(normal, sticker_offset)),
            .size = vec3(sticker_thickness, sticker_size, sticker_size),
        },
        .right => .{
            .position = add(center, scale(normal, sticker_offset)),
            .size = vec3(sticker_thickness, sticker_size, sticker_size),
        },
    };
}

fn coordOnFace(coord: FaceletCoord, face: Face) bool {
    return switch (face) {
        .up => coord.y == 1,
        .down => coord.y == -1,
        .front => coord.z == 1,
        .back => coord.z == -1,
        .left => coord.x == -1,
        .right => coord.x == 1,
    };
}

fn cubieInMovingLayer(coord: FaceletCoord, face: Face) bool {
    return coordOnFace(coord, face);
}

fn faceNormal(face: Face) rl.Vector3 {
    return switch (face) {
        .up => vec3(0, 1, 0),
        .down => vec3(0, -1, 0),
        .front => vec3(0, 0, 1),
        .back => vec3(0, 0, -1),
        .left => vec3(-1, 0, 0),
        .right => vec3(1, 0, 0),
    };
}

fn applyOrientation(orientation: Orientation) void {
    const x_axis = axisVector(orientation.right);
    const y_axis = axisVector(orientation.up);
    const z_axis = axisVector(orientation.front);
    const matrix = [_]f32{
        x_axis.x, x_axis.y, x_axis.z, 0,
        y_axis.x, y_axis.y, y_axis.z, 0,
        z_axis.x, z_axis.y, z_axis.z, 0,
        0,        0,        0,        1,
    };

    rl.gl.rlMultMatrixf(&matrix);
}

fn rayColor(color: CubeColor) rl.Color {
    return switch (color) {
        .white => rl.Color.init(250, 247, 239, 255),
        .yellow => rl.Color.init(255, 225, 87, 255),
        .green => rl.Color.init(101, 211, 132, 255),
        .blue => rl.Color.init(92, 146, 238, 255),
        .orange => rl.Color.init(255, 164, 93, 255),
        .red => rl.Color.init(246, 92, 104, 255),
    };
}

fn rotateAxis(axis: Axis, around: Axis, positive: bool) Axis {
    if (sameAxisLine(axis, around)) return axis;

    const axis_vector = axisVector(axis);
    const around_vector = axisVector(around);
    const rotated = if (positive)
        cross(around_vector, axis_vector)
    else
        cross(axis_vector, around_vector);

    return axisFromVector(rotated);
}

fn sameAxisLine(a: Axis, b: Axis) bool {
    return switch (a) {
        .positive_x, .negative_x => b == .positive_x or b == .negative_x,
        .positive_y, .negative_y => b == .positive_y or b == .negative_y,
        .positive_z, .negative_z => b == .positive_z or b == .negative_z,
    };
}

pub fn oppositeAxis(axis: Axis) Axis {
    return switch (axis) {
        .positive_x => .negative_x,
        .negative_x => .positive_x,
        .positive_y => .negative_y,
        .negative_y => .positive_y,
        .positive_z => .negative_z,
        .negative_z => .positive_z,
    };
}

pub fn axisVector(axis: Axis) rl.Vector3 {
    return switch (axis) {
        .positive_x => vec3(1, 0, 0),
        .negative_x => vec3(-1, 0, 0),
        .positive_y => vec3(0, 1, 0),
        .negative_y => vec3(0, -1, 0),
        .positive_z => vec3(0, 0, 1),
        .negative_z => vec3(0, 0, -1),
    };
}

fn axisFromVector(vector: rl.Vector3) Axis {
    if (vector.x == 1) return .positive_x;
    if (vector.x == -1) return .negative_x;
    if (vector.y == 1) return .positive_y;
    if (vector.y == -1) return .negative_y;
    if (vector.z == 1) return .positive_z;
    if (vector.z == -1) return .negative_z;
    unreachable;
}

fn cross(a: rl.Vector3, b: rl.Vector3) rl.Vector3 {
    return .{
        .x = a.y * b.z - a.z * b.y,
        .y = a.z * b.x - a.x * b.z,
        .z = a.x * b.y - a.y * b.x,
    };
}

fn absAxisComponent(component: f32) f32 {
    return if (component < 0) -component else component;
}

fn add(a: rl.Vector3, b: rl.Vector3) rl.Vector3 {
    return .{
        .x = a.x + b.x,
        .y = a.y + b.y,
        .z = a.z + b.z,
    };
}

fn scale(vector: rl.Vector3, amount: f32) rl.Vector3 {
    return .{
        .x = vector.x * amount,
        .y = vector.y * amount,
        .z = vector.z * amount,
    };
}

fn vec3(x: f32, y: f32, z: f32) rl.Vector3 {
    return .{ .x = x, .y = y, .z = z };
}
