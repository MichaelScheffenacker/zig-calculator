const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

const primes = @import("primes.zig");

pub const Frac = struct { num: i64, den: i64 };
pub const PFrac = struct { num: []i64, den: []i64 };
pub const Lcm = struct { fac1: u64, fac2: u64 };

pub fn AppendableSlice(comptime T: type) type { // to create a generic (struct) a function returning generic Type is required ...
    return struct { // ... this leads to utilization of an anonymous struct ...
        const This = @This(); // ... therefore instead of referencing the scruct by name the builtin function @This() is used.
        slice: []T,
        pub fn init(buffer: []T) This { // Since Zig requires arrays sizes to be known at compile time, passing it by reference is required ...
            return This{ .slice = buffer[0..0] }; // ... here; for some reason a slice and can be used as such reference.
        }
        pub fn append(this: This, value: T) This {
            var slice = this.slice;
            const pos = slice.len;
            slice.len += 1;
            slice[pos] = value;
            return This{ .slice = slice };
        }
        pub fn printSlice(this: This) void {
            for (this.slice) |element| {
                element.printx();
            }
            print("\n", .{});
        }
    };
}

pub const Expression = union(enum) {
    int: i64,
    frac: Frac,
    op: u8,
    pub fn printx(this: Expression) void {
        switch (this) {
            .int => |int| print("{} ", .{int}),
            .frac => |frac| {
                printFrac(frac);
                print(" ", .{});
            },
            .op => |op| print("{c} ", .{op}),
        }
    }
    pub fn isDivisionOperator(this: Expression) bool {
        return switch (this) {
            .int => false,
            .frac => false,
            .op => |operator| operator == '/',
        };
    }
};

pub const Summand = union(enum) {
    prod: []i64,
    frac: PFrac,
    pub fn printTop(this: Summand) void {
        switch (this) {
            .prod => |prod| for (0..calcSliceWidth(prod)) |_| {
                print(" ", .{});
            },
            .frac => |frac| printFracNum(frac),
        }
    }
    pub fn printMid(this: Summand) void {
        switch (this) {
            .prod => |prod| printSeparatedSlice(prod, "·"),
            .frac => |frac| for (0..calcFracWidth(frac)) |_| print("—", .{}),
        }
    }
    pub fn printBot(this: Summand) void {
        switch (this) {
            .prod => |prod| for (0..calcSliceWidth(prod)) |_| print(" ", .{}),
            .frac => |frac| printFracDen(frac),
        }
    }
    pub fn normal(this: Summand) Frac {
        switch (this) {
            .prod => |prod| return Frac{ .num = multiplyFactors(prod), .den = 1 },
            .frac => |frac| return pFracToNormalizedFrac(frac),
        }
    }
};

pub fn printFrac(a: Frac) void {
    std.debug.print("{}/{}", .{ a.num, a.den });
}

fn printFracNum(frac: PFrac) void {
    printFracElement(frac, frac.num);
}

fn printFracDen(frac: PFrac) void {
    printFracElement(frac, frac.den);
}

fn printFracElement(frac: PFrac, element: []i64) void {
    const elementWidth = calcSliceWidth(element);
    const width = calcFracWidth(frac);
    const preWidth = (width - elementWidth) / 2;
    const postWidth = width - elementWidth - preWidth;
    for (0..preWidth) |_| {
        print(" ", .{});
    }
    printSeparatedSlice(element, "·");
    for (0..postWidth) |_| {
        print(" ", .{});
    }
}

fn calcFracWidth(x: PFrac) u64 {
    const numWidth = calcSliceWidth(x.num);
    const denWidth = calcSliceWidth(x.den);
    return max(numWidth, denWidth);
}

fn calcSliceWidth(factors: []i64) u64 {
    var w = factors.len - 1; // space for multiplication signs
    for (factors) |factor| {
        var x = factor;
        if (x < 0) {
            w += 1; // space for minus sign
        }
        while (x != 0) {
            w += 1; // space for digits
            x = @divTrunc(x, 10); // optimization potential: logarithm
        }
    }
    return w;
}

fn printSeparatedSlice(slice: []i64, comptime separator: []const u8) void {
    for (slice, 0..) |element, i| {
        print("{}", .{element});
        if (i < slice.len - 1) print(separator, .{});
    }
}

fn pFracToNormalizedFrac(frac: PFrac) Frac {
    const reducedFrac = Frac{
        .num = multiplyFactors(frac.num),
        .den = multiplyFactors(frac.den),
    };
    const signedFrac = if (reducedFrac.den < 0)
        Frac{
            .num = -1 * reducedFrac.num,
            .den = -1 * reducedFrac.den,
        }
    else
        reducedFrac;
    return primes.reduceFrac(signedFrac);
}

fn multiplyFactors(factors: []i64) i64 {
    var product: i64 = 1;
    for (factors) |factor| {
        product *= factor;
    }
    return product;
}

fn max(a: u64, b: u64) u64 {
    return if (a > b) a else b;
}

test "AppendableSlice test" {
    var buff: [8]i8 = undefined;
    var slice = AppendableSlice(i8).init(&buff);
    slice = slice.append(2);
    slice = slice.append(3);
    try expect(slice.slice[0] == 2);
    try expect(slice.slice[1] == 3);
}
