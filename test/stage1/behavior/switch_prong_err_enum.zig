const assertOrPanic = @import("std").debug.assertOrPanic;

var read_count: u64 = 0;

fn readOnce() anyerror!u64 {
    read_count += 1;
    return read_count;
}

const FormValue = union(enum) {
    Address: u64,
    Other: bool,
};

fn doThing(form_id: u64) anyerror!FormValue {
    return switch (form_id) {
        17 => FormValue{ .Address = try readOnce() },
        else => error.InvalidDebugInfo,
    };
}

test "switch prong returns error enum" {
    switch (doThing(17) catch unreachable) {
        FormValue.Address => |payload| {
            assertOrPanic(payload == 1);
        },
        else => unreachable,
    }
    assertOrPanic(read_count == 1);
}
