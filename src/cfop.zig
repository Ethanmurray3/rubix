pub const Stage = enum {
    cross,
    f2l,
    oll,
    pll,
};

pub const Look = enum {
    one_look,
    two_look,
};

pub const CaseRef = struct {
    stage: Stage,
    look: Look,
    id: []const u8,

    pub fn eql(self: CaseRef, other: CaseRef) bool {
        return self.stage == other.stage and
            self.look == other.look and
            stringEql(self.id, other.id);
    }
};

pub fn stageName(stage: Stage) []const u8 {
    return switch (stage) {
        .cross => "Cross",
        .f2l => "F2L",
        .oll => "OLL",
        .pll => "PLL",
    };
}

pub fn lookName(look: Look) []const u8 {
    return switch (look) {
        .one_look => "1-look",
        .two_look => "2-look",
    };
}

fn stringEql(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |left, right| {
        if (left != right) return false;
    }
    return true;
}
