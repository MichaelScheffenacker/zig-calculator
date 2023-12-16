const std = @import("std");
const print = std.debug.print;

const Frac = struct { num: i64, den: i64 };

var primes: [1024]u64 = undefined;

var primeFactorizations: [128][128]u64 = undefined;

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

    //     // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // // stdout is for the actual output of your application, for example if you
    // // are implementing gzip, then only the compressed bytes should be sent to
    // // stdout, not any debugging messages.
    // const stdout_file = std.io.getStdOut().writer();
    // var bw = std.io.bufferedWriter(stdout_file);
    // const stdout = bw.writer();

    // try stdout.print("Run `zig build test` to run the tests.\n", .{});

    // try bw.flush(); // don't forget to flush!

    print("{any}\n", .{primeFactorize(8)});

    
}

fn add(a: Frac, b: Frac) Frac {
    const c = Frac{ .num = a.num + b.num, .den = a.den };
    return c;
}

fn printFrac(a: Frac) void {
    std.debug.print("{}/{}", .{a.num, a.den});
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
    i = 0;
    while (i < primes.len and i < 100) : (i += 1) {
        std.debug.print("{}, ", .{primes[i]});
    }
}

fn primeFactorize(number: i64) []u64 {
    var facs = primeFactorizations[0][0..3];
    _ = number;
    facs[0] = 2;
    facs[1] = 3;
    facs[2] = 4;
    return facs;
}

// test "simple test" {
//     var list = std.ArrayList(i32).init(std.testing.allocator);
//     defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
//     try list.append(42);
//     try std.testing.expectEqual(@as(i32, 42), list.pop());
// }
