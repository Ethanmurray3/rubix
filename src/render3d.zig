const rl = @import("raylib");
const cube_mod = @import("cube.zig");

const Cube = cube_mod.Cube;
const CubeColor = cube_mod.Color;
const Face = cube_mod.Face;

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

const spacing: f32 = 1.04;
const core_size: f32 = 3.0;
const face_coord: f32 = 1.54;
const sticker_size: f32 = 0.88;
const sticker_thickness: f32 = 0.08;

pub fn drawCube(cube: Cube, orientation: Orientation, highlight_face: ?Face, highlight_alpha: u8) void {
    rl.drawCubeV(
        vec3(0, 0, 0),
        vec3(core_size, core_size, core_size),
        rl.Color.init(24, 27, 31, 255),
    );
    rl.drawCubeWiresV(
        vec3(0, 0, 0),
        vec3(core_size, core_size, core_size),
        rl.Color.init(5, 5, 7, 255),
    );

    drawFace(cube, orientation, .up);
    drawFace(cube, orientation, .down);
    drawFace(cube, orientation, .front);
    drawFace(cube, orientation, .back);
    drawFace(cube, orientation, .left);
    drawFace(cube, orientation, .right);

    if (highlight_face) |face| {
        if (highlight_alpha > 0) drawHighlight(orientation, face, highlight_alpha);
    }
}

fn drawFace(cube: Cube, orientation: Orientation, face: Face) void {
    for (0..3) |row| {
        for (0..3) |col| {
            const index = row * 3 + col;
            const sticker = stickerTransform(face, row, col);
            rl.drawCubeV(
                orientation.transformPosition(sticker.position),
                orientation.transformSize(sticker.size),
                rayColor(cube.facelet(face, index)),
            );
            rl.drawCubeWiresV(
                orientation.transformPosition(sticker.position),
                orientation.transformSize(sticker.size),
                rl.Color.init(12, 12, 14, 255),
            );
        }
    }
}

fn drawHighlight(orientation: Orientation, face: Face, alpha: u8) void {
    const highlight_size: f32 = 3.08;
    const thickness: f32 = 0.06;
    const color = rl.Color.init(255, 255, 255, alpha);

    switch (face) {
        .up => drawOrientedCube(orientation, vec3(0, face_coord + 0.04, 0), vec3(highlight_size, thickness, highlight_size), color),
        .down => drawOrientedCube(orientation, vec3(0, -face_coord - 0.04, 0), vec3(highlight_size, thickness, highlight_size), color),
        .front => drawOrientedCube(orientation, vec3(0, 0, face_coord + 0.04), vec3(highlight_size, highlight_size, thickness), color),
        .back => drawOrientedCube(orientation, vec3(0, 0, -face_coord - 0.04), vec3(highlight_size, highlight_size, thickness), color),
        .left => drawOrientedCube(orientation, vec3(-face_coord - 0.04, 0, 0), vec3(thickness, highlight_size, highlight_size), color),
        .right => drawOrientedCube(orientation, vec3(face_coord + 0.04, 0, 0), vec3(thickness, highlight_size, highlight_size), color),
    }
}

const StickerTransform = struct {
    position: rl.Vector3,
    size: rl.Vector3,
};

fn stickerTransform(face: Face, row: usize, col: usize) StickerTransform {
    const col_pos = (@as(f32, @floatFromInt(col)) - 1.0) * spacing;
    const row_pos = (1.0 - @as(f32, @floatFromInt(row))) * spacing;

    return switch (face) {
        .up => .{
            .position = vec3(col_pos, face_coord, -row_pos),
            .size = vec3(sticker_size, sticker_thickness, sticker_size),
        },
        .down => .{
            .position = vec3(col_pos, -face_coord, row_pos),
            .size = vec3(sticker_size, sticker_thickness, sticker_size),
        },
        .front => .{
            .position = vec3(col_pos, row_pos, face_coord),
            .size = vec3(sticker_size, sticker_size, sticker_thickness),
        },
        .back => .{
            .position = vec3(-col_pos, row_pos, -face_coord),
            .size = vec3(sticker_size, sticker_size, sticker_thickness),
        },
        .left => .{
            .position = vec3(-face_coord, row_pos, col_pos),
            .size = vec3(sticker_thickness, sticker_size, sticker_size),
        },
        .right => .{
            .position = vec3(face_coord, row_pos, -col_pos),
            .size = vec3(sticker_thickness, sticker_size, sticker_size),
        },
    };
}

fn rayColor(color: CubeColor) rl.Color {
    return switch (color) {
        .white => rl.Color.init(245, 245, 238, 255),
        .yellow => rl.Color.init(252, 211, 43, 255),
        .green => rl.Color.init(30, 176, 85, 255),
        .blue => rl.Color.init(38, 96, 202, 255),
        .orange => rl.Color.init(242, 125, 32, 255),
        .red => rl.Color.init(218, 45, 50, 255),
    };
}

fn drawOrientedCube(orientation: Orientation, position: rl.Vector3, size: rl.Vector3, color: rl.Color) void {
    rl.drawCubeV(orientation.transformPosition(position), orientation.transformSize(size), color);
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

fn vec3(x: f32, y: f32, z: f32) rl.Vector3 {
    return .{ .x = x, .y = y, .z = z };
}
