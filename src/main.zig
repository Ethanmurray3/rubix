const std = @import("std");
const cube_mod = @import("cube.zig");
const Cube = cube_mod.Cube;

const default_iterations = 100_000;

pub fn main(init: std.process.Init) void {
    const iterations = parseIterations(init.minimal.args) catch |err| {
        std.debug.print("invalid iteration count: {t}\n", .{err});
        std.debug.print("usage: rubix [iterations]\n", .{});
        return;
    };

    var seed: u64 = undefined;
    init.io.random(std.mem.asBytes(&seed));

    var prng = std.Random.DefaultPrng.init(seed);
    const random = prng.random();

    var checksum: cube_mod.CubeBits = 0;
    const start = std.Io.Clock.boot.now(init.io);
    var cube = Cube.solved();

    for (0..iterations) |_| {
        _ = cube.scrambleWithRandom(random);
        checksum ^= cube.bits;
    }

    const end = std.Io.Clock.boot.now(init.io);
    const elapsed = start.durationTo(end);

    std.debug.print("scrambles: {}\n", .{iterations});
    std.debug.print("elapsed: {f}\n", .{elapsed});
    std.debug.print("checksum: {x}\n", .{checksum});
}

fn parseIterations(args: std.process.Args) !usize {
    var iterator = std.process.Args.Iterator.init(args);
    _ = iterator.skip();

    const raw_iterations = iterator.next() orelse return default_iterations;
    return std.fmt.parseInt(usize, raw_iterations, 10);
}
