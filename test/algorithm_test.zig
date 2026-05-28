const std = @import("std");
const rubix = @import("rubix");

const algorithm = rubix.algorithm;
const cfop = rubix.cfop;
const cube_mod = rubix.cube;
const move_mod = rubix.move;

const source = algorithm.Source{
    .name = "J Perm reference",
    .url = "https://jperm.net/algs/2lookoll",
};

test "cfop names are product-facing labels" {
    try std.testing.expectEqualStrings("Cross", cfop.stageName(.cross));
    try std.testing.expectEqualStrings("F2L", cfop.stageName(.f2l));
    try std.testing.expectEqualStrings("OLL", cfop.stageName(.oll));
    try std.testing.expectEqualStrings("PLL", cfop.stageName(.pll));
    try std.testing.expectEqualStrings("1-look", cfop.lookName(.one_look));
    try std.testing.expectEqualStrings("2-look", cfop.lookName(.two_look));
}

test "algorithm definition validates display against executable moves" {
    const definition = algorithm.Definition{
        .id = "oll-sune",
        .case = .{
            .stage = .oll,
            .look = .two_look,
            .id = "oll-sune",
        },
        .name = "Sune",
        .display = "R U R' U R U2 R'",
        .source = source,
        .moves = &.{ .R, .U, .RPrime, .U, .R, .U2, .RPrime },
    };

    try definition.validate(std.testing.allocator);

    var cube = cube_mod.Cube.solved();
    definition.apply(&cube);
    try cube.validate();
    try std.testing.expect(!cube.isSolved());
}

test "algorithm definition catches metadata and notation mistakes" {
    const valid_case = cfop.CaseRef{
        .stage = .oll,
        .look = .two_look,
        .id = "oll-sune",
    };

    try std.testing.expectError(
        error.EmptyId,
        (algorithm.Definition{
            .id = "",
            .case = valid_case,
            .name = "Sune",
            .display = "R",
            .source = source,
            .moves = &.{.R},
        }).validate(std.testing.allocator),
    );

    try std.testing.expectError(
        error.MovesDoNotMatchDisplay,
        (algorithm.Definition{
            .id = "bad-sune",
            .case = valid_case,
            .name = "Bad Sune",
            .display = "R",
            .source = source,
            .moves = &.{.U},
        }).validate(std.testing.allocator),
    );

    try std.testing.expectError(
        error.EmptyName,
        (algorithm.Definition{
            .id = "nameless",
            .case = valid_case,
            .name = "",
            .display = "R",
            .source = source,
            .moves = &.{.R},
        }).validate(std.testing.allocator),
    );

    try std.testing.expectError(
        error.UnsupportedExecutableToken,
        (algorithm.Definition{
            .id = "unsupported",
            .case = valid_case,
            .name = "Unsupported",
            .display = "M",
            .source = source,
            .moves = &.{},
        }).validate(std.testing.allocator),
    );

    _ = move_mod.Move.R;
}
