const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

const maxInt = std.math.maxInt(i64);
var primes: [1024]u64 = undefined;

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

test "prime array test" {
    generate();
    try expect(primes[0] == 2);
    try expect(primes[1] == 3);
    try expect(primes[2] == 5);
    try expect(primes[1021] == 8123);
    try expect(primes[1022] == 8147);
    try expect(primes[1023] == 8161);
}
