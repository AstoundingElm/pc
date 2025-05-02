import libc{...}

func MIN(x: int, y: int): int {
    return x <= y ? x : y;
}

func MAX(x: int, y: int): int {
    return x >= y ? x : y;
}

func CLAMP_MAX(x: int, x_max: int): int {
    return MIN(x, x_max);
}

func CLAMP_MIN(x: int, x_min: int): int {
    return MAX(x, x_min);
}

func IS_POW2(x: int): bool {
    return (((x) != 0) && ((x) & ((x)-1)) == 0)
}

func ALIGN_DOWN(x: int, alignment: int): int {
    return x & ~(alignment - 1);
}

func ALIGN_UP(x: int, alignment: int): int {
    return (x + alignment - 1) & ~(alignment - 1);
}

func ALIGN_DOWN_PTR(ptr: void*, alignment: uintptr): void* {
    return (:void*)(uintptr(ptr) & ~(alignment - 1));
}

func ALIGN_UP_PTR(ptr: void*, alignment: uintptr): void* {
    return (:void*)((uintptr(ptr) + alignment - 1) & ~(alignment - 1));
}

func align_down_uint(x: uint, alignment: uint): uint {
    return x & ~(alignment - 1);
}

func align_up_uint(x: uint, alignment: uint): uint {
    return (x + alignment - 1) & ~(alignment - 1);
}   


xcalloc(num_elems usize, elem_size usize) ^void {
    ptr :^void  = calloc(num_elems, elem_size)
    if (!ptr) {
        perror("xcalloc failed")
        exit(1)
    }
    return ptr
}

xrealloc fn(ptr ^void, num_bytes usize) ^void {

    ptr = realloc(ptr, num_bytes)
	if(!ptr)
	{
		perror("xrealloc failed")
		exit(1)
	}

	return ptr
}

xmalloc fn(num_bytes usize) ^void {

	ptr : ^void = malloc(num_bytes)
	if(!ptr){

		perror("xmalloc failed")
		exit(1)
	}

	return ptr
}

memdup fn(src :^void, size usize) ^void { 
    dest : ^void = xmalloc(size)
    pc_memcpy(dest, src, size)
    return dest
}

strf fn(fmt ^char, ...) ^char {
    args va_list
    va_start(args, fmt)
    n usize = 1 + vsnprintf(NULL, 0, fmt, args)
    va_end(args)
    str : ^char = xmalloc(n)
    va_start(args, fmt)
    vsnprintf(str, n, fmt, args)
    va_end(args)
    return str
}

read_file(path ^char ) ^char {
    file := fopen(path, "rb")
    if (!file) {
        return NULL
    }
    fseek(file, 0, SEEK_END)
    len := ftell(file)
    fseek(file, 0, SEEK_SET)
    buf ^char = xmalloc(len + 1)
    if (len && fread(buf, len, 1, file) != 1) {
        fclose(file)
        free(buf)
        return NULL
    }
    fclose(file) 
    buf[len] = 0
    return buf
}

write_file(path ^char, buf ^char, len usize) bool {
    file := fopen(path, "w");
    if (!file) {
        return false;
    }
    n := fwrite(buf, len, 1, file);
    fclose(file);
    return n == 1;
}

get_ext(path ^char) ^char {
    ext ^char = NULL
    for (i := 0; path^; path++) {
        if (*path == '.') {
            ext = path + 1
        }
    }
    return ext
}

replace_ext(path ^char, new_ext ^char) ^char {
    ext := get_ext(path)
    if (!ext) {
        return NULL
    }
    base_len := ext - path
    new_ext_len := pc_strlen(new_ext)
    new_path_len := base_len + new_ext_len
    new_path ^char = xmalloc(new_path_len + 1)
    pc_memcpy(new_path, path, base_len)
    pc_memcpy(new_path + base_len, new_ext, new_ext_len)
    new_path[new_path_len] = 0
    return new_path
}

@foreign("buf_len")
buf_len(x ^void ) -> usize;

@foreign("buf_push")
buf_push(x ^void, ...) -> ^void;

@foreign("buf_free")
buf_free(a ^void) -> ^void;

@foreign("buf_end")
buf_end(a ^void) -> ^void;

@foreign("buf_printf")
buf_printf(b char *, ...) -> ^char;

@foreign("buf_clear")
buf_clear(b ^void);

buf_test fn() {
    /*tbuf ^int 
    a := 1024

    for(i int = 0; i < 1024; i++) {
        apush(tbuf, i)

    }

    #assert(alen(tbuf) == a)
    for i int = 0, i < alen(tbuf), i++ {
        #assert(tbuf[i] == i)
      //  printf("%d\n", tbuf[i])
    }

    afree(tbuf)
*/
    buf :^int = NULL
    #assert(buf_len(buf) == 0)
    
    n int = 1024
    for (i int = 0; i < n; i++ ) {
        buf_push(buf, i)
    }

    #assert(buf_len(buf) == n)
    for i int = 0, i < buf_len(buf), i++ {
        #assert(buf[i] == i)
    }

    buf_free(buf)
    #assert(buf == NULL)
    #assert(buf_len(buf) == 0)

    str: ^char = NULL
    buf_printf(str, "One: %d\n", 1)
    #assert(pc_strcmp(str, "One: 1\n") == 0)
    buf_printf(str, "Hex: 0x%x\n", 0x12345678)
    #assert(pc_strcmp(str, "One: 1\nHex: 0x12345678\n") == 0)
}

 Arena struct {
    ptr ^char
    end ^char
    blocks ^^char 
}

ARENA_ALIGNMENT uint64 = 8
ARENA_BLOCK_SIZE uint64 = (2024 * 2024)

pc_arena_grow(arena ^Arena, min_size int) {
    size := ALIGN_UP(CLAMP_MIN(min_size, ARENA_BLOCK_SIZE), ARENA_ALIGNMENT);
    arena.ptr = xmalloc(size);
    #assert(arena.ptr == ALIGN_DOWN_PTR(arena.ptr, ARENA_ALIGNMENT));
    arena.end = arena.ptr + size;
    buf_push(arena.blocks, arena.ptr);
}

pc_arena_alloc(arena ^Arena, size int) ^void {
    if (size > (:usize)(arena.end - arena.ptr)) {
        pc_arena_grow(arena, size);
        #assert(size <= (:usize)(arena.end - arena.ptr));
    }
    ptr ^void = arena.ptr;
    arena.ptr = ALIGN_UP_PTR(arena.ptr + size, ARENA_ALIGNMENT);
    #assert(arena.ptr <= arena.end);
    #assert(ptr == ALIGN_DOWN_PTR(ptr, ARENA_ALIGNMENT));
    return ptr;
}

pc_arena_free(arena ^Arena) {
    for (it ^^char = arena.blocks; it != buf_end(arena.blocks); it++) {
        free(*it);
    }
    buf_free(arena.blocks);
}

// Hash map
/*
@foreign("phash_ptr")
phash_ptr(ptr ^void) -> uint64;

@foreign("phash_mix")
 phash_mix(x uint64, y uint64) -> uint64;

@foreign("phash_bytes")
 phash_bytes(ptr ^void, len usize) -> uint64;

@foreign("hash_uint64")
hash_uint64(x uint64) -> uint64;

@foreign("map_get")
map_get(map ^PMap, key ^void) -> ^void;

@foreign("map_put")
map_put(map ^PMap, key ^void, val ^void);

@foreign("map_get_from_uint64")
map_get_from_uint64(map ^PMap, key uint64) -> ^void;

@foreign("map_put_from_uint64")
map_put_from_uint64(map ^PMap, key uint64, val ^void);


@foreign("map_get_uint64")
map_get_uint64(map ^PMap, key ^void) -> uint64;

@foreign("map_put_uint64")
map_put_uint64(map ^PMap, key ^void, val uint64);


@foreign("PMap")*/

hash_uint64(x uint64) uint64 {
    x *= 0xff51afd7ed558ccd;
    x ^= x >> 32;
    return x;
}

phash_ptr(ptr ^void) uint64 {
    return hash_uint64((:uintptr)ptr);
}

phash_mix(x uint64, y uint64) uint64 {
    x ^= y;
    x *= 0xff51afd7ed558ccd;
    x ^= x >> 32;
    return x;
}

phash_bytes(ptr ^void, len usize) uint64 {
    x uint64 = 0xcbf29ce484222325;
    buf ^char = (: ^char)ptr;
    for (i usize = 0; i < len; i++) {
        x ^= buf[i];
        x *= 0x100000001b3;
        x ^= x >> 32;
    }
    return x;
}

PMap struct {
    keys ^uint64
    vals ^uint64
    len usize
    cap usize
} 

map_get_uint64_from_uint64(map ^PMap, key uint64) uint64 {


    if(map.len == 0){

        return 0
    }


    #assert(IS_POW2(map.cap));
    i usize = (:usize)hash_uint64(key);
    #assert(map.len < map.cap);
    while(1) {
        i &= map.cap - 1;
        if (map.keys[i] == key) {
            return map.vals[i];
        } else if (!map.keys[i]) {
            return 0;
        }
        i++;
    }
    return 0;
}

//map_put_uint64_from_uint64(map ^PMap, key uint64, val uint64);

map_grow(map ^PMap, new_cap usize) {
    new_cap = CLAMP_MIN(new_cap, 16)

    new_map PMap = {
        keys = xcalloc(new_cap, sizeof(uint64)),
        vals = xmalloc(new_cap * sizeof(uint64)),
        cap = new_cap,

    }
    for (i usize = 0; i < map.cap; i++) {
        if (map.keys[i]) {
            map_put_uint64_from_uint64(&new_map, map.keys[i], map.vals[i])
        }
    }


    free((:^void)map.keys)
    free(map.vals)
    map^ = new_map
}

map_put_uint64_from_uint64(map ^PMap, key uint64, val uint64) {
    #assert(key);
    if (!val) {
        return;
    }

    if (2*map.len >= map.cap ) {
        map_grow(map, 2*map.cap);
    }
    #assert(2*map.len < map.cap);
    #assert(IS_POW2(map.cap));
    i usize = (:usize)hash_uint64(key);
    while(true) {
        i &= map.cap - 1;
        if (!map.keys[i]) {
            map.len++;
            map.keys[i] = key;
            map.vals[i] = val;
            return;
        } else if (map.keys[i] == key) {
            map.vals[i] = val;
            return;
        }
        i++;
    }
}


map_get(map ^PMap, key ^void) ^void {
    return (:^void )(:uintptr)map_get_uint64_from_uint64(map, (:uint64)(:uintptr)key);
}

map_put(map ^PMap, key ^void, val ^void) {
    map_put_uint64_from_uint64(map, (:uint64)(:uintptr)key, (:uint64)(:uintptr)val);
}

map_get_from_uint64(map ^PMap, key uint64) ^void {
    return (: ^void)(: uintptr)map_get_uint64_from_uint64(map, key);
}

map_put_from_uint64(map ^PMap, key uint64, val ^void) {
    map_put_uint64_from_uint64(map, key, (: uint64)(: uintptr)val);
}

map_get_uint64(map ^PMap, key ^void) uint64 {
    return map_get_uint64_from_uint64(map, (: uint64)(: uintptr)key);
}

map_put_uint64(map ^PMap, key ^void, val uint64) {
    map_put_uint64_from_uint64(map, (: uint64)(: uintptr)key, val);
}

map_test() {
    map PMap = {0}
    N int = 1024
    for (i usize = 1; i < N; i++) {
        map_put(&map, (: ^void )i, (: ^void)(i+1));
    }
    for (i usize = 1; i < N; i++) {
        val: ^void = map_get(&map, (: ^void)i);
        #assert(val == (: ^void)(i+1));
    }
}

Intern struct {
    len usize
    next ^Intern
    str[0]char
} 

intern_arena Arena 
interns PMap 
intern_memory_usage usize 

str_intern_range(start ^char, end ^char) ^char {
    len usize = end - start;
    hash uint64 = phash_bytes(start, len);
    key uint64 = hash ? hash : 1;
    intern ^Intern = map_get_from_uint64(&interns, key);
    for (it := intern; it; it = it.next) {
        if (it.len == len && pc_strncmp(it.str, start, len) == 0) {
            return it.str;
        }
    }


    new_intern: ^Intern = pc_arena_alloc(&intern_arena, offsetof(Intern, str) + len + 1);

   //new_intern.str = pc_arena_alloc(&intern_arena, sizeof(char) * len + 1)

    new_intern.len = len;
    new_intern.next = intern;
    pc_memcpy(new_intern.str, start, len);
    new_intern.str[len] = 0;
    map_put_from_uint64(&interns, key, new_intern);
    intern_memory_usage += sizeof(Intern) + len + 1 + 16; /* 16 is estimate of hash table cost */
    return new_intern.str;
}

str_intern(str ^char) ^char {
    return str_intern_range(str, str + pc_strlen(str));
}

PIntern struct {
    len usize
    str [0]char
} 

pc_str_arena Arena
pc_interns ^^Intern 

pc_str_intern_range(start ^char, end ^char) ^char {
    len usize = end - start
    for (it := pc_interns; it != buf_end(pc_interns); it++) {
        loc := *it
        if (loc.len == len && pc_strncmp(loc.str, start, len) == 0) {
            return loc.str
        }
    }
    str ^char = pc_arena_alloc(&pc_str_arena, len + 1)
    pc_memcpy(str, start, len)
    str[len] = 0
    intern ^Intern
    intern.len = len
    pc_memcpy(intern.str, str, sizeof(str))
    buf_push(&pc_interns, intern )
    return str
}

pc_str_intern(str ^char) ^char {
    return str_intern_range(str, str + pc_strlen(str))
}

str_islower(str ^char) bool {
    while (*str) {
        if (pc_isalpha(*str) && !pc_islower(*str)) {
            return false
        }
        str++
    }
    return true
}

typedef unsigned = uint64

Val union {
    b bool
    c char
    uc uchar
    sc schar 
    s short
    us ushort
    i int
    u unsigned
    l long 
    ul ulong 
    ll llong
    ull ullong
    p uintptr
  
}
