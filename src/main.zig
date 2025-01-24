const std = @import("std");
const print = std.debug.print;
const stdin = std.io.getStdIn().reader();
const zigTime = std.time;
const expect = std.testing.expect;

fn AppendableSlice(comptime T: type) type { // to create a generic (struct) a function returning generic Type is required ...
    return struct { // ... this leads to utilization of an anonymous struct ...
        const This = @This(); // ... therefore instead of referencing the scruct by name the builtin function @This() is used.
        slice: []T,
        pub fn init(buffer: []T) This { // Since Zig requires arrays sizes to be known at compile time, passing it by reference is required ...
            return This{ .slice = buffer[0..0] }; // ... here; for some reason a slice and can be used as such reference.
        }
        pub fn append(this: This, value: T) This {
            var slice = this.slice;
            const pos = slice.len;
            slice.len += 1;
            slice[pos] = value;
            return This{ .slice = slice };
        }
    };
}

var numBuff: [64]i64 = undefined;
var denBuff: [64]i64 = undefined;
var numStart: u64 = 0;
var denStart: u64 = 0;
const Frac = struct { num: i64, den: i64 };
const PFrac = struct { num: []i64, den: []i64 };

const ExpressionTag = enum { int, frac, op };
const Expression = union(ExpressionTag) {
    int: i64,
    frac: Frac,
    op: u8,
    pub fn printx(this: Expression) void {
        switch (this) {
            .int => |int| print("{} ", .{int}),
            .frac => |frac| {
                printFrac(frac);
                print(" ", .{});
            },
            .op => |op| print("{c} ", .{op}),
        }
    }
    pub fn isDivisionOperator(this: Expression) bool {
        return switch (this) {
            .int => false,
            .frac => false,
            .op => |operator| operator == '/',
        };
    }
};

const SummandTag = enum { prod, frac };
const Summand = union(SummandTag) {
    prod: []i64,
    frac: PFrac,
    pub fn printTop(this: Summand) void {
        switch (this) {
            .prod => |prod| for (0..calcSliceWidth(prod)) |_| {
                print(" ", .{});
            },
            .frac => |frac| printFracNum(frac),
        }
    }
    pub fn printMid(this: Summand) void {
        switch (this) {
            .prod => |prod| printSeparatedSlice(prod, "·"),
            .frac => |frac| for (0..calcFracWidth(frac)) |_| print("—", .{}),
        }
    }
    pub fn printBot(this: Summand) void {
        switch (this) {
            .prod => |prod| for (0..calcSliceWidth(prod)) |_| print(" ", .{}),
            .frac => |frac| printFracDen(frac),
        }
    }
    pub fn normal(this: Summand) Frac {
        switch (this) {
            .prod => |prod| return Frac{ .num = multiplyFactors(prod), .den = 1 },
            .frac => |frac| return pFracToNormalizedFrac(frac),
        }
    }
};

const Symbols = AppendableSlice(Expression);
var symbolsBuffer: [1024]Expression = undefined;
var symbols: Symbols = undefined;
var summandsBuffer: [64]Summand = undefined;
var summands: []Summand = summandsBuffer[0..0];

const maxInt = std.math.maxInt(i64);
var primes: [1024]u64 = undefined;

var currentFactorization: u64 = 0;
var primeFactorizations: [128][128]u64 = undefined;

const PrimeFacErr = error{miss};
const ParseError = error{ missingOperand, redundantOperator };

const Lcm = struct { fac1: u64, fac2: u64 };

var inputBuffer: [128]u8 = undefined;

pub fn main() !void {
    var timer: std.time.Timer = try std.time.Timer.start();
    time(&timer);
    generatePrimes();
    time(&timer);

    // const a = Frac{ .num = 5, .den = 8 };
    // const b = Frac{ .num = 3, .den = 12 };
    // const factorsA = try primeFactorize(a.den);
    // const factorsB = try primeFactorize(b.den);
    // const lcm:Lcm = calcLcm(factorsA, factorsB);
    // const aNorm = normalize(a, lcm.fac1);
    // const bNorm = normalize(b, lcm.fac2);

    // const c = add(aNorm, bNorm);
    // const cReduced = try reduceFrac(c);

    // print("\n", .{});

    // printFrac(a);
    // print(" + ", .{});
    // printFrac(b);
    // print(" = ", .{});
    // printFrac(aNorm);
    // print(" + ", .{});
    // printFrac(bNorm);
    // print(" = ", .{});

    // printFrac(c);
    // print(" = ", .{});
    // printFrac(cReduced);

    // print("\n", .{});

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
        symbols = Symbols.init(&symbolsBuffer);
        summands = summandsBuffer[0..0];

        try parse(input);
        parseSummands();

        printExpressionSlice(symbols.slice);
        const result = calculateResult();
        printCalculation(result);

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

fn pFracToNormalizedFrac(frac: PFrac) Frac {
    const reducedFrac = Frac{
        .num = multiplyFactors(frac.num),
        .den = multiplyFactors(frac.den),
    };
    const signedFrac = if (reducedFrac.den < 0)
        Frac{
            .num = -1 * reducedFrac.num,
            .den = -1 * reducedFrac.den,
        }
    else
        reducedFrac;
    return reduceFrac(signedFrac) catch signedFrac;
}

fn multiplyFactors(factors: []i64) i64 {
    var product: i64 = 1;
    for (factors) |factor| {
        product *= factor;
    }
    return product;
}

fn max(a: u64, b: u64) u64 {
    return if (a > b) a else b;
}

fn calculateResult() Summand {
    var sum = Frac{ .num = 0, .den = 1 };
    for (summands) |summand| {
        var defaultFactors = [_]u64{ 1, 1 }; // of course this error handling is dysfunctional
        const sumFactors = primeFactorize(sum.den) catch defaultFactors[0..];
        const summandFactors = primeFactorize(summand.normal().den) catch defaultFactors[0..];
        const lcm: Lcm = calcLcm(sumFactors, summandFactors);
        const normSum = normalize(sum, lcm.fac1);
        const normSummand = normalize(summand.normal(), lcm.fac2);
        sum = add(normSum, normSummand);
    }
    const reducedSum = reduceFrac(sum) catch sum;
    var num = numBuff[numStart .. numStart + 1];
    var den = denBuff[denStart .. denStart + 1];
    num[0] = reducedSum.num;
    den[0] = reducedSum.den;
    numStart += 1;
    denStart += 1;
    return if (den[0] == 1) Summand{ .prod = num } else Summand{ .frac = PFrac{ .num = num, .den = den } };
}

fn printCalculation(sum: Summand) void {
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

fn printFracNum(frac: PFrac) void {
    printFracElement(frac, frac.num);
}

fn printFracDen(frac: PFrac) void {
    printFracElement(frac, frac.den);
}

fn printFracElement(frac: PFrac, element: []i64) void {
    const elementWidth = calcSliceWidth(element);
    const width = calcFracWidth(frac);
    const preWidth = (width - elementWidth) / 2;
    const postWidth = width - elementWidth - preWidth;
    for (0..preWidth) |_| {
        print(" ", .{});
    }
    printSeparatedSlice(element, "·");
    for (0..postWidth) |_| {
        print(" ", .{});
    }
}

fn calcFracWidth(x: PFrac) u64 {
    const numWidth = calcSliceWidth(x.num);
    const denWidth = calcSliceWidth(x.den);
    return max(numWidth, denWidth);
}

fn calcSliceWidth(factors: []i64) u64 {
    var w = factors.len - 1; // space for multiplication signs
    for (factors) |factor| {
        var x = factor;
        if (x < 0) {
            w += 1; // space for minus sign
        }
        while (x != 0) {
            w += 1; // space for digits
            x = @divTrunc(x, 10); // optimization potential: logarithm
        }
    }
    return w;
}

fn printExpressionSlice(slice: []Expression) void {
    for (slice) |element| {
        element.printx();
    }
    print("\n", .{});
}

fn printSummand(u: Summand) void {
    printSeparatedSlice(u.frac.num, "·");
    print("\n", .{});
    const width = max(u.frac.num.len, u.frac.den.len);
    const len = width * 2 - 1;
    for (0..len) |_| {
        print("—", .{});
    }
    print("\n", .{});
    printSeparatedSlice(u.frac.den, "·");
    print("\n", .{});
}

fn parseSummands() void {
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

fn appendSummand(summand: PFrac) void {
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

fn parse(string: []const u8) !void {
    var runIndex: u64 = 0;
    var isOperatorPosition = false;
    var sign: i2 = 1;
    while (runIndex < string.len) {
        if (isDigitSymbol(string[runIndex])) {
            const number = sign * parseNumber(string, &runIndex);
            append(Expression{ .int = number });
            isOperatorPosition = true;
            sign = 1;
        }
        if (isOperatorSymbol(string[runIndex])) {
            if (isOperatorPosition) {
                append(Expression{ .op = string[runIndex] });
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

fn append(value: Expression) void {
    const pos = symbols.slice.len;
    symbols.slice.len += 1;
    symbols.slice[pos] = value;
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

fn add(a: Frac, b: Frac) Frac {
    const c = Frac{ .num = a.num + b.num, .den = a.den };
    return c;
}

fn normalize(a: Frac, pLcmFac: u64) Frac {
    const lcmFac: u63 = @intCast(pLcmFac);
    return Frac{ .num = a.num * lcmFac, .den = a.den * lcmFac };
}

fn reduceFrac(a: Frac) !Frac {
    const factorsNum = try primeFactorize(a.num);
    const factorsDen = try primeFactorize(a.den);
    const gcd: u63 = @intCast(calcGcd(factorsNum, factorsDen));
    return Frac{ .num = @divTrunc(a.num, gcd), .den = @divTrunc(a.den, gcd) };
}

fn printFrac(a: Frac) void {
    std.debug.print("{}/{}", .{ a.num, a.den });
}

fn printFac(number: u64, factors: []u64) void {
    print("{} = ", .{number});
    for (factors) |p| {
        print("{}·", .{p});
    }
    print("\n", .{});
}

fn printSeparatedSlice(slice: []i64, comptime separator: []const u8) void {
    for (slice, 0..) |element, i| {
        print("{}", .{element});
        if (i < slice.len - 1) print(separator, .{});
    }
}

fn generatePrimes() void {
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

fn primeFactorize(number: i64) ![]u64 {
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

fn calcLcm(factors1: []u64, factors2: []u64) Lcm {
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

fn calcGcd(factors1: []u64, factors2: []u64) u64 {
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

test "AppendableSlice test" {
    var buff: [8]i8 = undefined;
    var slice = AppendableSlice(i8).init(&buff);
    slice = slice.append(2);
    slice = slice.append(3);
    try expect(slice.slice[0] == 2);
    try expect(slice.slice[1] == 3);
}

test "prime array test" {
    generatePrimes();
    try expect(primes[0] == 2);
    try expect(primes[1] == 3);
    try expect(primes[2] == 5);
    try expect(primes[1021] == 8123);
    try expect(primes[1022] == 8147);
    try expect(primes[1023] == 8161);
}
