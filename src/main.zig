const Cube = @import("cube.zig").Cube;
const render = @import("render.zig");

pub fn main() void {
    var cube = Cube.solved();
    render.printCube(cube);
    cube.turnU();
    render.printCube(cube);
}
