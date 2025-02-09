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

pub fn calcLcm(factors1: []u64, factors2: []u64) Lcm {
    var lcm: Lcm = .{ .fac1 = 1, .fac2 = 1 };
    var index1: u64 = 0;
    var index2: u64 = 0;
    while (true) {
        const val1: u64 = if (index1 < factors1.len) factors1[index1] else maxInt;
        const val2: u64 = if (index2 < factors2.len) factors2[index2] else maxInt;

        if (val1 == maxInt and val2 == maxInt) {
            return lcm;
        }

        if (val1 == val2) {
            index1 += 1;
            index2 += 1;
        } else if (val1 < val2) {
            lcm.fac2 *= val1;
            index1 += 1;
        } else {
            lcm.fac1 *= val2;
            index2 += 1;
        }
    }
}

pub fn calcGcd(factors1: []u64, factors2: []u64) u64 {
    var gcd: u64 = 1;
    var index1: u64 = 0;
    var index2: u64 = 0;
    while (true) {
        const val1: u64 = if (index1 < factors1.len) factors1[index1] else maxInt;
        const val2: u64 = if (index2 < factors2.len) factors2[index2] else maxInt;

        if (val1 == maxInt and val2 == maxInt) {
            return gcd;
        }

        if (val1 == val2) {
            index1 += 1;
            index2 += 1;
            gcd *= val1;
        } else if (val1 < val2) {
            index1 += 1;
        } else {
            index2 += 1;
        }
    }
}

pub fn reduceFrac(a: Frac) !Frac {
    const factorsNum = try factorize(a.num);
    const factorsDen = try factorize(a.den);
    const gcd: u63 = @intCast(calcGcd(factorsNum, factorsDen));
    return Frac{ .num = @divTrunc(a.num, gcd), .den = @divTrunc(a.den, gcd) };
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
