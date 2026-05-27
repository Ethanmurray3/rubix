const rl = @import("raylib");
const camera = @import("camera.zig");
const rubix = @import("rubix");
const render = @import("render.zig");
const facelet = rubix.facelet;
const move_mod = rubix.move;

const Face = facelet.Face;
const Move = move_mod.Move;

pub const ViewControls = struct {
    up: Face,
    down: Face,
    right: Face,
    left: Face,
    front: Face,
    back: Face,
};

pub fn fromViewAxes(view_axes: camera.ViewAxes, orientation: render.Orientation) ViewControls {
    return .{
        .up = orientation.faceOnWorldAxis(view_axes.up),
        .down = orientation.faceOnWorldAxis(render.oppositeAxis(view_axes.up)),
        .right = orientation.faceOnWorldAxis(view_axes.right),
        .left = orientation.faceOnWorldAxis(render.oppositeAxis(view_axes.right)),
        .front = orientation.faceOnWorldAxis(view_axes.front),
        .back = orientation.faceOnWorldAxis(render.oppositeAxis(view_axes.front)),
    };
}

pub fn readMoveInput(view_controls: ViewControls) ?Move {
    inline for (.{ .w, .s, .d, .a, .q, .e }) |key| {
        if (turnKeyPressed(key)) {
            return moveForKey(key, view_controls, shiftDown());
        }
    }
    return null;
}

pub fn readOrientationInput(orientation: *render.Orientation, view_axes: camera.ViewAxes) bool {
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

fn turnKeyPressed(key: rl.KeyboardKey) bool {
    return rl.isKeyPressed(key) or rl.isKeyPressedRepeat(key);
}

fn shiftDown() bool {
    return rl.isKeyDown(.left_shift) or rl.isKeyDown(.right_shift);
}

pub fn moveForKey(key: rl.KeyboardKey, view_controls: ViewControls, prime: bool) ?Move {
    const face = switch (key) {
        .w => view_controls.up,
        .s => view_controls.down,
        .d => view_controls.right,
        .a => view_controls.left,
        .q => view_controls.front,
        .e => view_controls.back,
        else => return null,
    };
    return moveForFace(face, prime);
}

pub fn moveForFace(face: Face, prime: bool) Move {
    return switch (face) {
        .up => if (prime) .UPrime else .U,
        .down => if (prime) .DPrime else .D,
        .right => if (prime) .RPrime else .R,
        .left => if (prime) .LPrime else .L,
        .front => if (prime) .FPrime else .F,
        .back => if (prime) .BPrime else .B,
    };
}
