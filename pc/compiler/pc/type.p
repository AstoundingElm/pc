PTypeKind enum {
  PTYPE_NONE,
    PTYPE_INCOMPLETE,
    PTYPE_COMPLETING,
    PTYPE_VOID,
    PTYPE_BOOL,
    PTYPE_CHAR,
    PTYPE_SCHAR,
    PTYPE_UCHAR,
    PTYPE_SHORT,
    PTYPE_USHORT,
    PTYPE_INT,
    PTYPE_UINT,
    PTYPE_LONG,
    PTYPE_ULONG,
    PTYPE_LLONG,
    PTYPE_ULLONG,
    PTYPE_ENUM,
    PTYPE_FLOAT,
    PTYPE_DOUBLE,
    PTYPE_PTR,
    PTYPE_FUNC,
    PTYPE_ARRAY,
    PTYPE_STRUCT,
    PTYPE_UNION,
    PTYPE_TUPLE,
    PTYPE_CONST,
    PNUM_TYPE_KINDS,
  
}

TypeField struct {
    name ^char 
    type ^Type
    offset usize
} 

Type struct {
    kind PTypeKind
    size usize
    align usize
    padding usize
    sym ^Sym
    base ^Type
    typeid  int
    nonmodifiable bool
  union {
        anonymousstruct {
            num_elems usize
            incomplete_elems bool 
        }
        t_aggregate struct {
            fields ^TypeField 
            num_fields usize
        } 
        t_func struct {
            intrinsic bool
            params ^^Type
            num_params usize
            has_varargs bool
            varargs_type ^Type
            ret ^Type
        } 
    }
}

TypeMetrics struct { 
    size usize
    align usize
    sign bool 
    max ullong
} 

type_metrics ^TypeMetrics

type_void ^Type = &(:Type){PTYPE_VOID}
type_bool ^Type = &(:Type){PTYPE_BOOL}
type_char ^Type = &(:Type){PTYPE_CHAR}
type_uchar ^Type = &(:Type){PTYPE_UCHAR}
type_schar ^Type = &(:Type){PTYPE_SCHAR}
type_short ^Type = &(:Type){PTYPE_SHORT}
type_ushort ^Type = &(:Type){PTYPE_USHORT}
type_int ^Type = &(:Type){PTYPE_INT}
type_uint ^Type = &(:Type){PTYPE_UINT}
type_long ^Type = &(:Type){PTYPE_LONG}
type_ulong ^Type = &(:Type){PTYPE_ULONG}
type_llong ^Type = &(:Type){PTYPE_LLONG}
type_ullong ^Type = &(:Type){PTYPE_ULLONG}
type_float ^Type = &(:Type){PTYPE_FLOAT}
type_double ^Type = &(:Type){PTYPE_DOUBLE}

type_char_ptr ^Type 
type_alloc_func ^Type

next_typeid int = 1

type_uintptr ^Type
type_usize ^Type
type_ssize ^Type

type_any ^Type 

typeid_map PMap  

get_type_from_typeid(typeid int) ^Type {
    if (typeid == 0) {
        return NULL
    }
    return map_get(&typeid_map, (: ^void )(:uintptr)typeid)
}

register_typeid(type ^Type) {
    map_put(&typeid_map, (: ^void )(:uintptr)type.typeid, type)
}


type_alloc(kind PTypeKind) ^Type {
    type ^Type = xcalloc(1, sizeof(Type))
    type.kind = kind
     type.typeid = next_typeid++
    register_typeid(type)
    return type
}

is_ptr_type(type ^Type) bool {
    return type && type.kind == PTYPE_PTR;
}

is_func_type(type ^Type ) bool {
    return type && type.kind == PTYPE_FUNC;
}

is_ptr_like_type(type ^Type) bool {
    return type && (type.kind == PTYPE_PTR || type.kind == PTYPE_FUNC);
}

is_const_type(type ^Type) bool {
    return type && type.kind == PTYPE_CONST;
}

is_array_type(type ^Type ) bool {
    return type && type.kind == PTYPE_ARRAY;
}

is_incomplete_array_type(type ^Type) bool {
    return type && is_array_type(type) && type.incomplete_elems;
}

is_integer_type(type ^Type) bool {
    return PTYPE_BOOL <= type.kind && type.kind <= PTYPE_ENUM;
}

is_floating_type(type ^Type) bool {
    return PTYPE_FLOAT <= type.kind && type.kind <= PTYPE_DOUBLE;
}

is_arithmetic_type(type ^Type) bool {
    return PTYPE_BOOL <= type.kind && type.kind <= PTYPE_DOUBLE;
}

is_scalar_type(type ^Type) bool {
    return PTYPE_BOOL <= type.kind && type.kind <= PTYPE_FUNC;
}

is_aggregate_type(type ^Type ) bool {
    return type.kind == PTYPE_STRUCT || type.kind == PTYPE_UNION || type.kind == PTYPE_TUPLE;
}

is_signed_type(type ^Type) bool {
   switch (type.kind) {
    case PTYPE_CHAR:
        return type_metrics[PTYPE_CHAR].sign;
    case PTYPE_SCHAR:
    case PTYPE_SHORT:
    case PTYPE_INT:
    case PTYPE_LONG:
    case PTYPE_LLONG:
        return true;
    default:
        return false;
    }
}

type_names ^[PNUM_TYPE_KINDS]char = {
    [PTYPE_VOID] = "void",
    [PTYPE_BOOL] = "bool",
    [PTYPE_CHAR] = "char",
    [PTYPE_SCHAR] = "schar",
    [PTYPE_UCHAR] = "uchar",
    [PTYPE_SHORT] = "short",
    [PTYPE_USHORT] = "ushort",
    [PTYPE_INT] = "int",
    [PTYPE_UINT] = "uint",
    [PTYPE_LONG] = "long",
    [PTYPE_ULONG] = "ulong",
    [PTYPE_LLONG] = "llong",
    [PTYPE_ULLONG] = "ullong",
    [PTYPE_FLOAT] = "float",
    [PTYPE_DOUBLE] = "double",
}

type_ranks[PNUM_TYPE_KINDS] int = {
   [PTYPE_BOOL] = 1,
    [PTYPE_CHAR] = 2,
    [PTYPE_SCHAR] = 2,
    [PTYPE_UCHAR] = 2,
    [PTYPE_SHORT] = 3,
    [PTYPE_USHORT] = 3,
    [PTYPE_INT] = 4,
    [PTYPE_UINT] = 4,
    [PTYPE_LONG] = 5,
    [PTYPE_ULONG] = 5,
    [PTYPE_LLONG] = 6,
    [PTYPE_ULLONG] = 6,
}

type_rank(type ^Type) int {
    rank := type_ranks[type.kind]
    #assert(rank != 0)
    return rank
}

unsigned_type(type ^Type) ^Type {
    switch (type.kind) {
    case PTYPE_BOOL:
        return type_bool
    case PTYPE_CHAR:
    case PTYPE_SCHAR:
    case PTYPE_UCHAR:
        return type_uchar
    case PTYPE_SHORT:
    case PTYPE_USHORT:
        return type_ushort
    case PTYPE_INT:
    case PTYPE_UINT:
        return type_uint
    case PTYPE_LONG:
    case PTYPE_ULONG:
        return type_ulong
    case PTYPE_LLONG:
    case PTYPE_ULLONG:
        return type_ullong
    default:
        #assert(0)
        return NULL
    }
}

type_sizeof(type ^Type) usize {
    #assert(type.kind > PTYPE_COMPLETING)
    return type.size
}

type_alignof(type ^Type) usize {
    #assert(type.kind > PTYPE_COMPLETING)
    return type.align
}

type_padding(type ^Type) usize {
    #assert(type.kind > PTYPE_COMPLETING)
    return type.padding
}

cached_ptr_types PMap

type_ptr(base ^Type) ^Type {
    type: ^Type = map_get(&cached_ptr_types, base)
    if (!type) {
        type = type_alloc(PTYPE_PTR)
        type.size = type_metrics[PTYPE_PTR].size
        type.align = type_metrics[PTYPE_PTR].align
        type.base = base
        map_put(&cached_ptr_types, base, type)
    }
    return type
}

cached_const_types PMap 

type_const(base ^Type) ^Type {
    if (base.kind == PTYPE_CONST) {
        return base
    }
    type ^Type =  map_get(&cached_const_types, base)
    if (!type) {
        complete_type(base)
        type = type_alloc(PTYPE_CONST)
        type.nonmodifiable = true
        type.size = base.size
        type.align = base.align
        type.base = base
        map_put(&cached_const_types, base, type)
    }
    return type
}

unqualify_type(type ^Type) ^Type {
    if (type.kind == PTYPE_CONST) {
        return type.base
    } else {
        return type
    }
}

qualify_type(type ^Type, qual ^Type) ^Type {
    type = unqualify_type(type)
    while (qual.kind == PTYPE_CONST) {
        type = type_const(type)
        qual = qual.base
    }
    return type
}

CachedArrayType struct {
    type ^Type 
    next ^CachedArrayType
}

cached_array_types PMap

type_array(base ^Type, num_elems usize, incomplete_elems bool) ^Type {
    hash uint64 = phash_mix(phash_ptr(base), hash_uint64(num_elems))
    key uint64 = hash ? hash : 1
    cached ^CachedArrayType = map_get_from_uint64(&cached_array_types, key)
    if (!incomplete_elems) {
        for (it := cached; it; it = it.next) {
            type := it.type
            if (type.base == base && type.num_elems == num_elems) {
                return type
            }
        }

    }
    complete_type(base)
    type: ^Type = type_alloc(PTYPE_ARRAY)
    type.nonmodifiable = base.nonmodifiable
    type.size = num_elems * type_sizeof(base);
    type.align = type_alignof(base);
    type.base = base;
    type.num_elems = num_elems
    type.incomplete_elems = incomplete_elems
    if (!incomplete_elems) {
        new_cached: ^CachedArrayType = xmalloc(sizeof(CachedArrayType))
        new_cached .type = type
        new_cached .next = cached;
        map_put_from_uint64(&cached_array_types, key, new_cached);
    }
    return type;
}

TypeLink struct {
    type ^Type 
    next ^TypeLink
}

cached_func_types PMap

type_func(params ^^Type, num_params usize, ret ^Type, intrinsic bool , has_varargs bool, varargs_type ^Type) ^Type{
    params_size usize = num_params * sizeof(*params);
    hash uint64  = phash_mix(phash_bytes(params, params_size), phash_ptr(ret));
    key uint64 = hash ? hash : 1;
    cached ^TypeLink = map_get_from_uint64(&cached_func_types, key);
    for (it := cached; it; it = it.next) {
        type := it.type;
        if (type.t_func.num_params == num_params && type.t_func.ret == ret && type.t_func.intrinsic == intrinsic && type.t_func.has_varargs == has_varargs && type.t_func.varargs_type == varargs_type) {
            if (pc_memcmp(type.t_func.params, params, params_size) == 0) {
                return type;
            }
        }
    }
    type: ^Type = type_alloc(PTYPE_FUNC);
    type.size = type_metrics[PTYPE_PTR].size;
    type.align = type_metrics[PTYPE_PTR].align;
    type.t_func.params = memdup(params, params_size);
    type.t_func.num_params = num_params;
    type.t_func.intrinsic = intrinsic;
    type.t_func.has_varargs = has_varargs;
    type.t_func.varargs_type = varargs_type;
    type.t_func.ret = ret;
    new_cached: ^TypeLink = xmalloc(sizeof(TypeLink));
    new_cached.type = type;
    new_cached.next = cached;
    map_put_from_uint64(&cached_func_types, key, new_cached);
    return type;
}

has_duplicate_fields(type ^Type) bool {
    for (i usize = 0; i < type.t_aggregate.num_fields; i++) {
        for (j usize = i+1; j < type.t_aggregate.num_fields; j++) {
            if (type.t_aggregate.fields[i].name == type.t_aggregate.fields[j].name) {
                return true
            }
        }
    }
    return false
}


add_type_fields(fields ^^TypeField, type ^Type, offset usize) {
    #assert(type.kind == PTYPE_STRUCT || type.kind == PTYPE_UNION);
    for (i usize = 0; i < type.t_aggregate.num_fields; i++) {
        field ^TypeField = &type.t_aggregate.fields[i];
        buf_push(*fields, (:TypeField){field.name, field.type, field.offset + offset});
    }
}

type_complete_struct(type ^Type, fields ^TypeField, num_fields usize) {
   #assert(type.kind == PTYPE_COMPLETING);
    type.kind = PTYPE_STRUCT;
    type.size = 0;
    type.align = 0;
    nonmodifiable := false;
    field_sizes usize = 0;
    new_fields ^TypeField = NULL;
    for (it := fields; it != fields + num_fields; it++) {
        #assert(IS_POW2(type_alignof(it.type)));
        if (it.name) {
            it.offset = type.size;
            buf_push(new_fields, *it);
        } else {
            add_type_fields(&new_fields, it.type, type.size);
        }
        field_sizes += type_sizeof(it.type);
        type.align = MAX(type.align, type_alignof(it.type));
        type.size = type_sizeof(it.type) + ALIGN_UP(type.size, type_alignof(it.type));
        nonmodifiable = it.type.nonmodifiable || nonmodifiable;
    }
    type.size = ALIGN_UP(type.size, type.align);
    type.padding = type.size - field_sizes;
    type.t_aggregate.fields = new_fields;
    type.t_aggregate.num_fields = buf_len(new_fields);
    type.nonmodifiable = nonmodifiable;
}

type_complete_union(type ^Type, fields ^TypeField, num_fields usize ) {
  #assert(type.kind == PTYPE_COMPLETING);
    type.kind = PTYPE_UNION;
    type.size = 0;
    type.align = 0;
    nonmodifiable := false;
    new_fields ^TypeField = NULL;
    for (it := fields; it != fields + num_fields; it++) {
        #assert(it.type.kind > PTYPE_COMPLETING);
        if (it.name) {
            it.offset = 0;
            buf_push(new_fields, *it);
        } else {
            add_type_fields(&new_fields, it.type, 0);
        }
        type.size = MAX(type.size, type_sizeof(it.type));
        type.align = MAX(type.align, type_alignof(it.type));
        nonmodifiable = it.type.nonmodifiable || nonmodifiable;
    }
    type.size = ALIGN_UP(type.size, type.align);
    type.t_aggregate.fields = new_fields;
    type.t_aggregate.num_fields = buf_len(new_fields);
    type.nonmodifiable = nonmodifiable;
}

type_complete_tuple(type ^Type, fields ^^Type, num_fields usize) {
    type.kind = PTYPE_TUPLE
    type.size = 0
    type.align = 0
    nonmodifiable := false
    elem_sizes usize = 0
    new_fields ^TypeField = NULL
    for (i usize = 0; i < num_fields; i++) {
        field := fields[i]
        complete_type(fields[i])
        #assert(IS_POW2(type_alignof(field)))
        name[64]char 
        snprintf(name, sizeof(name), "_%d", (:int)i)
        new_field: TypeField  = {
            name = str_intern(name),
            type = fields[i],
            offset = type.size,
        }
        buf_push(new_fields, new_field)
        elem_sizes += type_sizeof(field)
        type.align = MAX(type.align, type_alignof(field));
        type.size = type_sizeof(field) + ALIGN_UP(type.size, type_alignof(field));
        nonmodifiable = field.nonmodifiable || nonmodifiable;
    }
    type.size = ALIGN_UP(type.size, type.align);
    type.padding = type.size - elem_sizes;
    type.t_aggregate.fields = new_fields;
    type.t_aggregate.num_fields = buf_len(new_fields);
    type.nonmodifiable = nonmodifiable;
}

type_incomplete(sym ^Sym) ^Type{
    type := type_alloc(PTYPE_INCOMPLETE)
    type.sym = sym
    return type
}

type_enum(sym ^Sym, base ^Type) ^Type {
    type: ^Type = type_alloc(PTYPE_ENUM)
    type.sym = sym
    type.base = base
    type.size = type_int.size
    type.align = type_int.align
    return type
}

init_builtin_type(type ^Type) {
    type.typeid = next_typeid++
    register_typeid(type)
    type.size = type_metrics[type.kind].size
    type.align = type_metrics[type.kind].align
}

init_builtin_types() {
    init_builtin_type(type_void);
    init_builtin_type(type_bool);
    init_builtin_type(type_char);
    init_builtin_type(type_uchar);
    init_builtin_type(type_schar);
    init_builtin_type(type_short);
    init_builtin_type(type_ushort);
    init_builtin_type(type_int);
    init_builtin_type(type_uint);
    init_builtin_type(type_long);
    init_builtin_type(type_ulong);
    init_builtin_type(type_llong);
    init_builtin_type(type_ullong);
    init_builtin_type(type_float);
    init_builtin_type(type_double);
    type_char_ptr = type_ptr(type_char);

    type_alloc_func = type_func((:^[]Type){type_usize, type_usize}, 2, type_ptr(type_void), false, false, type_void);
}

aggregate_item_field_index(type ^Type, name ^char) usize{
   #assert(is_aggregate_type(type));
    for (i usize = 0; i < type.t_aggregate.num_fields; i++) {
        if (type.t_aggregate.fields[i].name == name) {
            return (:int)i
        }
    }
    return -1
}


aggregate_field_type_from_index(type ^Type, index int) ^Type {
    #assert(is_aggregate_type(type))
    #assert(0 <= index && index < (:int)type.t_aggregate.num_fields)
    return type.t_aggregate.fields[index].type
}

aggregate_field_type_from_name(type ^Type, name ^char) ^Type {
    #assert(is_aggregate_type(type));
    index := aggregate_item_field_index(type, name)
    if (index < 0) {
        return NULL
    }
    return aggregate_field_type_from_index(type, index)
}

cached_tuple_types PMap 
tuple_types ^^Type

type_tuple(fields ^^Type, num_fields usize) ^Type {
    fields_size usize = num_fields * sizeof(*fields)
    hash uint64 = phash_bytes(fields, fields_size)
    key uint64 = hash ? hash : 1;
    cached: ^TypeLink = map_get_from_uint64(&cached_tuple_types, key);
    for (it := cached; it; it = it.next) {
        cached_type := it.type;
        if (cached_type.t_aggregate.num_fields == num_fields) {
            for (i usize = 0; i < num_fields; i++) {
                if (cached_type.t_aggregate.fields[i].type != fields[i]) {
                    goto next;
                }
            }
            return cached_type;
        }
        :next b int  = 0
    }
    type: ^Type = type_alloc(PTYPE_TUPLE)
    type_complete_tuple(type, fields, num_fields);
    new_cached: ^TypeLink = xmalloc(sizeof(TypeLink));
    new_cached.type = type;
    new_cached.next = cached;
    map_put_from_uint64(&cached_tuple_types, key, new_cached);
    buf_push(tuple_types, type);
    return type;
}

unqualify_ptr_type(type ^Type) ^Type {
    if (type.kind == PTYPE_PTR) {
        type = type_ptr(unqualify_type(type.base))
    }
    return type
}
