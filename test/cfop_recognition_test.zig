const std = @import("std");
const rubix = @import("rubix");

const cases = rubix.cfop_cases;
const recognition = rubix.cfop_recognition;
const cube_mod = rubix.cube;

test "recognizeTwoLook matches starter setup fixtures" {
    for (cases.two_look_cases) |case| {
        var cube = cube_mod.Cube.solved();
        case.setup.apply(&cube);

        const result = recognition.recognizeTwoLook(cube) orelse return error.ExpectedRecognition;
        try std.testing.expectEqualStrings(case.id, result.case.id);
    }
}

test "recognizeTwoLook returns null for solved and unsupported states" {
    try std.testing.expectEqual(@as(?recognition.Result, null), recognition.recognizeTwoLook(cube_mod.Cube.solved()));

    var cube = cube_mod.Cube.solved();
    cube.applyMove(.R);
    try std.testing.expectEqual(@as(?recognition.Result, null), recognition.recognizeTwoLook(cube));
}
