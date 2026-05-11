const std = @import("std");
const render = @import("render.zig");

pub const Color = enum {
    white,
    yellow,
    green,
    blue,
    orange,
    red,
};

pub const Cube = struct {
    stickers: [6][9]Color,

    pub fn solved() Cube {
        return Cube{
            .stickers = .{
                [_]Color{.white} ** 9,
                [_]Color{.yellow} ** 9,
                [_]Color{.green} ** 9,
                [_]Color{.blue} ** 9,
                [_]Color{.orange} ** 9,
                [_]Color{.red} ** 9,
            },
        };
    }

    pub fn turnR(self: *Cube) void {
        const old = self.stickers;
        self.stickers[0][2] = old[2][2];
        self.stickers[0][5] = old[2][5];
        self.stickers[0][8] = old[2][8];
    }
};
