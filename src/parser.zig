const std = @import("std");
const print = std.debug.print;

const types = @import("types.zig");
const Frac = types.Frac;
const FracOfProducts = types.FracOfProducts;
const Expression = types.Expression;

var symbols: types.Symbols = undefined;
var summands: types.Summands = undefined;

const fractions = @import("fractions.zig");

const ParseError = error{ missingOperand, redundantOperator };

pub fn init() void {
    symbols = types.Symbols.new();
    summands = types.Summands.new();
}

pub fn printSymbols() void {
    symbols.printSlice();
}
pub fn parse(string: []const u8) !void {
    var runIndex: u64 = 0;
    var isOperatorPosition = false;
    var sign: i2 = 1;
    while (runIndex < string.len) {
        if (isDigitSymbol(string[runIndex])) {
            const number = sign * parseNumber(string, &runIndex);
            symbols = symbols.append(Expression{ .int = number }); // do not forget to assign the return value
            isOperatorPosition = true;
            sign = 1;
        }
        if (isOperatorSymbol(string[runIndex])) {
            if (isOperatorPosition) {
                symbols = symbols.append(Expression{ .op = string[runIndex] });
                isOperatorPosition = false;
            } else if (isSignSymbol(string[runIndex])) {
                if (string[runIndex] == '-') {
                    sign = sign * -1;
                }
            } else {
                return ParseError.redundantOperator;
            }
        }
        runIndex += 1;
    }

    if (symbols.slice.len > 0) {
        switch (symbols.slice[symbols.slice.len - 1]) {
            .int => {},
            .frac => {},
            .op => {
                return ParseError.missingOperand;
            },
        }
    }
}

pub fn parseSummands() void {
    if (symbols.slice.len == 0) {
        return;
    }
    var operator: u8 = 0;
    var factor = symbols.slice[0].int;
    var i: u64 = 1;
    var summand = FracOfProducts.init();
    summand = summand.appendNum(factor);

    while (i < symbols.slice.len) {
        operator = symbols.slice[i].op;
        factor = symbols.slice[i + 1].int;

        if (operator == '+' or operator == '-') {
            summands, summand = summands.append(summand);
            factor *= if (operator == '-') -1 else 1;
            summand = summand.appendNum(factor);
        } else {
            if (operator == '*') {
                summand = summand.appendNum(factor);
            } else if (operator == '/') {
                summand = summand.appendDen(factor);
            }
        }
        i += 2;
    }
    summands, summand = summands.append(summand);
}

fn parseNumber(string: []const u8, runIndex: *u64) i64 {
    var num: i64 = 0;
    while (true) {
        const char = string[runIndex.*];
        if (!isDigitSymbol(char)) break;
        const digit = char - '0';
        num = num * 10 + digit;

        if (runIndex.* + 1 >= string.len) break; // index is running between parsing functions; ...
        runIndex.* += 1; // ... special care is required.
    }
    return num;
}

fn isDigitSymbol(symbol: u8) bool {
    return (symbol >= '0' and symbol <= '9');
}

fn isOperatorSymbol(symbol: u8) bool {
    return (symbol == '/' or symbol == '*' or isSignSymbol(symbol));
}

fn isSignSymbol(symbol: u8) bool {
    return (symbol == '+' or symbol == '-');
}

pub fn calculateResult() FracOfProducts {
    return summands.calculateSum();
}

pub fn printCalculation(sum: FracOfProducts) void {
    print("\n", .{});
    for (summands.slice, 0..) |summand, i| {
        summand.printTop();
        if (i < summands.slice.len - 1) print("   ", .{});
    }
    print("   ", .{});
    sum.printTop();

    print("\n", .{});
    for (summands.slice, 0..) |summand, i| {
        summand.printMid();
        if (i < summands.slice.len - 1) print(" + ", .{});
    }
    print(" = ", .{});
    sum.printMid();

    print("\n", .{});
    for (summands.slice, 0..) |summand, i| {
        summand.printBot();
        if (i < summands.slice.len - 1) print("   ", .{});
    }
    print("   ", .{});
    sum.printBot();

    print("\n", .{});
}

pub fn showcases() void {
    const a = Frac{ .num = 5, .den = 8 };
    const b = Frac{ .num = 3, .den = 12 };
    const c = fractions.add(a, b);

    print("\n", .{});

    types.printFrac(a);
    print(" + ", .{});
    types.printFrac(b);
    print(" = ", .{});
    types.printFrac(c);

    print("\n", .{});
}

fn printFac(number: u64, factors: []u64) void {
    print("{} = ", .{number});
    for (factors) |p| {
        print("{}·", .{p});
    }
    print("\n", .{});
}
