const std = @import("std");
const print = std.debug.print;

const types = @import("types.zig");
const Frac = types.Frac;
const PFrac = types.PFrac;
const Expression = types.Expression;
const Summand = types.Summand;
const Lcm = types.Lcm;

const primes = @import("primes.zig");

const Symbols = types.AppendableSlice(Expression);
var symbolsBuffer: [1024]Expression = undefined;
var symbols: Symbols = undefined;
var summandsBuffer: [64]Summand = undefined;
var summands: []Summand = summandsBuffer[0..0];

const ParseError = error{ missingOperand, redundantOperator };

var numBuff: [64]i64 = undefined;
var denBuff: [64]i64 = undefined;
var numStart: u64 = 0;
var denStart: u64 = 0;


pub fn init() void {
    symbols = Symbols.init(&symbolsBuffer);
    summands = summandsBuffer[0..0];
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
    var summand = PFrac{ .num = numBuff[0..1], .den = denBuff[0..0] };
    summand.num[0] = factor;
    numStart = 1;
    denStart = 0;

    while (i < symbols.slice.len) {
        operator = symbols.slice[i].op;
        factor = symbols.slice[i + 1].int;

        if (operator == '+' or operator == '-') {
            appendSummand(summand);
            summand = PFrac{ .num = numBuff[numStart .. numStart + 1], .den = denBuff[denStart..denStart] };
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

pub fn appendSummand(summand: PFrac) void {
    const pos = summands.len;
    summands.len += 1;
    if (summand.den.len == 0) {
        summands[pos] = Summand{ .prod = summand.num };
    } else {
        summands[pos] = Summand{ .frac = summand };
    }
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


pub fn calculateResult() Summand {
    var sum = Frac{ .num = 0, .den = 1 };
    for (summands) |summand| {
        var defaultFactors = [_]u64{ 1, 1 }; // of course this error handling is dysfunctional
        const sumFactors = primes.factorize(sum.den) catch defaultFactors[0..];
        const summandFactors = primes.factorize(summand.normal().den) catch defaultFactors[0..];
        const lcm: Lcm = primes.calcLcm(sumFactors, summandFactors);
        const normSum = normalize(sum, lcm.fac1);
        const normSummand = normalize(summand.normal(), lcm.fac2);
        sum = add(normSum, normSummand);
    }
    const reducedSum = primes.reduceFrac(sum);
    var num = numBuff[numStart .. numStart + 1];
    var den = denBuff[denStart .. denStart + 1];
    num[0] = reducedSum.num;
    den[0] = reducedSum.den;
    numStart += 1;
    denStart += 1;
    return if (den[0] == 1) Summand{ .prod = num } else Summand{ .frac = PFrac{ .num = num, .den = den } };
}

pub fn printCalculation(sum: Summand) void {
    print("\n", .{});
    for (summands, 0..) |summand, i| {
        summand.printTop();
        if (i < summands.len - 1) print("   ", .{});
    }
    print("   ", .{});
    sum.printTop();

    print("\n", .{});
    for (summands, 0..) |summand, i| {
        summand.printMid();
        if (i < summands.len - 1) print(" + ", .{});
    }
    print(" = ", .{});
    sum.printMid();

    print("\n", .{});
    for (summands, 0..) |summand, i| {
        summand.printBot();
        if (i < summands.len - 1) print("   ", .{});
    }
    print("   ", .{});
    sum.printBot();

    print("\n", .{});
}

fn add(a: Frac, b: Frac) Frac {
    const c = Frac{ .num = a.num + b.num, .den = a.den };
    return c;
}

fn normalize(a: Frac, pLcmFac: u64) Frac {
    const lcmFac: u63 = @intCast(pLcmFac);  //todo: cleanup
    return Frac{ .num = a.num * lcmFac, .den = a.den * lcmFac };
}

pub fn showcases() !void {
    const a = Frac{ .num = 5, .den = 8 };
    const b = Frac{ .num = 3, .den = 12 };
    const factorsA = try primes.factorize(a.den);
    const factorsB = try primes.factorize(b.den);
    const lcm:Lcm = primes.calcLcm(factorsA, factorsB);
    const aNorm = normalize(a, lcm.fac1);
    const bNorm = normalize(b, lcm.fac2);

    const c = add(aNorm, bNorm);
    const cReduced = primes.reduceFrac(c);

    print("\n", .{});

    types.printFrac(a);
    print(" + ", .{});
    types.printFrac(b);
    print(" = ", .{});
    types.printFrac(aNorm);
    print(" + ", .{});
    types.printFrac(bNorm);
    print(" = ", .{});

    types.printFrac(c);
    print(" = ", .{});
    types.printFrac(cReduced);

    print("\n", .{});
}

fn printFac(number: u64, factors: []u64) void {
    print("{} = ", .{number});
    for (factors) |p| {
        print("{}·", .{p});
    }
    print("\n", .{});
}
