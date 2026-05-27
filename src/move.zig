pub const Move = enum(u5) {
    U,
    UPrime,
    U2,
    D,
    DPrime,
    D2,
    R,
    RPrime,
    R2,
    L,
    LPrime,
    L2,
    F,
    FPrime,
    F2,
    B,
    BPrime,
    B2,
};

pub const MoveAxis = enum {
    up_down,
    right_left,
    front_back,
};

pub fn moveAxis(move: Move) MoveAxis {
    return switch (move) {
        .U, .UPrime, .U2, .D, .DPrime, .D2 => .up_down,
        .R, .RPrime, .R2, .L, .LPrime, .L2 => .right_left,
        .F, .FPrime, .F2, .B, .BPrime, .B2 => .front_back,
    };
}

pub fn inverseMove(move: Move) Move {
    return switch (move) {
        .U => .UPrime,
        .UPrime => .U,
        .U2 => .U2,
        .D => .DPrime,
        .DPrime => .D,
        .D2 => .D2,
        .R => .RPrime,
        .RPrime => .R,
        .R2 => .R2,
        .L => .LPrime,
        .LPrime => .L,
        .L2 => .L2,
        .F => .FPrime,
        .FPrime => .F,
        .F2 => .F2,
        .B => .BPrime,
        .BPrime => .B,
        .B2 => .B2,
    };
}

pub fn moveName(move: Move) []const u8 {
    return switch (move) {
        .U => "U",
        .UPrime => "U'",
        .U2 => "U2",
        .D => "D",
        .DPrime => "D'",
        .D2 => "D2",
        .R => "R",
        .RPrime => "R'",
        .R2 => "R2",
        .L => "L",
        .LPrime => "L'",
        .L2 => "L2",
        .F => "F",
        .FPrime => "F'",
        .F2 => "F2",
        .B => "B",
        .BPrime => "B'",
        .B2 => "B2",
    };
}
