const std = @import("std");
const rubix = @import("rubix");

const cases = rubix.cfop_cases;
const trainer = rubix.trainer;

test "trainer session initializes a prompt from setup moves" {
    var expected = rubix.cube.Cube.solved();
    cases.two_look_cases[0].setup.apply(&expected);

    const session = trainer.Session.init(.reference, &cases.two_look_cases[0]);
    try std.testing.expect(session.prompt_cube.eql(expected));
    try std.testing.expectEqual(trainer.AttemptState.idle, session.attempt_state);
    try std.testing.expect(!session.hint_visible);
}

test "trainer supports hint and playback commands" {
    var session = trainer.Session.init(.reference, &cases.two_look_cases[0]);

    session.showHint();
    try std.testing.expect(session.hint_visible);

    const setup = session.playSetup();
    try std.testing.expectEqual(trainer.PlaybackKind.setup, setup.kind);
    try std.testing.expectEqualSlices(rubix.move.Move, cases.two_look_cases[0].setup.moves, setup.moves);

    const solution = session.playSolution();
    try std.testing.expectEqual(trainer.PlaybackKind.solution, solution.kind);
    try std.testing.expectEqualSlices(rubix.move.Move, cases.two_look_cases[0].solution.moves, solution.moves);
}

test "recognition quiz checks selected case id" {
    var session = trainer.Session.init(.recognition_quiz, &cases.two_look_cases[1]);

    try session.startAttempt();
    session.tick(250);
    try std.testing.expectEqual(@as(u32, 250), session.elapsed_ms);

    try std.testing.expectEqual(trainer.AnswerResult.correct, try session.submitCaseId(cases.two_look_cases[1].id));
    try std.testing.expectEqual(trainer.AttemptState.succeeded, session.attempt_state);
}

test "drill checks whether submitted moves solve the prompt" {
    var session = trainer.Session.init(.drill, &cases.two_look_cases[2]);

    try session.startAttempt();
    try std.testing.expectEqual(trainer.AnswerResult.incorrect, try session.submitMoves(&.{.U}));
    try std.testing.expectEqual(trainer.AttemptState.failed, session.attempt_state);

    try session.startAttempt();
    try std.testing.expectEqual(trainer.AnswerResult.correct, try session.submitMoves(cases.two_look_cases[2].solution.moves));
    try std.testing.expectEqual(trainer.AttemptState.succeeded, session.attempt_state);
}

test "trainer mode and attempt lifecycle errors are explicit" {
    var session = trainer.Session.init(.reference, &cases.two_look_cases[0]);
    try std.testing.expectError(error.WrongMode, session.startAttempt());

    session.setMode(.drill);
    try std.testing.expectError(error.AttemptNotRunning, session.submitMoves(cases.two_look_cases[0].solution.moves));

    try session.startAttempt();
    try std.testing.expectError(error.AttemptAlreadyRunning, session.startAttempt());
}
