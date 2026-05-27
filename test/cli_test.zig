const std = @import("std");
const rubix = @import("rubix");

const cli = rubix.cli_core;
const move_mod = rubix.move;

fn expectRun(args: []const []const u8, expected_code: cli.ExitCode, expected_stdout: []const u8, expected_stderr: []const u8) !void {
    const result = try cli.runAlloc(std.testing.allocator, args, 12345);
    defer result.deinit(std.testing.allocator);

    try std.testing.expectEqual(expected_code, result.exit_code);
    try std.testing.expectEqualStrings(expected_stdout, result.stdout);
    try std.testing.expectEqualStrings(expected_stderr, result.stderr);
}

test "apply prints facelet string" {
    try expectRun(&.{ "apply", "R U R' U'" }, .success, "WWOWWGWWGRRWBRRWRRGGYGGWGGGYYRYYYYYYBOOOOOOOOBRRBBBBBB\n", "");
}

test "check reports solved and unsolved without erroring on unsolved" {
    try expectRun(&.{ "check", "R U R' U'" }, .success, "unsolved\n", "");
    try expectRun(&.{ "check", "R U R' U' U R U' R'" }, .success, "solved\n", "");
}

test "invert normalizes inverse notation" {
    try expectRun(&.{ "invert", "  R U   R' U' " }, .success, "U R U' R'\n", "");
}

test "scramble seeded output is deterministic and avoids adjacent axes" {
    const first = try cli.runAlloc(std.testing.allocator, &.{ "scramble", "--seed", "123" }, 0);
    defer first.deinit(std.testing.allocator);
    const second = try cli.runAlloc(std.testing.allocator, &.{ "scramble", "--seed", "123" }, 999);
    defer second.deinit(std.testing.allocator);

    try std.testing.expectEqual(cli.ExitCode.success, first.exit_code);
    try std.testing.expectEqualStrings(first.stdout, second.stdout);
    try std.testing.expectEqualStrings("", first.stderr);

    const moves = try rubix.notation.parseAlgorithm(std.testing.allocator, std.mem.trimEnd(u8, first.stdout, "\n"));
    defer std.testing.allocator.free(moves);
    for (moves[1..], 1..) |move, index| {
        try std.testing.expect(move_mod.moveAxis(move) != move_mod.moveAxis(moves[index - 1]));
    }
}

test "usage errors and parse errors use stable exit codes" {
    try expectRun(&.{}, .usage, "", cli.usage_text);
    try expectRun(&.{"bogus"}, .usage, "", "rubix-cli: unknown command \"bogus\"\n");
    try expectRun(&.{ "apply", "M" }, .parse, "", "rubix-cli: invalid algorithm \"M\": InvalidFace\n");
    try expectRun(&.{ "scramble", "--seed", "nope" }, .usage, "", "rubix-cli: invalid seed \"nope\"\n");
}
