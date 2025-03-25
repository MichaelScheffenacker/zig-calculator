const std = @import("std");
const print = std.debug.print;

const types = @import("types.zig");
const Frac = types.Frac;
const FracOfProducts = types.FracOfProducts;
const Expression = types.Expression;

const fractions = @import("fractions.zig");

const Symbols = types.AppendableSlice(Expression);
var symbolsBuffer: [1024]Expression = undefined;
var symbols: Symbols = undefined;

const Summands = types.AppendableSlice(FracOfProducts);
var summandsBuffer: [64]FracOfProducts = undefined;
var summands: Summands = undefined;

const ParseError = error{ missingOperand, redundantOperator };

var numBuff: [64]i64 = undefined;
var denBuff: [64]i64 = undefined;
var numStart: u64 = 0;
var denStart: u64 = 0;


pub fn init() void {
    symbols = Symbols.init(&symbolsBuffer);
    summands = Summands.init(&summandsBuffer);
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
            symbols = symbols.append(Expression{ .int = number });  // do not forget to assign the return value
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
    var summand = FracOfProducts{ .num = numBuff[0..1], .den = denBuff[0..0] };
    summand.num[0] = factor;
    numStart = 1;
    denStart = 0;

    while (i < symbols.slice.len) {
        operator = symbols.slice[i].op;
        factor = symbols.slice[i + 1].int;

        if (operator == '+' or operator == '-') {
            appendSummand(summand);
            summand = FracOfProducts{ .num = numBuff[numStart .. numStart + 1], .den = denBuff[denStart..denStart] };
            if (operator == '-') {
                factor *= -1;
            }
            summand.num[0] = factor;
        } else {
            if (operator == '*') {
                const pos = summand.num.len;
                summand.num.len += 1;
                summand.num[pos] = factor;
            } else if (operator == '/') {
                const pos = summand.den.len;
                summand.den.len += 1;
                summand.den[pos] = factor;
            }
        }
        i += 2;
    }
    appendSummand(summand);
}

pub fn appendSummand(summand: FracOfProducts) void {
    summands = summands.append(summand);
    numStart += summand.num.len;
    denStart += summand.den.len;
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
    var sum = Frac{ .num = 0, .den = 1 };
    for (summands.slice) |summand| {
        sum = fractions.add(sum, summand.toFrac());
    }
    var num = numBuff[numStart .. numStart + 1];
    var den = denBuff[denStart .. denStart + 1];
    num[0] = sum.num;
    den[0] = sum.den;
    numStart += 1;
    denStart += 1;
    return FracOfProducts{ .num = num, .den = den };
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
