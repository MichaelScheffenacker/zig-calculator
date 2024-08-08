const std = @import("std");
const print = std.debug.print;
const stdin = std.io.getStdIn().reader();

var numBuff:[64]i64 = undefined;
var denBuff:[64]i64 = undefined;
var numStart:u64 = 0;
var denStart:u64 = 0;
const Frac = struct { num:i64, den:i64 };
const PFrac = struct { num: []i64, den: []i64 };
const SummandTag = enum { prod, frac };
const Summand = union(SummandTag) {
    prod: []i64,
    frac: PFrac,
    pub fn printTop(this: Summand) void {
        switch (this) {
            .prod => |prod| for (0..prod.len) |_| { print(" ", .{}); },
            .frac => |frac| printFracNum(frac),
        }
    }
    pub fn printMid(this: Summand) void {
        switch (this) {
            .prod => |prod| printSeparatedSlice(prod, "·"),
            .frac => |frac| for (0..calcFracWidth(frac)) |_| print("-", .{}),
        }
    }
    pub fn printBot(this: Summand) void {
        switch (this) {
            .prod => |prod| for (0..prod.len) |_| print(" ", .{}),
            .frac => |frac| printFracDen(frac),
        }
    }
};
var summandsBuffer: [64]Summand = undefined;
var summands: []Summand = summandsBuffer[0..0];

const ExpressionTag = enum { int, frac, op };
const Expression = union(ExpressionTag) {
    int: i64,
    frac: Frac,
    op: u8,
    pub fn printx(this: Expression) void {
        switch (this) {
            .int => |int| print("{} ", .{int}),
            .frac => |frac| { printFrac(frac); print(" ", .{}); },
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
var symbolsBuffer: [1024]Expression = undefined;
var symbols: []Expression = undefined;
var expressionsBuffer: [1024]Expression = undefined;
var expressions: []Expression = undefined;

const maxInt = std.math.maxInt(i64);
var primes: [1024]u64 = undefined;

var currentFactorization:u64 = 0;
var primeFactorizations: [128][128]u64 = undefined;

const PrimeFacErr = error { miss };
const ParseError = error { missingOperand, redundantOperator };

const Lcm = struct { fac1:u64, fac2:u64 };

var inputBuffer: [128]u8 = undefined;

pub fn main() !void {
    generatePrimes();

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

    const inputs: [2][]const u8 = .{
        "3/4 + 3/-7",
        //"asdf -12/ -88",
        "-12 /-88/7 +5*3",
        //"-12/-88asfd",
        //"12 / 88",
        //"",
        //"12//88",
        //"12/",
    };

    for (inputs) |input| {
        symbols = symbolsBuffer[0..0];
        expressions = expressionsBuffer[0..0];
        summands = summandsBuffer[0..0];

        try parse(input);
        try express();

        parseSummands();

        printExpressionSlice(symbols);
        printExpressionSlice(expressions);
        
        print("\n", .{});
        for (summands, 0..) |summand, i| {
            summand.printTop();
            if (i < summands.len-1) print("   ", .{});
        }
        print("\n", .{});
        for (summands, 0..) |summand, i| {
            summand.printMid();
            if (i < summands.len-1) print(" + ", .{});
        }
        print("\n", .{});
        for (summands, 0..) |summand, i| {
            summand.printBot();
            if (i < summands.len-1) print("   ", .{});
        }
        print("\n", .{});
        print("\n", .{});
        print("\n", .{});
    }
}

fn calcSliceWidth(factors: []i64) u64 {
    var w = factors.len - 1;  // space for multiplication signs
    for (factors) |factor| {
        var x = factor;
        if (x < 0) {
            w += 1;  // space for minus sign
        }
        while (x != 0) {
            w += 1;  // space for digits
            x = @divTrunc(x, 10);  // optimization potential: logarithm
        }
    }
    return w;
}

fn max(a: u64, b: u64) u64 {
    return if (a > b) a else b;
}

fn printFracNum(x: PFrac) void {
    const numWidth = calcSliceWidth(x.num);
    const width = calcFracWidth(x);
    const preWidth = (width - numWidth) / 2;
    const postWidth = width - numWidth - preWidth;
    for (0..preWidth) |_| { print(" ", .{}); }
    printSeparatedSlice(x.num, "·");
    for (0..postWidth) |_| { print(" ", .{}); }
}

fn printFracDen(x: PFrac) void {
    const denWidth = calcSliceWidth(x.den);
    const width = calcFracWidth(x);
    const preWidth = (width - denWidth) / 2;
    const postWidth = width - denWidth - preWidth;
    for (0..preWidth) |_| { print(" ", .{}); }
    printSeparatedSlice(x.den, "·");
    for (0..postWidth) |_| { print(" ", .{}); }
}

fn calcFracWidth(x: PFrac) u64 {
    const numWidth = calcSliceWidth(x.num);
    const denWidth = calcSliceWidth(x.den);
    return max(numWidth, denWidth);
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
    const width =  max(u.frac.num.len, u.frac.den.len);
    const len = width * 2 - 1;
    for (0..len) |_| {
        print("—", .{});
    }
    print("\n", .{});
    printSeparatedSlice(u.frac.den, "·");
    print("\n", .{});
}

fn parseSummands() void {
    if (symbols.len == 0) {
        return;
    }
    var operator:u8 = 0;
    var factor = symbols[0].int;
    var i:u64 = 1;
    var summand = PFrac{ .num = numBuff[0..1], .den = denBuff[0..0] };
    summand.num[0] = factor;
    numStart = 1;
    denStart = 0;
    
    while (i < symbols.len) {
        operator = symbols[i].op;
        factor = symbols[i+1].int;

        if (operator == '+' or operator == '-') {
            appendSummand(summand);
            summand = PFrac{
                .num = numBuff[numStart..numStart + 1],
                .den = denBuff[denStart..denStart]
            };
            summand.num[0] = factor;
        } else {
            if (operator == '*') {
                const pos = summand.num.len;
                summand.num.len += 1;
                summand.num[pos] = factor;
            }
            else if (operator == '/') {
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
    //print("asdf", .{});
    summands.len += 1;
    if (summand.den.len == 0) {
        summands[pos] = Summand { .prod = summand.num };
    } else {
        summands[pos] = Summand { .frac = summand };
    }
    numStart = summand.num.len;
    denStart = summand.den.len;
}

fn express() !void {
    var i:u64 = 0;
    while (i < symbols.len) {
        const symbol = symbols[i];
        if (symbol.isDivisionOperator()) {  // fraction after fraction will cause a bug rn
            var num = symbols[i-1].int;
            var den = symbols[i+1].int;
            if (den < 0) {
                num *= -1;
                den *= -1;
            }
            const reducedFrac = try reduceFrac( Frac{ .num = num, .den = den } );
            expressions[expressions.len - 1] = Expression{ .frac = reducedFrac };
            i += 1;  // fraction takes symbols at i-1, i, i+1 and puts it instead of last expression
        } else {
            appendExpression(symbol);
        }
        i += 1;
    }
}

fn parse(string: []const u8) !void {
    var runIndex:u64 = 0;
    var isOperatorPosition = false;
    var sign: i2 = 1;
    while (runIndex < string.len) {

        if (isDigitSymbol( string[runIndex] )) {
            const number = sign * parseNumber(string, &runIndex);
            append(Expression{ .int = number });
            isOperatorPosition = true;
            sign = 1;
        }
        if (isOperatorSymbol( string[runIndex] )) {
            if (isOperatorPosition) {
                append(Expression{ .op = string[runIndex] });
                isOperatorPosition = false;
            } else if (isSignSymbol( string[runIndex] )) {
                if (string[runIndex] == '-') {
                    sign = sign * -1;
                }
            }
            else {
                return ParseError.redundantOperator;
            }            
        }
        runIndex += 1;
    }

    if (symbols.len > 0) {
        switch (symbols[symbols.len - 1]) {
            .int => {},
            .frac => {},
            .op => { return ParseError.missingOperand; },
        }
    }
}

fn parseNumber(string:[]const u8, runIndex:*u64) i64 {
    var num:i64 = 0;
    while (true) {
        const char = string[runIndex.*];
        if (!isDigitSymbol(char)) break;
        const digit = char - '0';
        num = num * 10 + digit;
        
        if (runIndex.* + 1 >= string.len) break; // index is running between parsing functions; ...
        runIndex.* += 1;                         // ... special care is required.
    }
    return num;
}

fn append(value:Expression) void {
    const pos = symbols.len;
    symbols.len += 1;
    symbols[pos] = value;
}

fn appendExpression(value:Expression) void {
    const pos = expressions.len;
    expressions.len += 1;
    expressions[pos] = value;
}
//fn appedX(value:i64) void {
//    const pos = x

fn isDigitSymbol(symbol: u8) bool {
    return (symbol >= '0' and symbol <= '9');
}

fn isOperatorSymbol(symbol: u8) bool {
    return (symbol == '/' or symbol == '*' or isSignSymbol(symbol));
}

fn isSignSymbol(symbol: u8) bool {
    return (symbol == '+' or symbol == '-');
}

fn add(a:Frac, b:Frac) Frac {
    const c = Frac{ .num = a.num + b.num, .den = a.den };
    return c;
}

fn normalize(a:Frac, pLcmFac:u64) Frac {
    const lcmFac:u63 = @intCast(pLcmFac);
    return Frac{ .num = a.num * lcmFac, .den = a.den * lcmFac };
}

fn reduceFrac(a:Frac) !Frac {
    const factorsNum = try primeFactorize(a.num);
    const factorsDen = try primeFactorize(a.den);
    const gcd:u63 = @intCast( calcGcd(factorsNum, factorsDen) );
    return Frac{ .num = @divTrunc(a.num, gcd), .den = @divTrunc(a.den, gcd) };
}

fn printFrac(a: Frac) void {
    std.debug.print("{}/{}", .{a.num, a.den});
}

fn printFac(number:u64, factors:[]u64) void {
    print("{} = ", .{number});
    for (factors) |p| { print( "{}·", .{p}); }
    print("\n", .{});
}

fn printSeparatedSlice(slice:[]i64, comptime separator: []const u8) void {
    for (slice, 0..) |element, i| {
        print("{}", .{element});
        if (i < slice.len-1) print(separator, .{});
    }
}

fn generatePrimes() void {
    primes[0] = 2;
    var i:u64 = 3;
    var p:u64 = 1;
    while (p < primes.len) : (i += 1) {
        var q:u64 = 0;
        while (q < p) : (q += 1) {
            if (i % primes[q] == 0)  { break; }
        }
        if (q == p) {  // q is incremented one last time when the loop finishes.
            primes[p] = i;
            p += 1;
        }
    }
    
    // for (primes[0..8]) |prime| { print("{} ", .{prime}); }
    // print("... ", .{});
    // for (primes[1018..]) |prime| { print("{} ", .{prime}); }
    // print("\n", .{});
}

fn primeFactorize(number: i64) ![]u64 {
    const abs = if (number < 0) number * -1 else number;
    var facs:[]u64 = primeFactorizations[currentFactorization][0..];
    currentFactorization += 1;
    var n:u64 = @intCast(abs);
    for (facs, 0..) |*fac, i| {
        for (primes) |prime| {
            if (n % prime == 0) {
                n = n / prime;
                fac.* = prime;
                break;
            }
            if (n == 1) {
                facs = facs[0..i];
                // printFac(number, facs);
                return facs;
            }
            if (prime > n) { return PrimeFacErr.miss; }
            
        }
    }
    return PrimeFacErr.miss;
}

fn calcLcm(factors1:[]u64, factors2:[]u64) Lcm {
    var lcm:Lcm = .{.fac1 = 1, .fac2 = 1};
    var index1:u64 = 0;
    var index2:u64 = 0;
    while (true) {
        const val1:u64 = if (index1 < factors1.len) factors1[index1] else maxInt;
        const val2:u64 = if (index2 < factors2.len) factors2[index2] else maxInt;

        // print("{} {}\n", .{lcm.fac1, lcm.fac2});
        
        if (val1 == maxInt and val2 == maxInt) {  return lcm; }
                
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

fn calcGcd(factors1:[]u64, factors2:[]u64) u64 {
    var gcd:u64 = 1;
    var index1:u64 = 0;
    var index2:u64 = 0;
    while (true) {
        const val1:u64 = if (index1 < factors1.len) factors1[index1] else maxInt;
        const val2:u64 = if (index2 < factors2.len) factors2[index2] else maxInt;

        // print("{} {} {} {} {} \n", .{index1, index2, val1, val2, gcd});

        if (val1 == maxInt and val2 == maxInt) {  return gcd; }

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

test "simple test" {
    //try std.testing.expectEqual(@as(i32, 42), list.pop());
}
