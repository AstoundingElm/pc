



/*example_test() : i64 
{ 
    return fact_rec(10) == fact_iter(10)
}*/


IntOrPtr : union { i: i64 p: i64* }

f() {
    u1 := IntOrPtr{i = 42}
    u2 := IntOrPtr{p = cast(i64*, 42)}
    u1.i = 0
        u2.p = cast(i64*, 0)
}


i: i64
Vector : struct { x, y: i64 }
fact_iter(n: i64): i64 { r := 1 for i := 2; i <= n; i++ { r *= i } return r }
fact_rec(n: i64): i64 { if (n == 0) { return 1 } else { return n * fact_rec(n-1) } }

/*
//#if 0
f1() { v := Vector{1, 2} j := i i++ j++ v.x = 2*j }
f2(n: i64): i64 { return 2*n }
f3(x: i64): i64 { if (x) { return -x } else if (x % 2 == 0) { return 42 } else { return -1 } }
f4(n: i64): i64 { for i := 0; i < n; i++ { if (i % 3 == 0) { return n } } return 0 }
f5(x: i64): i64 { switch(x) { case 0: case 1: return 42 case 3: default: return -1 } }
f6(n: i64): i64 { p := 1 while (n) { p *= 2 n-- } return p }
f7(n: i64): i64 { p := 1 do { p *= 2 n-- } while (n) return p }
*/
//#endif
n :: = 1+sizeof(p)
p: T*
T : struct { a: i64[n] }