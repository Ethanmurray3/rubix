const Cube = @import("cube.zig").Cube;
const render = @import("render.zig");

pub fn main() void {
    var cube = Cube.solved();
    render.printCube(cube);

    cube.turnR();
    cube.turnR();
    cube.turnLPrime();
    cube.turnD();
    cube.turnF();
    cube.turnF();
    cube.turnRPrime();
    cube.turnDPrime();
    cube.turnRPrime();
    cube.turnL();
    cube.turnUPrime();
    cube.turnD();
    cube.turnR();
    cube.turnD();
    cube.turnB();
    cube.turnB();
    cube.turnRPrime();
    cube.turnU();
    cube.turnD();
    cube.turnD();

    render.printCube(cube);
}
