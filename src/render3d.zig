const rl = @import("raylib");
const cube_mod = @import("cube.zig");

const Cube = cube_mod.Cube;
const CubeColor = cube_mod.Color;
const Face = cube_mod.Face;

const spacing: f32 = 1.04;
const core_size: f32 = 3.0;
const face_coord: f32 = 1.54;
const sticker_size: f32 = 0.88;
const sticker_thickness: f32 = 0.08;

pub fn drawCube(cube: Cube, highlight_face: ?Face, highlight_alpha: u8) void {
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

    drawFace(cube, .up);
    drawFace(cube, .down);
    drawFace(cube, .front);
    drawFace(cube, .back);
    drawFace(cube, .left);
    drawFace(cube, .right);

    if (highlight_face) |face| {
        if (highlight_alpha > 0) drawHighlight(face, highlight_alpha);
    }
}

fn drawFace(cube: Cube, face: Face) void {
    for (0..3) |row| {
        for (0..3) |col| {
            const index = row * 3 + col;
            const sticker = stickerTransform(face, row, col);
            rl.drawCubeV(sticker.position, sticker.size, rayColor(cube.facelet(face, index)));
            rl.drawCubeWiresV(sticker.position, sticker.size, rl.Color.init(12, 12, 14, 255));
        }
    }
}

fn drawHighlight(face: Face, alpha: u8) void {
    const highlight_size: f32 = 3.08;
    const thickness: f32 = 0.06;
    const color = rl.Color.init(255, 255, 255, alpha);

    switch (face) {
        .up => rl.drawCubeV(vec3(0, face_coord + 0.04, 0), vec3(highlight_size, thickness, highlight_size), color),
        .down => rl.drawCubeV(vec3(0, -face_coord - 0.04, 0), vec3(highlight_size, thickness, highlight_size), color),
        .front => rl.drawCubeV(vec3(0, 0, face_coord + 0.04), vec3(highlight_size, highlight_size, thickness), color),
        .back => rl.drawCubeV(vec3(0, 0, -face_coord - 0.04), vec3(highlight_size, highlight_size, thickness), color),
        .left => rl.drawCubeV(vec3(-face_coord - 0.04, 0, 0), vec3(thickness, highlight_size, highlight_size), color),
        .right => rl.drawCubeV(vec3(face_coord + 0.04, 0, 0), vec3(thickness, highlight_size, highlight_size), color),
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

fn vec3(x: f32, y: f32, z: f32) rl.Vector3 {
    return .{ .x = x, .y = y, .z = z };
}
