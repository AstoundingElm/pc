/*#foreign(header = "<stdlib.h>")

@foreign
struct div_t {
    quot: int;
    rem: int;
}

@foreign
struct ldiv_t {
    quot: long;
    rem: long;
}

@foreign
struct lldiv_t {
    quot: llong;
    rem: llong;
}

@foreign var RAND_MAX: int

@foreign
func atof(nptr: char*): double;

@foreign
func atoi(nptr: char*): int;

@foreign
func atol(nptr: char*): long;

@foreign
func atoll(nptr: char*): llong;

@foreign
func rand(): int;

@foreign
func srand(seed: uint);

@foreign
func stdlibfree(ptr: void*);

@foreign
func malloc(size: usize): void*;

@foreign
func abort();

@foreign
func atexit(procedure: func()): int;

@foreign
func system(string: char*): int;

@foreign
func bsearch(key: void *, base: void *, nmemb: usize, size: usize, compar: func(void *, void *): int): void*;

@foreign
func qsort(base: void*, nmemb: usize, size: usize, compar: func(void *, void *): int);

@foreign
func abs(j: int): int;

@foreign
func labs(j: long): long;

@foreign
func llabs(j: llong): llong;

@foreign
func div(numer: int, denom: int): div_t;


@foreign
func ldiv(numer: long, denom: long): ldiv_t;

@foreign
func lldiv(numer: llong, denom: llong): lldiv_t;

@foreign
func mblen(s: char*, n: usize): int;

@foreign
func mbtowc(pwc: short*, s: char*, n: usize): int;

@foreign
func wctomb(s: char*, wchar: short): int;

@foreign
func mbstowcs(pwcs: short*, s: char*, n: usize): usize;

@foreign
func wcstombs(s: char*, pwcs: short *, n: usize): usize;*/



@foreign
func exit(status: int);

@foreign
func _Exit(status: int);

@foreign
func getenv(name: char*): char*;


@foreign
func malloc(size: usize): void*;

@foreign
func realloc(ptr: void*, size: usize): void*;

@foreign
func calloc(nmemb: usize, size: usize): void*;

@foreign
func strtod(nptr: char*, endptr: char**): double;

@foreign
func strtof(nptr: char*, endptr: char**): float;

@foreign
func strtol(nptr: char*, endptr: char**, base: int): long;

@foreign
func strtoll(nptr: char*, endptr: char**, base: int): llong;

@foreign
func strtoul(nptr: char*, endptr: char**, base: int): ulong;

@foreign
func strtoull(nptr: char*, endptr: char**, base: int): ullong;