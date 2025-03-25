const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

const types = @import("types.zig");
const Frac = types.Frac;

fn lcm(a: i64, b: i64) i64 {
    const absA: i64 = @intCast(@abs(a));
    const absB: i64 = @intCast(@abs(b));
    // absA * absB could overflow
    // dividing first could reduce the risk
    // at this point the order of execution is unclear in Zig
    // unclear if the parenthesis forces a the order of execution
    // todo: add overflow check
    return absA * (absB / gcd(a, b));
}

fn gcd(a: i64, b: i64) i64 {
    if (b == 0) { return a; }
    const absA: i64 = @intCast(@abs(a));
    const absB: i64 = @intCast(@abs(b));
    return gcd(absB, @rem(absA, absB));
}

pub fn reduce(a: Frac) Frac {
    if (a.den == 0) { return a; }
    const sign: i2 = if (a.den < 0) -1 else 1;
    const lgcd: i64 = gcd(a.num, a.den);
    return Frac{
        .num = sign * @divExact(a.num, lgcd),
        .den = sign * @divExact(a.den, lgcd)
    };
}

pub fn add(a: Frac, b: Frac) Frac {
    //todo: add overflow check
    const c = Frac{
        .num = a.num * b.den + b.num * a.den,
        .den = a.den * b.den
    };
    return reduce(c);
}


test "gdc test" {
    try expect(gcd(12,  6) ==  6);
    try expect(gcd( 6, 12) ==  6);
    try expect(gcd( 6,  6) ==  6);
    try expect(gcd( 8,  6) ==  2);
    try expect(gcd( 0,  4) ==  4);
    try expect(gcd( 4,  0) ==  4);
    try expect(gcd( 0,  0) ==  0);
    try expect(gcd(-8,  6) ==  2);
    try expect(gcd( 8, -6) ==  2);
    try expect(gcd(-8, -6) ==  2);
    try expect(gcd(456748351263, 789465123468) == 261);
}

test "reduce test" {
    var frac: Frac = undefined;

    frac =reduce(Frac{ .num = 12, .den = 6});
    try expect(frac.num == 2 and frac.den == 1);
    
    frac = reduce(Frac{ .num = 6, .den = 12});
    try expect(frac.num == 1 and frac.den == 2);
    
    frac = reduce(Frac{ .num = 6, .den = 6});
    try expect(frac.num == 1 and frac.den == 1);
    
    frac = reduce(Frac{ .num = -8, .den = 6});
    try expect(frac.num == -4 and frac.den == 3);
    
    frac = reduce(Frac{ .num = 8, .den = -6});
    try expect(frac.num == -4 and frac.den == 3);
    
    frac = reduce(Frac{ .num = -8, .den = -6});
    try expect(frac.num == 4 and frac.den == 3);
}

test "log2" {
    const b: i64 = 0b110011;
    try expect(64 - @clz(b) == 6);
}

