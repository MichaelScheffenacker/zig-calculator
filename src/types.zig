const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

const fractions = @import("fractions.zig");

pub const Frac = struct { num: i64, den: i64 };

const Factors = AppendableSlice(i64);

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

pub const FracOfProducts= struct {
    num: []i64,
    den: []i64,
    pub fn printTop(this: FracOfProducts) void {
        const numWidth = calcSliceWidth(this.num);
        if (isOnlyProduct(this)) { printRepeat(numWidth, " "); } else { printFracNum(this); }
    }
    pub fn printMid(this: FracOfProducts) void {
        const fracWidth = calcFracWidth(this);
        if (isOnlyProduct(this)) { printSeparatedSlice(this.num, "·"); } else { printRepeat(fracWidth, "—"); }
    }
    pub fn printBot(this: FracOfProducts) void {
        const numWidth = calcSliceWidth(this.num);
        if (isOnlyProduct(this)) { printRepeat(numWidth, " "); } else { printFracDen(this); }
    }
    pub fn toFrac(this: FracOfProducts) Frac {
        const frac = Frac{
            .num = multiplyFactors(this.num),
            .den = if (isOnlyProduct(this)) 1 else multiplyFactors(this.den)
        };
        return fractions.reduce(frac);
    }
    fn isOnlyProduct(this: FracOfProducts) bool {
        return this.den.len == 0;
    }
};

fn printRepeat(n: u64, comptime str: []const u8) void {
    for (0..n) |_| print(str, .{});
}

pub fn printFrac(a: Frac) void {
    std.debug.print("{}/{}", .{ a.num, a.den });
}

fn printFracNum(frac: FracOfProducts) void {
    printFracElement(frac, frac.num);
}

fn printFracDen(frac: FracOfProducts) void {
    printFracElement(frac, frac.den);
}

fn printFracElement(frac: FracOfProducts, element: []i64) void {
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

fn calcFracWidth(x: FracOfProducts) u64 {
    const numWidth = calcSliceWidth(x.num);
    const denWidth = calcSliceWidth(x.den);
    return max(numWidth, denWidth);
}

fn calcSliceWidth(factors: []i64) u64 {
    if (factors.len == 0) return 0;
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

fn multiplyFactors(factors: []i64) i64 {
    //todo: add overflow check
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

