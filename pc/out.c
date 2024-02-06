#include <stdio.h>
#include <stdint.h>
typedef int64_t i64;
typedef union IntOrPtr IntOrPtr;

void f(void);

typedef struct Vector Vector;

i64 fact_iter(i64 n);

i64 fact_rec(i64 n);

typedef struct T T;


union IntOrPtr {i64 i;i64 (*p);};
void f(void) {

    IntOrPtr u1 = (IntOrPtr){.i = 42};
    IntOrPtr u2 = (IntOrPtr){.p = (int *)(42)
};
    u1.i = 0;
    u2.p = (int *)(0)
;}

i64 i;
struct Vector {i64 x;i64 y;};
i64 fact_iter(i64 n) {

    int r = 1;for (int i = 2; (i) <= (n); i++) {

        r *= i;}
return r;}

i64 fact_rec(i64 n) {
if ((n) == (0)) {
return 1;}
 else {
return (n) * (fact_rec((n) - (1)));}
}

T (*p);
enum { n = (1) + (sizeof(p)) };
struct T {ni64 (a[(null)]);};
