const std = @import("std");
const print = std.debug.print;
const stdin = std.io.getStdIn().reader();

const Frac = struct { num:u64, den:u64 };
const ExpressionSymbolTag = enum { int, frac, op };
const ExpressionSymbol = union(ExpressionSymbolTag) {
    int: i64,
    frac: Frac,
    op: u8,
};
var expressionSymbolsBuffer: [1024]ExpressionSymbol = undefined;
var expressionSymbols: []ExpressionSymbol =  expressionSymbolsBuffer[0..0];

const maxInt = std.math.maxInt(u64);
var primes: [1024]u64 = undefined;

var currentFactorization:u64 = 0;
var primeFactorizations: [128][128]u64 = undefined;

const PrimeFacErr = error { miss };

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
    const input = "asdf -12/ -88";
    //if (inputResult) |input| {
        parse(input);
    //}
    
}

fn parse(input: []const u8) void {
    var num:i64 = 0;
    var den:i64 = 0;
    var i:u64 = 0;
    var symbol:u8 = undefined;
    while (i < input.len) {
        symbol = input[i];

        if (isNumberSymbol(symbol)) {
            append(ExpressionSymbol{ .int = parseNumber(input, &i, &symbol) });
        }

        //print("{} {c}\n", .{i, symbol});
        i += 1;
    }
    num = expressionSymbols[0].int;
    den = expressionSymbols[1].int;
    print("num: {}   den: {}\n", .{num, den});
}

fn parseNumber(input:[]const u8, i:*u64, symbol:*u8 ) i64 {
    var num:i64 = 0;
    var sig:i2 = 1;
    var start: bool = true;
    while (i.* < input.len) {
        symbol.* = input[i.*];

        if (start) {
            start = false;
            if (symbol.* == '-') {
                sig = -1;
            }
        } else if (isDigitSymbol(symbol.*)) {
            const digit = symbol.* - '0';
            num = num * 10 + digit;
        } else {
            return num * sig;
        }
        
        i.* += 1;
    }
    return num * sig;
}

fn append(value :ExpressionSymbol) void {
    const pos = expressionSymbols.len;
    expressionSymbols.len += 1;
    expressionSymbols[pos] = value;
}

fn isDigitSymbol(symbol: u8) bool {
    return (symbol >= '0' and symbol <= '9');
}

fn isNumberSymbol(symbol: u8) bool {
    return (symbol == '-' or isDigitSymbol(symbol));
}

fn add(a:Frac, b:Frac) Frac {
    const c = Frac{ .num = a.num + b.num, .den = a.den };
    return c;
}

fn normalize(a:Frac, lcmFac:u64) Frac {
    return Frac{ .num = a.num * lcmFac, .den = a.den * lcmFac };
}

fn reduceFrac(a:Frac) !Frac {
    const factorsNum = try primeFactorize(a.num);
    const factorsDen = try primeFactorize(a.den);
    const gcd:u64 = calcGcd(factorsNum, factorsDen);
    return Frac{ .num = a.num / gcd, .den = a.den / gcd };
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

fn primeFactorize(number: u64) ![]u64 {
    var facs:[]u64 = primeFactorizations[currentFactorization][0..];
    currentFactorization += 1;
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
