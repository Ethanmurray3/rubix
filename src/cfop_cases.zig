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

fn inverse(comptime moves: []const Move) [moves.len]Move {
    var out: [moves.len]Move = undefined;
    for (moves, 0..) |move, index| {
        out[moves.len - 1 - index] = move_mod.inverseMove(move);
    }
    return out;
}

const oll_dot_case = cfop.CaseRef{ .stage = .oll, .look = .two_look, .id = "2look-oll-dot" };
const oll_l_case = cfop.CaseRef{ .stage = .oll, .look = .two_look, .id = "2look-oll-l" };
const oll_line_case = cfop.CaseRef{ .stage = .oll, .look = .two_look, .id = "2look-oll-line" };
const oll_antisune_case = cfop.CaseRef{ .stage = .oll, .look = .two_look, .id = "2look-oll-antisune" };
const oll_sune_case = cfop.CaseRef{ .stage = .oll, .look = .two_look, .id = "2look-oll-sune" };
const oll_h_case = cfop.CaseRef{ .stage = .oll, .look = .two_look, .id = "2look-oll-h" };
const oll_pi_case = cfop.CaseRef{ .stage = .oll, .look = .two_look, .id = "2look-oll-pi" };
const oll_t_case = cfop.CaseRef{ .stage = .oll, .look = .two_look, .id = "2look-oll-t" };
const oll_u_case = cfop.CaseRef{ .stage = .oll, .look = .two_look, .id = "2look-oll-u" };
const oll_headlights_case = cfop.CaseRef{ .stage = .oll, .look = .two_look, .id = "2look-oll-headlights" };

const pll_t_case = cfop.CaseRef{ .stage = .pll, .look = .two_look, .id = "2look-pll-t" };
const pll_y_case = cfop.CaseRef{ .stage = .pll, .look = .two_look, .id = "2look-pll-y" };
const pll_ua_case = cfop.CaseRef{ .stage = .pll, .look = .two_look, .id = "2look-pll-ua" };
const pll_ub_case = cfop.CaseRef{ .stage = .pll, .look = .two_look, .id = "2look-pll-ub" };
const pll_h_case = cfop.CaseRef{ .stage = .pll, .look = .two_look, .id = "2look-pll-h" };
const pll_z_case = cfop.CaseRef{ .stage = .pll, .look = .two_look, .id = "2look-pll-z" };

const oll_dot_solution = [_]Move{ .F, .R, .U, .RPrime, .UPrime, .FPrime, .U2, .F, .U, .R, .UPrime, .RPrime, .FPrime };
const oll_dot_setup = inverse(&oll_dot_solution);

const oll_l_solution = [_]Move{ .F, .U, .R, .UPrime, .RPrime, .FPrime };
const oll_l_setup = inverse(&oll_l_solution);

const oll_line_solution = [_]Move{ .F, .R, .U, .RPrime, .UPrime, .FPrime };
const oll_line_setup = inverse(&oll_line_solution);

const oll_antisune_solution = [_]Move{ .R, .U2, .RPrime, .UPrime, .R, .UPrime, .RPrime };
const oll_antisune_setup = inverse(&oll_antisune_solution);

const oll_sune_solution = [_]Move{ .R, .U, .RPrime, .U, .R, .U2, .RPrime };
const oll_sune_setup = inverse(&oll_sune_solution);

const oll_h_solution = [_]Move{ .R, .U, .RPrime, .U, .R, .UPrime, .RPrime, .U, .R, .U2, .RPrime };
const oll_h_setup = inverse(&oll_h_solution);

const oll_pi_solution = [_]Move{ .R, .U2, .R2, .UPrime, .R2, .UPrime, .R2, .U2, .R };
const oll_pi_setup = inverse(&oll_pi_solution);

const oll_t_solution = [_]Move{ .R, .U, .RPrime, .UPrime, .RPrime, .F, .R, .FPrime };
const oll_t_setup = inverse(&oll_t_solution);

const oll_u_solution = [_]Move{ .R2, .D, .RPrime, .U2, .R, .DPrime, .RPrime, .U2, .RPrime };
const oll_u_setup = inverse(&oll_u_solution);

const oll_headlights_solution = [_]Move{ .F, .RPrime, .FPrime, .R, .U, .R, .UPrime, .RPrime };
const oll_headlights_setup = inverse(&oll_headlights_solution);

const pll_t_solution = [_]Move{ .R, .U, .RPrime, .UPrime, .RPrime, .F, .R2, .UPrime, .RPrime, .UPrime, .R, .U, .RPrime, .FPrime };
const pll_t_setup = inverse(&pll_t_solution);

const pll_y_solution = [_]Move{ .F, .R, .UPrime, .RPrime, .UPrime, .R, .U, .RPrime, .FPrime, .R, .U, .RPrime, .UPrime, .RPrime, .F, .R, .FPrime };
const pll_y_setup = inverse(&pll_y_solution);

const pll_ua_solution = [_]Move{ .R, .UPrime, .R, .U, .R, .U, .R, .UPrime, .RPrime, .UPrime, .R2 };
const pll_ua_setup = inverse(&pll_ua_solution);

const pll_ub_solution = [_]Move{ .R2, .U, .R, .U, .RPrime, .UPrime, .RPrime, .UPrime, .RPrime, .U, .RPrime };
const pll_ub_setup = inverse(&pll_ub_solution);

const pll_h_solution = [_]Move{ .R2, .U2, .R, .U2, .R2, .U2, .R2, .U2, .R, .U2, .R2 };
const pll_h_setup = inverse(&pll_h_solution);

const pll_z_solution = [_]Move{ .R, .U, .RPrime, .U, .RPrime, .UPrime, .RPrime, .U, .R, .UPrime, .RPrime, .UPrime, .R2, .U, .R };
const pll_z_setup = inverse(&pll_z_solution);

pub const two_look_cases = [_]CaseDefinition{
    caseDefinition(oll_dot_case, "2-look OLL dot", jperm_2look_oll, "Dot", "F R U R' U' F' U2 F U R U' R' F'", "F R U R' U' F' U2 F U R U' R' F'", &oll_dot_setup, &oll_dot_solution),
    caseDefinition(oll_l_case, "2-look OLL L", jperm_2look_oll, "L shape", "F R U R' U' F'", "F U R U' R' F'", &oll_l_setup, &oll_l_solution),
    caseDefinition(oll_line_case, "2-look OLL line", jperm_2look_oll, "Line", "F U R U' R' F'", "F R U R' U' F'", &oll_line_setup, &oll_line_solution),
    caseDefinition(oll_antisune_case, "2-look OLL Anti-Sune", jperm_2look_oll, "Anti-Sune", "R U R' U R U2 R'", "R U2 R' U' R U' R'", &oll_antisune_setup, &oll_antisune_solution),
    caseDefinition(oll_sune_case, "2-look OLL Sune", jperm_2look_oll, "Sune", "R U2 R' U' R U' R'", "R U R' U R U2 R'", &oll_sune_setup, &oll_sune_solution),
    caseDefinition(oll_h_case, "2-look OLL H", jperm_2look_oll, "H", "R U2 R' U' R U R' U' R U' R'", "R U R' U R U' R' U R U2 R'", &oll_h_setup, &oll_h_solution),
    caseDefinition(oll_pi_case, "2-look OLL Pi", jperm_2look_oll, "Pi", "R' U2 R2 U R2 U R2 U2 R'", "R U2 R2 U' R2 U' R2 U2 R", &oll_pi_setup, &oll_pi_solution),
    caseDefinition(oll_t_case, "2-look OLL T", jperm_2look_oll, "T", "F R' F' R U R U' R'", "R U R' U' R' F R F'", &oll_t_setup, &oll_t_solution),
    caseDefinition(oll_u_case, "2-look OLL U", jperm_2look_oll, "U", "R U2 R D R' U2 R D' R2", "R2 D R' U2 R D' R' U2 R'", &oll_u_setup, &oll_u_solution),
    caseDefinition(oll_headlights_case, "2-look OLL headlights", jperm_2look_oll, "Headlights", "R U R' U' R' F R F'", "F R' F' R U R U' R'", &oll_headlights_setup, &oll_headlights_solution),
    caseDefinition(pll_t_case, "2-look PLL T", jperm_2look_pll, "T", "F R U' R' U R U R2 F' R U R U' R'", "R U R' U' R' F R2 U' R' U' R U R' F'", &pll_t_setup, &pll_t_solution),
    caseDefinition(pll_y_case, "2-look PLL Y", jperm_2look_pll, "Y", "F R' F' R U R U' R' F R U' R' U R U R' F'", "F R U' R' U' R U R' F' R U R' U' R' F R F'", &pll_y_setup, &pll_y_solution),
    caseDefinition(pll_ua_case, "2-look PLL Ua", jperm_2look_pll, "Ua", "R2 U R U R' U' R' U' R' U R'", "R U' R U R U R U' R' U' R2", &pll_ua_setup, &pll_ua_solution),
    caseDefinition(pll_ub_case, "2-look PLL Ub", jperm_2look_pll, "Ub", "R U' R U R U R U' R' U' R2", "R2 U R U R' U' R' U' R' U R'", &pll_ub_setup, &pll_ub_solution),
    caseDefinition(pll_h_case, "2-look PLL H", jperm_2look_pll, "H", "R2 U2 R' U2 R2 U2 R2 U2 R' U2 R2", "R2 U2 R U2 R2 U2 R2 U2 R U2 R2", &pll_h_setup, &pll_h_solution),
    caseDefinition(pll_z_case, "2-look PLL Z", jperm_2look_pll, "Z", "R' U' R2 U R U R' U' R U R U' R U' R'", "R U R' U R' U' R' U R U' R' U' R2 U R", &pll_z_setup, &pll_z_solution),
};

fn caseDefinition(
    case_ref: cfop.CaseRef,
    case_name: []const u8,
    source: algorithm.Source,
    algorithm_name: []const u8,
    setup_display: []const u8,
    solution_display: []const u8,
    setup_moves: []const Move,
    solution_moves: []const Move,
) CaseDefinition {
    return .{
        .id = case_ref.id,
        .name = case_name,
        .stage = case_ref.stage,
        .look = case_ref.look,
        .setup = .{
            .id = setupId(case_ref.id),
            .case = case_ref,
            .name = setupName(algorithm_name),
            .display = setup_display,
            .source = source,
            .moves = setup_moves,
        },
        .solution = .{
            .id = algorithmId(case_ref.id),
            .case = case_ref,
            .name = algorithm_name,
            .display = solution_display,
            .source = source,
            .moves = solution_moves,
        },
    };
}

fn setupId(comptime case_id: []const u8) []const u8 {
    return "setup-" ++ case_id;
}

fn algorithmId(comptime case_id: []const u8) []const u8 {
    return "alg-" ++ case_id;
}

fn setupName(comptime algorithm_name: []const u8) []const u8 {
    return algorithm_name ++ " setup";
}
