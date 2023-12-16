const std = @import("std");
const print = std.debug.print;

const Frac = struct { num: u64, den: u64 };

var primes: [1024]u64 = undefined;

var primeFactorizations: [128][128]u64 = undefined;

const PrimeFacErr = error { miss };

pub fn main() !void {
    generatePrimes();

    
    
    const a = Frac{ .num = 5, .den = 12 };
    const b = Frac{ .num = 3, .den = 12 };
    const c = add(a, b);

    print("\n", .{});
    print("\n", .{});

    printFrac(a);
    print(" + ", .{});
    printFrac(b);
    print(" = ", .{});
    printFrac(c);

    print("\n", .{});

    const number1 = 156;
    _ = try primeFactorize(number1);
    const number2 = 133;
    _ = try primeFactorize(number2);

    
}

fn add(a: Frac, b: Frac) Frac {
    const c = Frac{ .num = a.num + b.num, .den = a.den };
    return c;
}

fn printFrac(a: Frac) void {
    std.debug.print("{}/{}", .{a.num, a.den});
}

fn printFac(number: u64, factors: []u64) void {
    print("{} = ", .{number});
    for (factors) |p| { print( "{}·", .{p}); }
    print("\n", .{});

}

fn generatePrimes() void {
    primes[0] = 2;
    var i: u64 = 3;
    var p: u64 = 1;
    while (p < primes.len) : (i += 1) {
        var q: u64 = 0;
        while (q < p) : (q += 1) {
            if (i % primes[q] == 0)  { break; }
        }
        if (q == p) {  // q is incremented one last time when the loop finishes.
            primes[p] = i;
            p += 1;
        }
    }
    
    for (primes[0..8]) |prime| { print("{} ", .{prime}); }
    print("... ", .{});
    for (primes[1018..]) |prime| { print("{} ", .{prime}); }
}

fn primeFactorize(number: u64) ![]u64 {
    var facs:[]u64 = primeFactorizations[0][0..];
    var n:u64 = number;
    for (facs, 0..) |*fac, i| {
        for (primes) |prime| {
            if (n % prime == 0) {
                n = n / prime;
                fac.* = prime;
                break;
            }
            if (n == 1) {
                facs = facs[0..i];
                printFac(number, facs);
                return facs;
            }
            if (prime > n) { return PrimeFacErr.miss; }
            
        }
    }
    return PrimeFacErr.miss;
}


// test "simple test" {
//     var list = std.ArrayList(i32).init(std.testing.allocator);
//     defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
//     try list.append(42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }
