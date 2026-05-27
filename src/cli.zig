const std = @import("std");
const cli_core = @import("cli_core.zig");

pub fn main(init: std.process.Init) !u8 {
    var iterator = try std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa);
    defer iterator.deinit();

    _ = iterator.next();
    var args: std.ArrayList([]const u8) = .empty;
    defer args.deinit(init.gpa);
    while (iterator.next()) |arg| {
        try args.append(init.gpa, arg);
    }

    var seed: u64 = undefined;
    init.io.random(std.mem.asBytes(&seed));

    const result = try cli_core.runAlloc(init.gpa, args.items, seed);
    defer result.deinit(init.gpa);

    try std.Io.File.stdout().writeStreamingAll(init.io, result.stdout);
    try std.Io.File.stderr().writeStreamingAll(init.io, result.stderr);
    return @intFromEnum(result.exit_code);
}
