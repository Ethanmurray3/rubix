const std = @import("std");
const rl = @import("raylib");
const animation = @import("animation.zig");
const controls = @import("controls.zig");
const cube_mod = @import("cube.zig");
const render = @import("render.zig");
const ui = @import("ui.zig");

pub const target_fps = 240;

pub fn initWindow() void {
    rl.setConfigFlags(.{
        .window_resizable = true,
        .msaa_4x_hint = true,
        .vsync_hint = true,
    });
    rl.initWindow(1280, 800, "Rubix");
    rl.setTargetFPS(target_fps);
}

pub fn drawFrame(
    cube: cube_mod.Cube,
    camera: rl.Camera3D,
    orientation: render.Orientation,
    last: ui.LastAction,
    view_controls: controls.ViewControls,
    visual_turn: ?animation.VisualTurn,
) void {
    rl.beginDrawing();
    defer rl.endDrawing();

    rl.clearBackground(rl.Color.init(180, 221, 245, 255));

    camera.begin();
    render.drawCube(cube, orientation, visual_turn);
    camera.end();

    drawOverlay(last, view_controls);
}

fn drawOverlay(last: ui.LastAction, view_controls: controls.ViewControls) void {
    var controls_buffer: [160]u8 = undefined;
    const controls_text = std.fmt.bufPrintZ(
        &controls_buffer,
        "W:{s} S:{s} D:{s} A:{s} Q:{s} E:{s}    Shift: prime",
        .{
            ui.faceName(view_controls.up),
            ui.faceName(view_controls.down),
            ui.faceName(view_controls.right),
            ui.faceName(view_controls.left),
            ui.faceName(view_controls.front),
            ui.faceName(view_controls.back),
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
