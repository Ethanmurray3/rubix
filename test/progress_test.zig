const std = @import("std");
const rubix = @import("rubix");

const progress = rubix.progress;

test "progress records attempts and timing stats" {
    var book = progress.Book{};

    _ = try book.recordAttempt(.{ .case_id = "2look-oll-sune", .kind = .drill, .success = true, .elapsed_ms = 1200, .review_tick = 1 });
    const stats = try book.recordAttempt(.{ .case_id = "2look-oll-sune", .kind = .recognition, .success = false, .elapsed_ms = 800, .review_tick = 2 });

    try std.testing.expectEqual(@as(u32, 2), stats.attempts);
    try std.testing.expectEqual(@as(u32, 1), stats.successes);
    try std.testing.expectEqual(@as(u32, 1), stats.drill_successes);
    try std.testing.expectEqual(@as(u32, 1), stats.recognition_attempts);
    try std.testing.expectEqual(@as(?u32, 800), stats.best_elapsed_ms);
    try std.testing.expectEqual(@as(?u32, 1000), stats.averageElapsedMs());
    try std.testing.expectApproxEqAbs(@as(f32, 0.5), stats.successRate(), 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 0.0), stats.recognitionAccuracy(), 0.001);
}

test "progress marks learned after strong streak" {
    var book = progress.Book{};

    for (0..5) |index| {
        const stats = try book.recordAttempt(.{
            .case_id = "2look-pll-ua",
            .kind = .drill,
            .success = true,
            .elapsed_ms = 900,
            .review_tick = @intCast(index),
        });
        if (index < 4) {
            try std.testing.expect(!stats.learned);
        } else {
            try std.testing.expect(stats.learned);
            try std.testing.expectEqual(@as(u32, 14), stats.next_due_tick);
        }
    }
}

test "progress ranks weak cases and due reviews" {
    var book = progress.Book{};
    _ = try book.recordAttempt(.{ .case_id = "strong", .kind = .drill, .success = true, .elapsed_ms = 700, .review_tick = 5 });
    _ = try book.recordAttempt(.{ .case_id = "weak", .kind = .drill, .success = false, .elapsed_ms = 1700, .review_tick = 3 });
    _ = try book.recordAttempt(.{ .case_id = "medium", .kind = .recognition, .success = true, .elapsed_ms = 1200, .review_tick = 1 });

    var weak_buffer: [3]*const progress.CaseStats = undefined;
    const weak_cases = book.weakCases(&weak_buffer);
    try std.testing.expectEqualStrings("weak", weak_cases[0].case_id);

    var due_buffer: [3]*const progress.CaseStats = undefined;
    const due_cases = book.dueCases(4, &due_buffer);
    try std.testing.expectEqual(@as(usize, 2), due_cases.len);
    try std.testing.expectEqualStrings("medium", due_cases[0].case_id);
    try std.testing.expectEqualStrings("weak", due_cases[1].case_id);
}
