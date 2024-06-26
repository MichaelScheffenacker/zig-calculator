const std = @import("std");
const print = std.debug.print;
const stdin = std.io.getStdIn().reader();

const Frac = struct { num:i64, den:i64 };

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
    
    const a = Frac{ .num = 5, .den = 8 };
    const b = Frac{ .num = 3, .den = 12 };
    const factorsA = try primeFactorize(a.den);
    const factorsB = try primeFactorize(b.den);
    const lcm:Lcm = calcLcm(factorsA, factorsB);
    const aNorm = normalize(a, lcm.fac1);
    const bNorm = normalize(b, lcm.fac2);
    
    const c = add(aNorm, bNorm);
    const cReduced = try reduceFrac(c);

    print("\n", .{});

    printFrac(a);
    print(" + ", .{});
    printFrac(b);
    print(" = ", .{});
    printFrac(aNorm);
    print(" + ", .{});
    printFrac(bNorm);
    print(" = ", .{});
    
    printFrac(c);
    print(" = ", .{});
    printFrac(cReduced);

    print("\n", .{});

    
    //const inputResult = stdin.readUntilDelimiterOrEof(inputBuffer[0..], '\n') catch null;
    //if (inputResult) |input| {

    const inputs: [6][]const u8 = .{
        "3/4 + -3/7",
        "asdf -12/ -88",
        "asdf-12 /-88 ",
        "-12/-88asfd",
        "12 / 88",
        "",
        //"12//88",
        //"12/",
    };

    for (inputs) |input| {
        symbols = symbolsBuffer[0..0];
        expressions = expressionsBuffer[0..0];

        try parse(input);

        express();

        printExpressionSlice(symbols);
        printExpressionSlice(expressions);
    }
}

fn printExpressionSlice(slice: []Expression) void {
    for (slice) |element| {
        element.printx();
    }
    print("\n", .{});
}

fn express() void {
    var i:u64 = 0;
    while (i < symbols.len) {
        const symbol = symbols[i];
        if (symbol.isDivisionOperator()) {  // fraction after fraction will cause a bug rn
            const frac = Frac{ .num = symbols[i-1].int, .den = symbols[i+1].int };
            expressions[expressions.len - 1] = Expression{ .frac = frac };
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
    var facs:[]u64 = primeFactorizations[currentFactorization][0..];
    currentFactorization += 1;
    var n:u64 = @intCast(number);
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
