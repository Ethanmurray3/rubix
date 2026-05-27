const std = @import("std");
const cube_mod = @import("cube.zig");
const facelet = @import("facelet.zig");
const notation = @import("notation.zig");
const scramble_mod = @import("scramble.zig");

pub const ExitCode = enum(u8) {
    success = 0,
    usage = 1,
    parse = 2,
    validation = 3,
};

pub const Result = struct {
    exit_code: ExitCode,
    stdout: []u8,
    stderr: []u8,

    pub fn deinit(self: Result, allocator: std.mem.Allocator) void {
        allocator.free(self.stdout);
        allocator.free(self.stderr);
    }
};

pub const usage_text =
    \\Usage: rubix-cli <command> [args]
    \\
    \\Commands:
    \\  apply <algorithm>       Print facelet string after applying algorithm to solved cube
    \\  check <algorithm>       Print solved or unsolved after applying algorithm
    \\  invert <algorithm>      Print normalized inverse algorithm
    \\  scramble [--seed <n>]   Print a scramble; seed makes output deterministic
    \\  help                    Print this help
    \\
;

pub fn runAlloc(allocator: std.mem.Allocator, args: []const []const u8, default_seed: u64) !Result {
    if (args.len == 0) return textResult(allocator, .usage, "", usage_text);

    const command = args[0];
    if (std.mem.eql(u8, command, "help") or std.mem.eql(u8, command, "--help") or std.mem.eql(u8, command, "-h")) {
        return textResult(allocator, .success, usage_text, "");
    }
    if (std.mem.eql(u8, command, "apply")) return applyCommand(allocator, args[1..]);
    if (std.mem.eql(u8, command, "check")) return checkCommand(allocator, args[1..]);
    if (std.mem.eql(u8, command, "invert")) return invertCommand(allocator, args[1..]);
    if (std.mem.eql(u8, command, "scramble")) return scrambleCommand(allocator, args[1..], default_seed);

    return allocPrintResult(allocator, .usage, "", "rubix-cli: unknown command \"{s}\"\n", .{command});
}

fn applyCommand(allocator: std.mem.Allocator, args: []const []const u8) !Result {
    if (args.len != 1) return textResult(allocator, .usage, "", "rubix-cli: apply requires exactly one algorithm\n");

    const moves = notation.parseAlgorithm(allocator, args[0]) catch |err| {
        return parseErrorResult(allocator, args[0], err);
    };
    defer allocator.free(moves);

    var cube = cube_mod.Cube.solved();
    cube.applyMoves(moves);
    cube.validate() catch |err| return validationErrorResult(allocator, err);

    var out: [55]u8 = undefined;
    writeFaceletString(cube, out[0..54]);
    out[54] = '\n';
    return textResult(allocator, .success, out[0..], "");
}

fn checkCommand(allocator: std.mem.Allocator, args: []const []const u8) !Result {
    if (args.len != 1) return textResult(allocator, .usage, "", "rubix-cli: check requires exactly one algorithm\n");

    const moves = notation.parseAlgorithm(allocator, args[0]) catch |err| {
        return parseErrorResult(allocator, args[0], err);
    };
    defer allocator.free(moves);

    var cube = cube_mod.Cube.solved();
    cube.applyMoves(moves);
    cube.validate() catch |err| return validationErrorResult(allocator, err);

    return textResult(allocator, .success, if (cube.isSolved()) "solved\n" else "unsolved\n", "");
}

fn invertCommand(allocator: std.mem.Allocator, args: []const []const u8) !Result {
    if (args.len != 1) return textResult(allocator, .usage, "", "rubix-cli: invert requires exactly one algorithm\n");

    const moves = notation.parseAlgorithm(allocator, args[0]) catch |err| {
        return parseErrorResult(allocator, args[0], err);
    };
    defer allocator.free(moves);

    const inverse = try allocator.alloc(@import("move.zig").Move, moves.len);
    defer allocator.free(inverse);
    _ = notation.inverseAlgorithmInto(moves, inverse) catch unreachable;

    var buffer: [256]u8 = undefined;
    const formatted = notation.formatAlgorithmInto(&buffer, inverse) catch {
        return textResult(allocator, .validation, "", "rubix-cli: formatted algorithm exceeded output buffer\n");
    };
    return allocPrintResult(allocator, .success, "{s}\n", "", .{formatted});
}

fn scrambleCommand(allocator: std.mem.Allocator, args: []const []const u8, default_seed: u64) !Result {
    var seed = default_seed;
    var index: usize = 0;
    while (index < args.len) {
        if (std.mem.eql(u8, args[index], "--seed")) {
            if (index + 1 >= args.len) return textResult(allocator, .usage, "", "rubix-cli: --seed requires a value\n");
            seed = std.fmt.parseUnsigned(u64, args[index + 1], 10) catch {
                return allocPrintResult(allocator, .usage, "", "rubix-cli: invalid seed \"{s}\"\n", .{args[index + 1]});
            };
            index += 2;
            continue;
        }
        return allocPrintResult(allocator, .usage, "", "rubix-cli: unknown scramble option \"{s}\"\n", .{args[index]});
    }

    var prng = std.Random.DefaultPrng.init(seed);
    const scramble = scramble_mod.generate(prng.random());
    var buffer: [128]u8 = undefined;
    const formatted = notation.formatAlgorithmInto(&buffer, &scramble.moves) catch unreachable;
    return allocPrintResult(allocator, .success, "{s}\n", "", .{formatted});
}

fn writeFaceletString(cube: cube_mod.Cube, out: []u8) void {
    std.debug.assert(out.len == 54);
    const faces = [_]facelet.Face{ .up, .right, .front, .down, .left, .back };
    var pos: usize = 0;
    for (faces) |face| {
        for (0..9) |index| {
            out[pos] = colorChar(facelet.color(cube, face, index));
            pos += 1;
        }
    }
}

fn colorChar(color: facelet.Color) u8 {
    return switch (color) {
        .white => 'W',
        .yellow => 'Y',
        .green => 'G',
        .blue => 'B',
        .orange => 'O',
        .red => 'R',
    };
}

fn parseErrorResult(allocator: std.mem.Allocator, input: []const u8, err: notation.ParseError) !Result {
    return allocPrintResult(allocator, .parse, "", "rubix-cli: invalid algorithm \"{s}\": {s}\n", .{ input, @errorName(err) });
}

fn validationErrorResult(allocator: std.mem.Allocator, err: cube_mod.ValidationError) !Result {
    return allocPrintResult(allocator, .validation, "", "rubix-cli: cube validation failed: {s}\n", .{@errorName(err)});
}

fn textResult(allocator: std.mem.Allocator, exit_code: ExitCode, stdout: []const u8, stderr: []const u8) !Result {
    return .{
        .exit_code = exit_code,
        .stdout = try allocator.dupe(u8, stdout),
        .stderr = try allocator.dupe(u8, stderr),
    };
}

fn allocPrintResult(
    allocator: std.mem.Allocator,
    exit_code: ExitCode,
    comptime stdout_fmt: []const u8,
    comptime stderr_fmt: []const u8,
    args: anytype,
) !Result {
    const stdout = if (stdout_fmt.len == 0)
        try allocator.dupe(u8, "")
    else
        try std.fmt.allocPrint(allocator, stdout_fmt, args);
    errdefer allocator.free(stdout);

    const stderr = if (stderr_fmt.len == 0)
        try allocator.dupe(u8, "")
    else
        try std.fmt.allocPrint(allocator, stderr_fmt, args);

    return .{
        .exit_code = exit_code,
        .stdout = stdout,
        .stderr = stderr,
    };
}
