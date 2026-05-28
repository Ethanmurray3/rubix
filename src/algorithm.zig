const std = @import("std");
const cfop = @import("cfop.zig");
const cube_mod = @import("cube.zig");
const move_mod = @import("move.zig");
const notation = @import("notation.zig");

pub const ValidationError = error{
    EmptyId,
    EmptyCaseId,
    EmptyDisplay,
    EmptySourceName,
    EmptySourceUrl,
    MovesDoNotMatchDisplay,
};

pub const Source = struct {
    name: []const u8,
    url: []const u8,
};

pub const Definition = struct {
    id: []const u8,
    case: cfop.CaseRef,
    name: []const u8,
    display: []const u8,
    source: Source,
    moves: []const move_mod.Move,

    pub fn validate(self: Definition, allocator: std.mem.Allocator) !void {
        if (self.id.len == 0) return ValidationError.EmptyId;
        if (self.case.id.len == 0) return ValidationError.EmptyCaseId;
        if (self.display.len == 0) return ValidationError.EmptyDisplay;
        if (self.source.name.len == 0) return ValidationError.EmptySourceName;
        if (self.source.url.len == 0) return ValidationError.EmptySourceUrl;

        const parsed = try notation.parseExecutableAlgorithm(allocator, self.display);
        defer allocator.free(parsed);
        if (!std.mem.eql(move_mod.Move, parsed, self.moves)) {
            return ValidationError.MovesDoNotMatchDisplay;
        }
    }

    pub fn apply(self: Definition, cube: *cube_mod.Cube) void {
        cube.applyMoves(self.moves);
    }
};
