x : i64


Vector : struct 
{
    x : i64
        b : i64
}
/*

x, y : i64


print(v : Vector) 
{
    printf("{%d, %d}", v.x, v.y);
}


add(v: Vector, w: Vector): Vector 
{ 
    return {v.x + w.x, v.y + w.y} 
}

x := add({1,2}, {3,4})


"var w = Vector{3,4}",
"var p: void*",
"var i = cast(int, p) + 1",


a: i64[3] = {1,2,3}
b: i64[4]
p = &a[1]
i = p[1]
j = *p
*/

n := sizeof(a)
/*
"const m = sizeof(&a[0])",
"const l = sizeof(1 ? a : b)",
*/

pi := 3.14
name := 'Pete'
i := 42
/*
v = Vector{1,2}
"const a = 1000/((2*3-5) << 1)",
"const b = !0",
"const c = ~100 + 1 == -100",
"const k = 1 ? 2 : 3",
"union IntOrPtr { i: int; p: int*; }",*/
i := 42

/*
"var u = IntOrPtr{i, &i}",
const n = 1+sizeof(p)",
"var p: T*",
"var u = *p",
"struct T { a: int[n]; }",
"var r = &t.a",*/
t : T

/*
"typedef S = int[n+m]",
"const m = sizeof(t.a)",*/
i := n+m

/*
"var q = &i",

"const n = sizeof(x)",*/
x: T

/*
"struct T { s: S*; }",
"struct S { t: T[n]; }",
*/





