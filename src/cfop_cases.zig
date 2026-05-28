const algorithm = @import("algorithm.zig");
const cfop = @import("cfop.zig");
const move_mod = @import("move.zig");

const Move = move_mod.Move;

pub const CaseDefinition = struct {
    id: []const u8,
    name: []const u8,
    stage: cfop.Stage,
    look: cfop.Look,
    setup: algorithm.Definition,
    solution: algorithm.Definition,
};

const jperm_2look_oll = algorithm.Source{
    .name = "J Perm 2-look OLL reference",
    .url = "https://jperm.net/algs/2lookoll",
};

const jperm_2look_pll = algorithm.Source{
    .name = "J Perm 2-look PLL reference",
    .url = "https://jperm.net/algs/2lookpll",
};

const oll_line_case = cfop.CaseRef{ .stage = .oll, .look = .two_look, .id = "2look-oll-line" };
const oll_sune_case = cfop.CaseRef{ .stage = .oll, .look = .two_look, .id = "2look-oll-sune" };
const pll_ua_case = cfop.CaseRef{ .stage = .pll, .look = .two_look, .id = "2look-pll-ua" };
const pll_ub_case = cfop.CaseRef{ .stage = .pll, .look = .two_look, .id = "2look-pll-ub" };

const oll_line_setup = [_]Move{ .F, .U, .R, .UPrime, .RPrime, .FPrime };
const oll_line_solution = [_]Move{ .F, .R, .U, .RPrime, .UPrime, .FPrime };

const oll_sune_setup = [_]Move{ .R, .U2, .RPrime, .UPrime, .R, .UPrime, .RPrime };
const oll_sune_solution = [_]Move{ .R, .U, .RPrime, .U, .R, .U2, .RPrime };

const pll_ua_setup = [_]Move{ .R2, .U, .R, .U, .RPrime, .UPrime, .RPrime, .UPrime, .RPrime, .U, .RPrime };
const pll_ua_solution = [_]Move{ .R, .UPrime, .R, .U, .R, .U, .R, .UPrime, .RPrime, .UPrime, .R2 };

const pll_ub_setup = [_]Move{ .R, .UPrime, .R, .U, .R, .U, .R, .UPrime, .RPrime, .UPrime, .R2 };
const pll_ub_solution = [_]Move{ .R2, .U, .R, .U, .RPrime, .UPrime, .RPrime, .UPrime, .RPrime, .U, .RPrime };

pub const two_look_cases = [_]CaseDefinition{
    .{
        .id = "2look-oll-line",
        .name = "2-look OLL line",
        .stage = .oll,
        .look = .two_look,
        .setup = .{
            .id = "setup-2look-oll-line",
            .case = oll_line_case,
            .name = "Line setup",
            .display = "F U R U' R' F'",
            .source = jperm_2look_oll,
            .moves = &oll_line_setup,
        },
        .solution = .{
            .id = "alg-2look-oll-line",
            .case = oll_line_case,
            .name = "Line",
            .display = "F R U R' U' F'",
            .source = jperm_2look_oll,
            .moves = &oll_line_solution,
        },
    },
    .{
        .id = "2look-oll-sune",
        .name = "2-look OLL Sune",
        .stage = .oll,
        .look = .two_look,
        .setup = .{
            .id = "setup-2look-oll-sune",
            .case = oll_sune_case,
            .name = "Sune setup",
            .display = "R U2 R' U' R U' R'",
            .source = jperm_2look_oll,
            .moves = &oll_sune_setup,
        },
        .solution = .{
            .id = "alg-2look-oll-sune",
            .case = oll_sune_case,
            .name = "Sune",
            .display = "R U R' U R U2 R'",
            .source = jperm_2look_oll,
            .moves = &oll_sune_solution,
        },
    },
    .{
        .id = "2look-pll-ua",
        .name = "2-look PLL Ua",
        .stage = .pll,
        .look = .two_look,
        .setup = .{
            .id = "setup-2look-pll-ua",
            .case = pll_ua_case,
            .name = "Ua setup",
            .display = "R2 U R U R' U' R' U' R' U R'",
            .source = jperm_2look_pll,
            .moves = &pll_ua_setup,
        },
        .solution = .{
            .id = "alg-2look-pll-ua",
            .case = pll_ua_case,
            .name = "Ua",
            .display = "R U' R U R U R U' R' U' R2",
            .source = jperm_2look_pll,
            .moves = &pll_ua_solution,
        },
    },
    .{
        .id = "2look-pll-ub",
        .name = "2-look PLL Ub",
        .stage = .pll,
        .look = .two_look,
        .setup = .{
            .id = "setup-2look-pll-ub",
            .case = pll_ub_case,
            .name = "Ub setup",
            .display = "R U' R U R U R U' R' U' R2",
            .source = jperm_2look_pll,
            .moves = &pll_ub_setup,
        },
        .solution = .{
            .id = "alg-2look-pll-ub",
            .case = pll_ub_case,
            .name = "Ub",
            .display = "R2 U R U R' U' R' U' R' U R'",
            .source = jperm_2look_pll,
            .moves = &pll_ub_solution,
        },
    },
};
