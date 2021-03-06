const std = @import("std");
const assertOrPanic = std.debug.assertOrPanic;
const builtin = @import("builtin");
const maxInt = std.math.maxInt;

const StructWithNoFields = struct {
    fn add(a: i32, b: i32) i32 {
        return a + b;
    }
};
const empty_global_instance = StructWithNoFields{};

test "call struct static method" {
    const result = StructWithNoFields.add(3, 4);
    assertOrPanic(result == 7);
}

test "return empty struct instance" {
    _ = returnEmptyStructInstance();
}
fn returnEmptyStructInstance() StructWithNoFields {
    return empty_global_instance;
}

const should_be_11 = StructWithNoFields.add(5, 6);

test "invoke static method in global scope" {
    assertOrPanic(should_be_11 == 11);
}

test "void struct fields" {
    const foo = VoidStructFieldsFoo{
        .a = void{},
        .b = 1,
        .c = void{},
    };
    assertOrPanic(foo.b == 1);
    assertOrPanic(@sizeOf(VoidStructFieldsFoo) == 4);
}
const VoidStructFieldsFoo = struct {
    a: void,
    b: i32,
    c: void,
};

test "structs" {
    var foo: StructFoo = undefined;
    @memset(@ptrCast([*]u8, &foo), 0, @sizeOf(StructFoo));
    foo.a += 1;
    foo.b = foo.a == 1;
    testFoo(foo);
    testMutation(&foo);
    assertOrPanic(foo.c == 100);
}
const StructFoo = struct {
    a: i32,
    b: bool,
    c: f32,
};
fn testFoo(foo: StructFoo) void {
    assertOrPanic(foo.b);
}
fn testMutation(foo: *StructFoo) void {
    foo.c = 100;
}

const Node = struct {
    val: Val,
    next: *Node,
};

const Val = struct {
    x: i32,
};

test "struct point to self" {
    var root: Node = undefined;
    root.val.x = 1;

    var node: Node = undefined;
    node.next = &root;
    node.val.x = 2;

    root.next = &node;

    assertOrPanic(node.next.next.next.val.x == 1);
}

test "struct byval assign" {
    var foo1: StructFoo = undefined;
    var foo2: StructFoo = undefined;

    foo1.a = 1234;
    foo2.a = 0;
    assertOrPanic(foo2.a == 0);
    foo2 = foo1;
    assertOrPanic(foo2.a == 1234);
}

fn structInitializer() void {
    const val = Val{ .x = 42 };
    assertOrPanic(val.x == 42);
}

test "fn call of struct field" {
    assertOrPanic(callStructField(Foo{ .ptr = aFunc }) == 13);
}

const Foo = struct {
    ptr: fn () i32,
};

fn aFunc() i32 {
    return 13;
}

fn callStructField(foo: Foo) i32 {
    return foo.ptr();
}

test "store member function in variable" {
    const instance = MemberFnTestFoo{ .x = 1234 };
    const memberFn = MemberFnTestFoo.member;
    const result = memberFn(instance);
    assertOrPanic(result == 1234);
}
const MemberFnTestFoo = struct {
    x: i32,
    fn member(foo: MemberFnTestFoo) i32 {
        return foo.x;
    }
};

test "call member function directly" {
    const instance = MemberFnTestFoo{ .x = 1234 };
    const result = MemberFnTestFoo.member(instance);
    assertOrPanic(result == 1234);
}

test "member functions" {
    const r = MemberFnRand{ .seed = 1234 };
    assertOrPanic(r.getSeed() == 1234);
}
const MemberFnRand = struct {
    seed: u32,
    pub fn getSeed(r: *const MemberFnRand) u32 {
        return r.seed;
    }
};

test "return struct byval from function" {
    const bar = makeBar(1234, 5678);
    assertOrPanic(bar.y == 5678);
}
const Bar = struct {
    x: i32,
    y: i32,
};
fn makeBar(x: i32, y: i32) Bar {
    return Bar{
        .x = x,
        .y = y,
    };
}

test "empty struct method call" {
    const es = EmptyStruct{};
    assertOrPanic(es.method() == 1234);
}
const EmptyStruct = struct {
    fn method(es: *const EmptyStruct) i32 {
        return 1234;
    }
};

test "return empty struct from fn" {
    _ = testReturnEmptyStructFromFn();
}
const EmptyStruct2 = struct {};
fn testReturnEmptyStructFromFn() EmptyStruct2 {
    return EmptyStruct2{};
}

test "pass slice of empty struct to fn" {
    assertOrPanic(testPassSliceOfEmptyStructToFn([]EmptyStruct2{EmptyStruct2{}}) == 1);
}
fn testPassSliceOfEmptyStructToFn(slice: []const EmptyStruct2) usize {
    return slice.len;
}

const APackedStruct = packed struct {
    x: u8,
    y: u8,
};

test "packed struct" {
    var foo = APackedStruct{
        .x = 1,
        .y = 2,
    };
    foo.y += 1;
    const four = foo.x + foo.y;
    assertOrPanic(four == 4);
}

const BitField1 = packed struct {
    a: u3,
    b: u3,
    c: u2,
};

const bit_field_1 = BitField1{
    .a = 1,
    .b = 2,
    .c = 3,
};

test "bit field access" {
    var data = bit_field_1;
    assertOrPanic(getA(&data) == 1);
    assertOrPanic(getB(&data) == 2);
    assertOrPanic(getC(&data) == 3);
    comptime assertOrPanic(@sizeOf(BitField1) == 1);

    data.b += 1;
    assertOrPanic(data.b == 3);

    data.a += 1;
    assertOrPanic(data.a == 2);
    assertOrPanic(data.b == 3);
}

fn getA(data: *const BitField1) u3 {
    return data.a;
}

fn getB(data: *const BitField1) u3 {
    return data.b;
}

fn getC(data: *const BitField1) u2 {
    return data.c;
}

const Foo24Bits = packed struct {
    field: u24,
};
const Foo96Bits = packed struct {
    a: u24,
    b: u24,
    c: u24,
    d: u24,
};

test "packed struct 24bits" {
    comptime {
        assertOrPanic(@sizeOf(Foo24Bits) == 3);
        assertOrPanic(@sizeOf(Foo96Bits) == 12);
    }

    var value = Foo96Bits{
        .a = 0,
        .b = 0,
        .c = 0,
        .d = 0,
    };
    value.a += 1;
    assertOrPanic(value.a == 1);
    assertOrPanic(value.b == 0);
    assertOrPanic(value.c == 0);
    assertOrPanic(value.d == 0);

    value.b += 1;
    assertOrPanic(value.a == 1);
    assertOrPanic(value.b == 1);
    assertOrPanic(value.c == 0);
    assertOrPanic(value.d == 0);

    value.c += 1;
    assertOrPanic(value.a == 1);
    assertOrPanic(value.b == 1);
    assertOrPanic(value.c == 1);
    assertOrPanic(value.d == 0);

    value.d += 1;
    assertOrPanic(value.a == 1);
    assertOrPanic(value.b == 1);
    assertOrPanic(value.c == 1);
    assertOrPanic(value.d == 1);
}

const FooArray24Bits = packed struct {
    a: u16,
    b: [2]Foo24Bits,
    c: u16,
};

test "packed array 24bits" {
    comptime {
        assertOrPanic(@sizeOf([9]Foo24Bits) == 9 * 3);
        assertOrPanic(@sizeOf(FooArray24Bits) == 2 + 2 * 3 + 2);
    }

    var bytes = []u8{0} ** (@sizeOf(FooArray24Bits) + 1);
    bytes[bytes.len - 1] = 0xaa;
    const ptr = &@bytesToSlice(FooArray24Bits, bytes[0 .. bytes.len - 1])[0];
    assertOrPanic(ptr.a == 0);
    assertOrPanic(ptr.b[0].field == 0);
    assertOrPanic(ptr.b[1].field == 0);
    assertOrPanic(ptr.c == 0);

    ptr.a = maxInt(u16);
    assertOrPanic(ptr.a == maxInt(u16));
    assertOrPanic(ptr.b[0].field == 0);
    assertOrPanic(ptr.b[1].field == 0);
    assertOrPanic(ptr.c == 0);

    ptr.b[0].field = maxInt(u24);
    assertOrPanic(ptr.a == maxInt(u16));
    assertOrPanic(ptr.b[0].field == maxInt(u24));
    assertOrPanic(ptr.b[1].field == 0);
    assertOrPanic(ptr.c == 0);

    ptr.b[1].field = maxInt(u24);
    assertOrPanic(ptr.a == maxInt(u16));
    assertOrPanic(ptr.b[0].field == maxInt(u24));
    assertOrPanic(ptr.b[1].field == maxInt(u24));
    assertOrPanic(ptr.c == 0);

    ptr.c = maxInt(u16);
    assertOrPanic(ptr.a == maxInt(u16));
    assertOrPanic(ptr.b[0].field == maxInt(u24));
    assertOrPanic(ptr.b[1].field == maxInt(u24));
    assertOrPanic(ptr.c == maxInt(u16));

    assertOrPanic(bytes[bytes.len - 1] == 0xaa);
}

const FooStructAligned = packed struct {
    a: u8,
    b: u8,
};

const FooArrayOfAligned = packed struct {
    a: [2]FooStructAligned,
};

test "aligned array of packed struct" {
    comptime {
        assertOrPanic(@sizeOf(FooStructAligned) == 2);
        assertOrPanic(@sizeOf(FooArrayOfAligned) == 2 * 2);
    }

    var bytes = []u8{0xbb} ** @sizeOf(FooArrayOfAligned);
    const ptr = &@bytesToSlice(FooArrayOfAligned, bytes[0..bytes.len])[0];

    assertOrPanic(ptr.a[0].a == 0xbb);
    assertOrPanic(ptr.a[0].b == 0xbb);
    assertOrPanic(ptr.a[1].a == 0xbb);
    assertOrPanic(ptr.a[1].b == 0xbb);
}

test "runtime struct initialization of bitfield" {
    const s1 = Nibbles{
        .x = x1,
        .y = x1,
    };
    const s2 = Nibbles{
        .x = @intCast(u4, x2),
        .y = @intCast(u4, x2),
    };

    assertOrPanic(s1.x == x1);
    assertOrPanic(s1.y == x1);
    assertOrPanic(s2.x == @intCast(u4, x2));
    assertOrPanic(s2.y == @intCast(u4, x2));
}

var x1 = u4(1);
var x2 = u8(2);

const Nibbles = packed struct {
    x: u4,
    y: u4,
};

const Bitfields = packed struct {
    f1: u16,
    f2: u16,
    f3: u8,
    f4: u8,
    f5: u4,
    f6: u4,
    f7: u8,
};

test "native bit field understands endianness" {
    var all: u64 = 0x7765443322221111;
    var bytes: [8]u8 = undefined;
    @memcpy(bytes[0..].ptr, @ptrCast([*]u8, &all), 8);
    var bitfields = @ptrCast(*Bitfields, bytes[0..].ptr).*;

    assertOrPanic(bitfields.f1 == 0x1111);
    assertOrPanic(bitfields.f2 == 0x2222);
    assertOrPanic(bitfields.f3 == 0x33);
    assertOrPanic(bitfields.f4 == 0x44);
    assertOrPanic(bitfields.f5 == 0x5);
    assertOrPanic(bitfields.f6 == 0x6);
    assertOrPanic(bitfields.f7 == 0x77);
}

test "align 1 field before self referential align 8 field as slice return type" {
    const result = alloc(Expr);
    assertOrPanic(result.len == 0);
}

const Expr = union(enum) {
    Literal: u8,
    Question: *Expr,
};

fn alloc(comptime T: type) []T {
    return []T{};
}

test "call method with mutable reference to struct with no fields" {
    const S = struct {
        fn doC(s: *const @This()) bool {
            return true;
        }
        fn do(s: *@This()) bool {
            return true;
        }
    };

    var s = S{};
    assertOrPanic(S.doC(&s));
    assertOrPanic(s.doC());
    assertOrPanic(S.do(&s));
    assertOrPanic(s.do());
}

test "implicit cast packed struct field to const ptr" {
    const LevelUpMove = packed struct {
        move_id: u9,
        level: u7,

        fn toInt(value: u7) u7 {
            return value;
        }
    };

    var lup: LevelUpMove = undefined;
    lup.level = 12;
    const res = LevelUpMove.toInt(lup.level);
    assertOrPanic(res == 12);
}

test "pointer to packed struct member in a stack variable" {
    const S = packed struct {
        a: u2,
        b: u2,
    };

    var s = S{ .a = 2, .b = 0 };
    var b_ptr = &s.b;
    assertOrPanic(s.b == 0);
    b_ptr.* = 2;
    assertOrPanic(s.b == 2);
}
