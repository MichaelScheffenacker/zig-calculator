const std = @import("std");
const print = std.debug.print;
const stdin = std.io.getStdIn().reader();
const zigTime = std.time;

const parser = @import("parser.zig");
const primes = @import("primes.zig");

comptime {
    _ = @import("primes.zig");
}

var inputBuffer: [128]u8 = undefined;


pub fn main() !void {
    var timer: std.time.Timer = try std.time.Timer.start();
    time(&timer);
    primes.generate();

    time(&timer);

    parser.showcases();
    
    //const inputResult = stdin.readUntilDelimiterOrEof(inputBuffer[0..], '\n') catch null;
    //if (inputResult) |input| {

    const inputs: [3][]const u8 = .{
        "3/4 + 3/-7",
        "-1/4 + 1/4 - 1/8 - 7/8",
        "-12 /-88/7 +5*3+1*8/4/5",
        //"-12/-88asfd",
        //"12 / 88",
        //"",
        //"12//88",
        //"12/",
    };

    for (inputs) |input| {
        parser.init();
        
        try parser.parse(input);
        parser.parseSummands();
        parser.printSymbols();

        const result = parser.calculateResult();
        parser.printCalculation(result);

        print("\n", .{});
        print("\n", .{});
    }

    print("   78   \n", .{});
    print("——————     78       78  \n", .{});
    print(" _____  ————————  —=====\n", .{});
    print("√12*45  √(12*45)  √12*45\n", .{});
    print("\n", .{});

}

fn time(timer: *std.time.Timer) void {
    print("{}\n", .{timer.lap()});
}
