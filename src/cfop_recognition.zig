const cfop_cases = @import("cfop_cases.zig");
const cube_mod = @import("cube.zig");

pub const Result = struct {
    case: *const cfop_cases.CaseDefinition,
};

// Temporary fixture matcher for the starter catalog. This intentionally
// recognizes exact setup states only; real trainer recognition still needs
// AUF/orientation-aware case signatures.
pub fn recognizeTwoLook(cube: cube_mod.Cube) ?Result {
    for (&cfop_cases.two_look_cases) |*case| {
        var candidate = cube_mod.Cube.solved();
        case.setup.apply(&candidate);
        if (cube.eql(candidate)) {
            return .{ .case = case };
        }
    }
    return null;
}
