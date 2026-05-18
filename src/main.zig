const std = @import("std");
const builtin = @import("builtin");
const cube_mod = @import("cube.zig");
const render = @import("render.zig");

const Cube = cube_mod.Cube;
const Move = cube_mod.Move;

const TerminalSize = struct {
    cols: usize,
    rows: usize,
};

const Action = union(enum) {
    move: Move,
    scramble,
    quit,
    none,
};

pub fn main(init: std.process.Init) !void {
    var cube = Cube.solved();
    var seed: u64 = undefined;
    init.io.random(std.mem.asBytes(&seed));
    var prng = std.Random.DefaultPrng.init(seed);
    var status: []const u8 = "Solved";

    const original_termios = enableRawMode() catch |err| switch (err) {
        error.NotATerminal => null,
        else => return err,
    };

    if (original_termios) |original| {
        defer restoreTerminal(original);
        enterScreen();
        defer leaveScreen();
    } else {
        render.printCube(cube);
        std.debug.print("\nRun in a terminal to use interactive controls.\n", .{});
        return;
    }

    while (true) {
        draw(cube, status);

        switch (keyAction(try readKey())) {
            .move => |move| {
                cube.applyMove(move);
                status = cube_mod.moveName(move);
            },
            .scramble => {
                _ = cube.scrambleWithRandom(prng.random());
                status = "Scrambled";
            },
            .quit => break,
            .none => {},
        }

        if (cube.isSolved()) {
            status = "Solved";
        }
    }
}

fn enableRawMode() !?std.posix.termios {
    const stdin = std.posix.STDIN_FILENO;
    const original = try std.posix.tcgetattr(stdin);
    var raw = original;

    raw.iflag.ICRNL = false;
    raw.iflag.IXON = false;
    raw.lflag.ECHO = false;
    raw.lflag.ICANON = false;
    raw.lflag.ISIG = false;
    raw.cc[@intFromEnum(std.posix.system.V.MIN)] = 1;
    raw.cc[@intFromEnum(std.posix.system.V.TIME)] = 0;

    try std.posix.tcsetattr(stdin, .FLUSH, raw);
    return original;
}

fn restoreTerminal(original: std.posix.termios) void {
    std.posix.tcsetattr(std.posix.STDIN_FILENO, .FLUSH, original) catch {};
}

fn enterScreen() void {
    std.debug.print("\x1b[?1049h\x1b[?25l", .{});
}

fn leaveScreen() void {
    std.debug.print("\x1b[?25h\x1b[?1049l", .{});
}

fn readKey() !u8 {
    var byte: [1]u8 = undefined;
    while (true) {
        const count = try std.posix.read(std.posix.STDIN_FILENO, &byte);
        if (count == 1) return byte[0];
        if (count == 0) return 'q';
    }
}

fn keyAction(key: u8) Action {
    return switch (key) {
        'u' => .{ .move = .U },
        'U' => .{ .move = .UPrime },
        'd' => .{ .move = .D },
        'D' => .{ .move = .DPrime },
        'r' => .{ .move = .R },
        'R' => .{ .move = .RPrime },
        'l' => .{ .move = .L },
        'L' => .{ .move = .LPrime },
        'f' => .{ .move = .F },
        'F' => .{ .move = .FPrime },
        'b' => .{ .move = .B },
        'B' => .{ .move = .BPrime },
        's' => .scramble,
        'q', 0x03 => .quit,
        else => .none,
    };
}

fn draw(cube: Cube, status: []const u8) void {
    const size = terminalSize();
    const left_pad = if (size.cols > render.cube_width)
        (size.cols - render.cube_width) / 2
    else
        0;
    const top_pad = if (size.rows > render.cube_height + 5)
        (size.rows - render.cube_height - 5) / 2
    else
        0;

    std.debug.print("\x1b[2J\x1b[H", .{});

    for (0..top_pad) |_| {
        std.debug.print("\n", .{});
    }

    for (0..render.cube_height) |line| {
        printSpaces(left_pad);

        var buffer: [256]u8 = undefined;
        var writer = std.Io.Writer.fixed(&buffer);
        render.writeCubeLine(&writer, cube, line) catch unreachable;
        std.debug.print("{s}\n", .{writer.buffered()});
    }

    std.debug.print("\n", .{});
    printCentered(size.cols, "u/U d/D r/R l/L f/F b/B: turn   s: scramble   q or Ctrl-C: quit");
    printCentered(size.cols, status);
}

fn printCentered(cols: usize, text: []const u8) void {
    const left_pad = if (cols > text.len) (cols - text.len) / 2 else 0;
    printSpaces(left_pad);
    std.debug.print("{s}\n", .{text});
}

fn printSpaces(count: usize) void {
    for (0..count) |_| {
        std.debug.print(" ", .{});
    }
}

fn terminalSize() TerminalSize {
    var size = getTerminalSize(std.posix.STDOUT_FILENO);
    if (size.cols == 0 or size.rows == 0) {
        size = .{ .cols = 80, .rows = 24 };
    }
    return size;
}

fn getTerminalSize(fd: std.posix.fd_t) TerminalSize {
    var winsize: std.posix.winsize = .{
        .row = 0,
        .col = 0,
        .xpixel = 0,
        .ypixel = 0,
    };

    switch (builtin.os.tag) {
        .linux => {
            const rc = std.os.linux.ioctl(fd, std.posix.T.IOCGWINSZ, @intFromPtr(&winsize));
            if (rc == 0) return fromWinsize(winsize);
        },
        .windows, .wasi => {},
        else => {
            const rc = std.posix.system.ioctl(fd, std.posix.T.IOCGWINSZ, &winsize);
            if (rc == 0) return fromWinsize(winsize);
        },
    }

    return .{ .cols = 0, .rows = 0 };
}

fn fromWinsize(winsize: std.posix.winsize) TerminalSize {
    return .{
        .cols = winsize.col,
        .rows = winsize.row,
    };
}
