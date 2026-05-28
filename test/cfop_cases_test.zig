const std = @import("std");
const rubix = @import("rubix");

const cfop = rubix.cfop;
const cases = rubix.cfop_cases;
const cube_mod = rubix.cube;

test "starter two-look cases validate algorithm metadata" {
    try std.testing.expect(cases.two_look_cases.len >= 4);

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

test "starter two-look setup and solution fixtures resolve" {
    for (cases.two_look_cases) |case| {
        var cube = cube_mod.Cube.solved();
        case.setup.apply(&cube);
        try cube.validate();
        try std.testing.expect(!cube.isSolved());

        case.solution.apply(&cube);
        try cube.validate();
        try std.testing.expect(cube.isSolved());
    }
}
