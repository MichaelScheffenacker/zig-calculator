const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

const types = @import("types.zig");
const Frac = types.Frac;
const Lcm = types.Lcm;

const maxInt = std.math.maxInt(i64);
var primes: [1024]u64 = undefined;

var currentFactorization: u64 = 0;
var primeFactorizations: [128][128]u64 = undefined;

const PrimeFacErr = error{miss};

var sieve = [_]u64{
    0x4114510504514414,
    0x1145105045144141,
    0x1451050451441411,
    0x4510504514414114,
    0x5105045144141145,
    0x1050451441411451,
    0x0504514414114510,
    0x5045144141145105,
    0x0451441411451050,
    0x4514414114510504,
    0x5144141145105045,
    0x1441411451050451,
    0x4414114510504514,
    0x4141145105045144,
    0x1411451050451441 }**4473925;


pub fn generate() void {
    primes[0] = 2;
    var i: u64 = 3;
    var p: u64 = 1;
    while (p < primes.len) : (i += 1) {
        var q: u64 = 0;
        while (q < p) : (q += 1) {
            if (i % primes[q] == 0) {
                break;
            }
        }
        if (q == p) { // q is incremented one last time when the loop finishes.
            primes[p] = i;
            p += 1;
        }
    }
}

pub fn factorize(number: i64) ![]u64 {
    const abs = if (number < 0) number * -1 else number;
    var facs: []u64 = primeFactorizations[currentFactorization][0..];
    currentFactorization += 1;
    var n: u64 = @intCast(abs);
    for (facs, 0..) |*fac, i| {
        for (primes) |prime| {
            if (n % prime == 0) {
                n = n / prime;
                fac.* = prime;
                break;
            }
            if (n == 1) {
                facs = facs[0..i];
                return facs;
            }
            if (prime > n) {
                return PrimeFacErr.miss;
            }
        }
    }
    return PrimeFacErr.miss;
}

pub fn calcLcm(a: i64, b: i64) Lcm {
    const absA: i64 = @intCast(@abs(a));
    const absB: i64 = @intCast(@abs(b));
    // absA * absB could overflow
    // dividing first could reduce the risk
    // at this point the order of execution is unclear in Zig
    // unclear if the parenthesis forces a the order of execution
    // todo: add overflow check
    return absA * (absB / calcGcd(a, b));
}

pub fn calcGcd(a: i64, b: i64) i64 {
    if (b == 0) { return a; }
    const absA: i64 = @intCast(@abs(a));
    const absB: i64 = @intCast(@abs(b));
    return calcGcd(absB, @rem(absA, absB));
}

pub fn reduceFrac(a: Frac) Frac {
    if (a.den == 0) { return a; }
    const sign: i2 = if (a.den < 0) -1 else 1;
    const gcd: i64 = calcGcd(a.num, a.den);
    return Frac{
        .num = sign * @divExact(a.num, gcd),
        .den = sign * @divExact(a.den, gcd)
    };
}


test "prime array test" {
    generate();
    try expect(primes[0] == 2);
    try expect(primes[1] == 3);
    try expect(primes[2] == 5);
    try expect(primes[1021] == 8123);
    try expect(primes[1022] == 8147);
    try expect(primes[1023] == 8161);
}

test "gdc test" {
    try expect(calcGcd(12,  6) ==  6);
    try expect(calcGcd( 6, 12) ==  6);
    try expect(calcGcd( 6,  6) ==  6);
    try expect(calcGcd( 8,  6) ==  2);
    try expect(calcGcd( 0,  4) ==  4);
    try expect(calcGcd( 4,  0) ==  4);
    try expect(calcGcd( 0,  0) ==  0);
    try expect(calcGcd(-8,  6) ==  2);
    try expect(calcGcd( 8, -6) ==  2);
    try expect(calcGcd(-8, -6) ==  2);
    try expect(calcGcd(456748351263, 789465123468) == 261);
}

test "reduceFrac test" {
    var frac: Frac = undefined;

    frac =reduceFrac(Frac{ .num = 12, .den = 6});
    try expect(frac.num == 2 and frac.den == 1);
    
    frac = reduceFrac(Frac{ .num = 6, .den = 12});
    try expect(frac.num == 1 and frac.den == 2);
    
    frac = reduceFrac(Frac{ .num = 6, .den = 6});
    try expect(frac.num == 1 and frac.den == 1);
    
    frac = reduceFrac(Frac{ .num = -8, .den = 6});
    try expect(frac.num == -4 and frac.den == 3);
    
    frac = reduceFrac(Frac{ .num = 8, .den = -6});
    try expect(frac.num == -4 and frac.den == 3);
    
    frac = reduceFrac(Frac{ .num = -8, .den = -6});
    try expect(frac.num == 4 and frac.den == 3);
}

test "log2" {
    const b: i64 = 0b110011;
    try expect(64 - @clz(b) == 6);
}
