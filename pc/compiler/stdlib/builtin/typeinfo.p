//typedef BUILTINtypeid = ullong;
/*
BUILTINTypeKind enum {
    BUILTINTYPE_NONE,
    BUILTINTYPE_VOID,
    BUILTINTYPE_BOOL,
    BUILTINTYPE_CHAR,
    BUILTINTYPE_UCHAR,
    BUILTINTYPE_SCHAR,
    BUILTINTYPE_SHORT,
    BUILTINTYPE_USHORT,
    BUILTINTYPE_INT,
    BUILTINTYPE_UINT,
    BUILTINTYPE_LONG,
    BUILTINTYPE_ULONG,
    BUILTINTYPE_LLONG,
    BUILTINTYPE_ULLONG,
    BUILTINTYPE_FLOAT,
    BUILTINTYPE_DOUBLE,
    BUILTINTYPE_CONST,
    BUILTINTYPE_PTR,
    BUILTINTYPE_ARRAY,
    BUILTINTYPE_STRUCT,
    BUILTINTYPE_UNION,
    BUILTINTYPE_FUNC,
    BUILTINTYPE_TUPLE,
}

BUILTINTypeFieldInfo struct {
    name: char const*;
    type: BUILTINtypeid;
    offset: int;
}

struct BUILTINTypeInfo {
    kind: BUILTINTypeKind;
    size: int;
    align: int;
    name: char const*;
    count: int;
    base: BUILTINtypeid;
    fields: BUILTINTypeFieldInfo*;
    num_fields: int;
}

@foreign
var BUILTINtypeinfos: ^^BUILTINTypeInfo

@foreign
var BUILTINnum_typeinfos: int

func BUILTINtypeid_kind(type: BUILTINtypeid): BUILTINTypeKind {
    return BUILTINTypeKind((type >> 24) & 0xFF);
}

func BUILTINtypeid_index(type: BUILTINtypeid): int {
    return int(type & 0xFFFFFF);
}

func BUILTINtypeid_size(type: BUILTINtypeid): usize {
    return usize(type >> 32);
}

func get_typeinfo(type: BUILTINtypeid): ^BUILTINTypeInfo  {
    index := BUILTINtypeid_index(type);
    if (BUILTINtypeinfos && index < BUILTINnum_typeinfos) {
        return BUILTINtypeinfos[index];
    } else {
        return NULL;
    }
}*/

 any struct {
    ptr: void*;
    type: ullong;
}
