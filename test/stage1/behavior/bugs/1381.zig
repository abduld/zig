const std = @import("std");

const B = union(enum) {
    D: u8,
    E: u16,
};

const A = union(enum) {
    B: B,
    C: u8,
};

test "union that needs padding bytes inside an array" {
    var as = []A{
        A{ .B = B{ .D = 1 } },
        A{ .B = B{ .D = 1 } },
    };

    const a = as[0].B;
    std.debug.assertOrPanic(a.D == 1);
}
