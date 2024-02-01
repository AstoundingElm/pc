/*x : i64

Vector : struct 
{
    x, y : i64
}

*/
/*print(v : Vector) 
{
    printf('{%d, %d}', v.x, v.y);
}*/
/*
add(v: Vector, w: Vector): Vector 
{ 
    return {v.x + w.x, v.y + w.y} 
}



v: Vector = {1,2}

w := Vector{3,4}

p : void*

i := cast(i64, p) + 1
b: i64[4]
l :: := sizeof(1 ? a : b)*/
a: i64[3] = {1,2,3}

p := &a[1]

i := p[1]
j := *p

n :: := sizeof(a)
m :: := sizeof(&a[0])



pi := 3.14

//j := +i
//k := -i

name := 'Pete'


Vector : struct 
{
    x, y : i64
}

v := Vector{1,2}

i :: := 42

p := cast(void *) i

j  := cast(i64)p
//q := cast(i64*)j

a :: := 1000/((2*3-5) << 1)

b :: := !0


c :: := ~100 + 1 == -100
k :: := 1 ? 2 : 3

add(v: Vector, w: Vector): Vector 
{ 
    return {v.x + w.x, v.y + w.y} 
}

x := add({1,2}, {3,4})

v: Vector = {1,2}

w := Vector{3,4}

IntOrPtr : union
{ 
    i: i64
        p: i64* 
}

i  := 42

p := Test{1, 2}

Test : struct
{
    i : i64
        b : i64
}

u := IntOrPtr{i, &i}

n :: := 1  + sizeof(p)


p: T*

u := *p

T: struct 
{
    a: i64[n] 
}

r := &t.a

t : T
typedef S = i64[n+m]

m :: := sizeof(t.a)

i := n+m

q := &i
n :: := sizeof(x)
x: T

T : struct 
{
    s: S* 
}

S : struct 
{ 
    t: T[n]
}
