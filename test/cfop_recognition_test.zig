const std = @import("std");
const rubix = @import("rubix");

const cases = rubix.cfop_cases;
const recognition = rubix.cfop_recognition;
const cube_mod = rubix.cube;

test "recognizeTwoLook matches setup fixtures and AUF variants" {
    for (cases.two_look_cases) |case| {
        inline for (.{ recognition.Auf.none, .u, .u2, .u_prime }) |auf| {
            var cube = cube_mod.Cube.solved();
            case.setup.apply(&cube);
            applyAuf(&cube, auf);

            const result = recognition.recognizeTwoLook(cube);
            switch (result) {
                .known => |known| {
                    try std.testing.expectEqualStrings(case.id, known.case.id);
                    try std.testing.expectEqual(auf, known.auf);
                },
                else => return error.ExpectedKnownCase,
            }
        }
    }
}

test "recognizeTwoLook distinguishes solved AUF states" {
    inline for (.{ recognition.Auf.none, .u, .u2, .u_prime }) |auf| {
        var cube = cube_mod.Cube.solved();
        applyAuf(&cube, auf);

        const result = recognition.recognizeTwoLook(cube);
        switch (result) {
            .solved => |solved_auf| {
                var aligned = cube;
                applyAuf(&aligned, solved_auf);
                try std.testing.expect(aligned.isSolved());
            },
            else => return error.ExpectedSolved,
        }
    }
}

test "recognizeTwoLook returns unsupported for non-CFOP last-layer states" {
    var cube = cube_mod.Cube.solved();
    cube.applyMove(.R);

    try std.testing.expectEqual(recognition.Result.unsupported, recognition.recognizeTwoLook(cube));
}

fn applyAuf(cube: *cube_mod.Cube, auf: recognition.Auf) void {
    switch (auf) {
        .none => {},
        .u => cube.applyMove(.U),
        .u2 => cube.applyMove(.U2),
        .u_prime => cube.applyMove(.UPrime),
    }
}
