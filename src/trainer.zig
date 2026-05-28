const std = @import("std");
const cfop_cases = @import("cfop_cases.zig");
const cube_mod = @import("cube.zig");
const move_mod = @import("move.zig");

pub const Mode = enum {
    reference,
    drill,
    recognition_quiz,
};

pub const AttemptState = enum {
    idle,
    running,
    succeeded,
    failed,
};

pub const AnswerResult = enum {
    none,
    correct,
    incorrect,
};

pub const PlaybackKind = enum {
    setup,
    solution,
};

pub const PlaybackRequest = struct {
    kind: PlaybackKind,
    moves: []const move_mod.Move,
};

pub const Error = error{
    WrongMode,
    AttemptAlreadyRunning,
    AttemptNotRunning,
};

pub const Session = struct {
    mode: Mode,
    selected_case: *const cfop_cases.CaseDefinition,
    prompt_cube: cube_mod.Cube,
    hint_visible: bool = false,
    attempt_state: AttemptState = .idle,
    elapsed_ms: u32 = 0,
    last_answer: AnswerResult = .none,
    last_playback: ?PlaybackRequest = null,

    pub fn init(mode: Mode, selected_case: *const cfop_cases.CaseDefinition) Session {
        return .{
            .mode = mode,
            .selected_case = selected_case,
            .prompt_cube = promptCube(selected_case),
        };
    }

    pub fn chooseCase(self: *Session, selected_case: *const cfop_cases.CaseDefinition) void {
        self.selected_case = selected_case;
        self.resetPrompt();
    }

    pub fn setMode(self: *Session, mode: Mode) void {
        self.mode = mode;
        self.resetAttempt();
    }

    pub fn resetPrompt(self: *Session) void {
        self.prompt_cube = promptCube(self.selected_case);
        self.hint_visible = false;
        self.last_playback = null;
        self.resetAttempt();
    }

    pub fn showHint(self: *Session) void {
        self.hint_visible = true;
    }

    pub fn hideHint(self: *Session) void {
        self.hint_visible = false;
    }

    pub fn startAttempt(self: *Session) Error!void {
        if (self.mode == .reference) return Error.WrongMode;
        if (self.attempt_state == .running) return Error.AttemptAlreadyRunning;

        self.attempt_state = .running;
        self.elapsed_ms = 0;
        self.last_answer = .none;
        self.hint_visible = false;
    }

    pub fn tick(self: *Session, delta_ms: u32) void {
        if (self.attempt_state == .running) {
            self.elapsed_ms +|= delta_ms;
        }
    }

    pub fn submitCaseId(self: *Session, case_id: []const u8) Error!AnswerResult {
        if (self.mode != .recognition_quiz) return Error.WrongMode;
        try self.requireRunningAttempt();

        if (std.mem.eql(u8, case_id, self.selected_case.id)) {
            return self.finishAttempt(.correct);
        }
        return self.finishAttempt(.incorrect);
    }

    pub fn submitMoves(self: *Session, moves: []const move_mod.Move) Error!AnswerResult {
        if (self.mode != .drill) return Error.WrongMode;
        try self.requireRunningAttempt();

        var cube = self.prompt_cube;
        cube.applyMoves(moves);
        if (cube.isSolved()) {
            return self.finishAttempt(.correct);
        }
        return self.finishAttempt(.incorrect);
    }

    pub fn completeAttempt(self: *Session, correct: bool) Error!AnswerResult {
        if (self.mode == .reference) return Error.WrongMode;
        try self.requireRunningAttempt();
        return self.finishAttempt(if (correct) .correct else .incorrect);
    }

    pub fn playSetup(self: *Session) PlaybackRequest {
        self.last_playback = .{
            .kind = .setup,
            .moves = self.selected_case.setup.moves,
        };
        return self.last_playback.?;
    }

    pub fn playSolution(self: *Session) PlaybackRequest {
        self.last_playback = .{
            .kind = .solution,
            .moves = self.selected_case.solution.moves,
        };
        return self.last_playback.?;
    }

    fn requireRunningAttempt(self: Session) Error!void {
        if (self.attempt_state != .running) return Error.AttemptNotRunning;
    }

    fn finishAttempt(self: *Session, result: AnswerResult) AnswerResult {
        self.last_answer = result;
        self.attempt_state = if (result == .correct) .succeeded else .failed;
        return result;
    }

    fn resetAttempt(self: *Session) void {
        self.attempt_state = .idle;
        self.elapsed_ms = 0;
        self.last_answer = .none;
    }
};

fn promptCube(selected_case: *const cfop_cases.CaseDefinition) cube_mod.Cube {
    var cube = cube_mod.Cube.solved();
    selected_case.setup.apply(&cube);
    return cube;
}
