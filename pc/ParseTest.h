
x : char[256] = {1, 2, 3, ['a'] = 4}

g : char[245] = 'kkk'

v = Vector{x = 1.0, y = -1.0}

v : Vector = {1.0, -1.0}

n = sizeof(:i64 *[16])

n ::  = sizeof(1+2)
x = b == 1 ? 1+2 : 3-4

fact( n : i64) : i64 
{  
    if n == 0
    { 
        return 1
    } 
    else 
    {
        return  n * fact( n - 1)
    }
    
}



fact(n: i64): i64
{ 
    p := 1
        
        for i := 1; i <= n; i++
    {
        p *= i
    } 
    
    return p 
}


foo = a ? a&b + c<<d + e*f == +u-v-w + *g/h(x,y) + -i%k[x] && m <= n*(p+q)/r : 0


f(x: i64): bool 
{
    switch (x )
    { 
        case 0: 
        case 1: return true
            case 2:
        case 3:
        case 4: return false
            case 5: return true
            default: return false
    }
} 

Color: enum { RED = 3, GREEN, BLUE = 0 }

pi = 3.14


Vector : struct
{
    x, y: float
}



IntOrFloat : union { i: i64  f: float }

typedef Vectors = Vector[1+2]


f() { 
    do 
    {
        
        printf(66)
            
    } while (1)
}


typedef T = (func(i64):i64)[16]

f() 
{  
    E : enum { A, B, C } 
    
    return
}



o : enum
{
    p, k, l
}


Bar() 
{
    if(1) 
    { 
        return 1
    } 
    else if 2
    { 
        return 2
    } 
    else 
    { 
        return 3
    }
}
