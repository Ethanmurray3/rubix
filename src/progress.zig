const std = @import("std");

pub const max_cases = 64;

pub const AttemptKind = enum {
    drill,
    recognition,
};

pub const Error = error{
    BookFull,
};

pub const Attempt = struct {
    case_id: []const u8,
    kind: AttemptKind,
    success: bool,
    elapsed_ms: u32,
    review_tick: u32 = 0,
};

pub const CaseStats = struct {
    case_id: []const u8,
    attempts: u32 = 0,
    successes: u32 = 0,
    drill_attempts: u32 = 0,
    drill_successes: u32 = 0,
    recognition_attempts: u32 = 0,
    recognition_successes: u32 = 0,
    total_elapsed_ms: u64 = 0,
    best_elapsed_ms: ?u32 = null,
    current_streak: u32 = 0,
    learned: bool = false,
    last_review_tick: u32 = 0,
    next_due_tick: u32 = 0,

    pub fn successRate(self: CaseStats) f32 {
        if (self.attempts == 0) return 0;
        return @as(f32, @floatFromInt(self.successes)) / @as(f32, @floatFromInt(self.attempts));
    }

    pub fn recognitionAccuracy(self: CaseStats) f32 {
        if (self.recognition_attempts == 0) return 0;
        return @as(f32, @floatFromInt(self.recognition_successes)) / @as(f32, @floatFromInt(self.recognition_attempts));
    }

    pub fn averageElapsedMs(self: CaseStats) ?u32 {
        if (self.attempts == 0) return null;
        return @intCast(self.total_elapsed_ms / self.attempts);
    }

    pub fn weakScore(self: CaseStats) f32 {
        if (self.attempts == 0) return 1;
        const failure_rate = 1 - self.successRate();
        const familiarity_penalty: f32 = if (self.attempts < 5) 0.25 else 0;
        return failure_rate + familiarity_penalty;
    }
};

pub const Book = struct {
    entries: [max_cases]CaseStats = undefined,
    len: usize = 0,

    pub fn recordAttempt(self: *Book, attempt: Attempt) Error!*CaseStats {
        const stats = try self.entryFor(attempt.case_id);

        stats.attempts += 1;
        stats.total_elapsed_ms += attempt.elapsed_ms;
        stats.last_review_tick = attempt.review_tick;

        if (stats.best_elapsed_ms == null or attempt.elapsed_ms < stats.best_elapsed_ms.?) {
            stats.best_elapsed_ms = attempt.elapsed_ms;
        }

        switch (attempt.kind) {
            .drill => stats.drill_attempts += 1,
            .recognition => stats.recognition_attempts += 1,
        }

        if (attempt.success) {
            stats.successes += 1;
            stats.current_streak += 1;
            switch (attempt.kind) {
                .drill => stats.drill_successes += 1,
                .recognition => stats.recognition_successes += 1,
            }
        } else {
            stats.current_streak = 0;
        }

        stats.learned = stats.attempts >= 5 and stats.current_streak >= 3 and stats.successRate() >= 0.8;
        stats.next_due_tick = attempt.review_tick + if (attempt.success) learnedInterval(stats.learned) else 1;

        return stats;
    }

    pub fn statsFor(self: *const Book, case_id: []const u8) ?*const CaseStats {
        for (self.entries[0..self.len]) |*entry| {
            if (std.mem.eql(u8, entry.case_id, case_id)) return entry;
        }
        return null;
    }

    pub fn weakCases(self: *const Book, out: []*const CaseStats) []const *const CaseStats {
        const count = @min(out.len, self.len);
        for (self.entries[0..count], 0..) |*entry, index| {
            out[index] = entry;
        }

        std.mem.sort(*const CaseStats, out[0..count], {}, weakLessThan);
        return out[0..count];
    }

    pub fn dueCases(self: *const Book, now_tick: u32, out: []*const CaseStats) []const *const CaseStats {
        var count: usize = 0;
        for (self.entries[0..self.len]) |*entry| {
            if (entry.next_due_tick <= now_tick and count < out.len) {
                out[count] = entry;
                count += 1;
            }
        }

        std.mem.sort(*const CaseStats, out[0..count], {}, dueLessThan);
        return out[0..count];
    }

    fn entryFor(self: *Book, case_id: []const u8) Error!*CaseStats {
        for (self.entries[0..self.len]) |*entry| {
            if (std.mem.eql(u8, entry.case_id, case_id)) return entry;
        }

        if (self.len >= self.entries.len) return Error.BookFull;

        self.entries[self.len] = .{ .case_id = case_id };
        self.len += 1;
        return &self.entries[self.len - 1];
    }
};

fn learnedInterval(learned: bool) u32 {
    return if (learned) 10 else 3;
}

fn weakLessThan(_: void, left: *const CaseStats, right: *const CaseStats) bool {
    const left_score = left.weakScore();
    const right_score = right.weakScore();
    if (left_score == right_score) return std.mem.lessThan(u8, left.case_id, right.case_id);
    return left_score > right_score;
}

fn dueLessThan(_: void, left: *const CaseStats, right: *const CaseStats) bool {
    if (left.next_due_tick == right.next_due_tick) return std.mem.lessThan(u8, left.case_id, right.case_id);
    return left.next_due_tick < right.next_due_tick;
}
