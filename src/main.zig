const Cube = @import("cube.zig").Cube;
const render = @import("render.zig");

pub fn main() void {
    var cube = Cube.solved();
    render.printCubeCompact(cube);
    // render.printCubeSplit(cube);

    cube.turnR();

    render.printCubeCompact(cube);
}
