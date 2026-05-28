const std = @import("std");
const rubix = @import("rubix");

const cfop = rubix.cfop;
const cases = rubix.cfop_cases;
const cube_mod = rubix.cube;
const move_mod = rubix.move;
const notation = rubix.notation;

fn expectF2LSolved(cube: cube_mod.Cube) !void {
    inline for (.{ cube_mod.CornerPosition.dfr, .drb, .dbl, .dlf }) |position| {
        try std.testing.expect(cube.isCornerSolved(position));
    }
    inline for (.{
        cube_mod.EdgePosition.fr,
        .br,
        .bl,
        .fl,
        .df,
        .dr,
        .db,
        .dl,
    }) |position| {
        try std.testing.expect(cube.isEdgeSolved(position));
    }
}

test "two-look catalog includes the full starter OLL and PLL sets" {
    try std.testing.expectEqual(@as(usize, 16), cases.two_look_cases.len);

    var oll_count: usize = 0;
    var pll_count: usize = 0;
    for (cases.two_look_cases, 0..) |case, index| {
        switch (case.stage) {
            .oll => oll_count += 1,
            .pll => pll_count += 1,
            else => return error.UnexpectedStage,
        }

        for (cases.two_look_cases[index + 1 ..]) |other| {
            try std.testing.expect(!std.mem.eql(u8, case.id, other.id));
        }
    }

    try std.testing.expectEqual(@as(usize, 10), oll_count);
    try std.testing.expectEqual(@as(usize, 6), pll_count);
}

test "two-look cases validate algorithm metadata" {
    for (cases.two_look_cases) |case| {
        try std.testing.expect(case.stage == .oll or case.stage == .pll);
        try std.testing.expectEqual(cfop.Look.two_look, case.look);
        try std.testing.expect(case.solution.case.eql(case.setup.case));
        try std.testing.expectEqual(case.stage, case.solution.case.stage);
        try std.testing.expectEqual(case.look, case.solution.case.look);

        try case.setup.validate(std.testing.allocator);
        try case.solution.validate(std.testing.allocator);
    }
}

test "two-look setups are inverse fixtures and resolve" {
    for (cases.two_look_cases) |case| {
        var expected_setup: [32]move_mod.Move = undefined;
        const inverse = try notation.inverseAlgorithmInto(case.solution.moves, &expected_setup);
        try std.testing.expectEqualSlices(move_mod.Move, inverse, case.setup.moves);

        var cube = cube_mod.Cube.solved();
        case.setup.apply(&cube);
        try cube.validate();
        try std.testing.expect(!cube.isSolved());

        case.solution.apply(&cube);
        try cube.validate();
        try std.testing.expect(cube.isSolved());
    }
}

test "two-look setup fixtures preserve stage semantics" {
    for (cases.two_look_cases) |case| {
        var cube = cube_mod.Cube.solved();
        case.setup.apply(&cube);
        try cube.validate();
        try expectF2LSolved(cube);

        switch (case.stage) {
            .oll => {
                try std.testing.expect(!cube.isUpLayerOriented());
            },
            .pll => {
                try std.testing.expect(cube.isUpLayerOriented());
                try std.testing.expect(!cube.isUpLayerPermutationSolved());
            },
            else => unreachable,
        }
    }
}
