i : i64 = 99
Vector : struct {
    x ,  y : i64
}


f1(a : i64, b : i64, k : i64) 
{ 
    
    v := Vector{1, 2}
    j := i
        
        i++
        j++
        
        v.x = 2*j
}



f2(a : i64, c : i64) 
{ 
    
    v := Vector{1, 2}
    j := i
        i++
        j++
        
        v.x = 2*j
}



f2(n: i64): i64 { 
    return 2*n
}



f3(x: i64): i64 
{ if (x) 
    { 
        return -x
    } 
    else if (x % 2 == 0) 
    { 
        return 42
    } 
    else 
    { 
        return -1
    } 
}


f4(n: i64): i64 
{ 
    for i := 0; i < n; i++
    { 
        if(i % 3 == 0)
        { 
            return n
        } 
    }
    
    return 0
}


f5(x: i64): i64 
{ switch(x)
    { 
        case 0: 
        case 1: return 42
            case 3: 
        default: 
        return -1
    }
}


f6(n: i64): i64 
{ 
    p := 1 
        while (n) 
    { 
        p *= 2 
            n-- 
    } 
    
    return p
}


f7(n: i64): i64 
{
    p := 1 
        do 
    {
        p *= 2 
            n-- 
    }
    while (n) 
        return p
}


add(v: Vector, w: Vector): Vector { return {v.x + w.x, v.y + w.y} }



IntOrPtr : union  { i: i64 p: i64* }

u1 = IntOrPtr{i = 42}
u2 = IntOrPtr{p = cast(i64*, 42)}

a : i64[256] =  {1, ['a'] = 33, [255] = 123}


v: Vector = 0 ? {1,2} : {3,4}
vs: Vector[2][2] = {{{1,2},{3,4}}, {{5,6},{7,8}}}


A : struct  { c: char }
B : struct { i: i64 }
C : struct { c: char a: A }
D : struct { c: char b: B }


//print(v: Vector) { printf("{%d, %d}", v.x, v.y) }


x = add({1,2}, {3,4})
v : Vector = {1,2}
w = Vector{3,4}


a : i64
p : void *

i = cast(i64, p) + 1

fp: func(Vector)
Dup : struct { x: i64 x: i64 }
a: i64[3] = {1,2,3}
b: i64[4]
p = &a[1]
i = p[1]
j = *p


n :: = sizeof(a)
m :: = sizeof(&a[0])
l :: = sizeof(1 ? a : b)
pi = 3.14
name = "Per"
v = Vector{1,2}
j = cast(i64, p)
//q = cast(i64*, j)
i :: = 42
//j :: = +i
//k :: = -i

a :: = 1000/((2*3-5) << 1)
b :: = !0
c :: = ~100 + 1 == -100
k :: = 1 ? 2 : 3
IntOrPtr : union{ i: i64 p: i64* }
i = 42
u = IntOrPtr{i, &i}
n :: = 1+sizeof(p)
p: T*
u = *p
T : struct { a: i64[n] }
r = &t.a
t: T
typedef S = i64[n+m]
m :: = sizeof(t.a)
i = n+m
q = &i
n :: = sizeof(x)
x: T
T : struct  { s: S* }
S : struct { t: T[n] }