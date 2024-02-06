typedef enum TypeKind {
    TYPE_NONE,
    TYPE_INCOMPLETE,
    TYPE_COMPLETING,
    TYPE_VOID,
    TYPE_CHAR,
    TYPE_I64,
    TYPE_FLOAT,
    TYPE_PTR,
    TYPE_ARRAY,
    TYPE_STRUCT,
    TYPE_UNION,
    TYPE_ENUM,
    TYPE_FUNC,
} TypeKind;

typedef struct Sym Sym;

typedef struct Type Type;

typedef struct TypeField {
    const char *Name;
    Type *type;
} TypeField;



struct Type
{
    TypeKind Kind;
    size_t Size;
    size_t Align;
    Sym *sym;
    
    union{
        struct {
            struct Type *Elem;
        }Ptr;
        struct {
            struct Type *Elem;
            size_t Size;
        } Array;
        struct {
            TypeField *Fields;
            size_t NumFields;
        } Aggregate;
        struct {
            Type **Params;
            size_t NumParams;
            struct Type *Ret;
        } Func;
    };
    
};

const size_t PTR_SIZE = 8;
const size_t PTR_ALIGN = 8;



typedef enum EntityKind {
    SYM_NONE,
    SYM_VAR,
    SYM_CONST,
    SYM_FUNC,
    SYM_TYPE,
    SYM_ENUM_CONST,
} SymKind;

typedef enum SymState {
    SYM_UNRESOLVED,
    SYM_RESOLVING,
    SYM_RESOLVED,
} SymState;

struct Sym
{
    const char *Name;
    SymKind Kind;
    SymState State;
    Decl *decl;
    Type *type;
    i64 Val;
    
};

void ResolveSym(Sym* sym);

typedef struct CachedArrayType {
    Type *Elem;
    size_t Size;
    Type *Array;
} CachedArrayType;

CachedArrayType *CachedArrayTypes;

typedef struct Operand {
    Type *type;
    bool32 IsLValue;
    bool32 IsConst;
    int64_t Val;
} Operand;

Type *TypeAlloc(TypeKind Kind) {
    Type *type = calloc(1, sizeof(Type));
    type->Kind = Kind;
    return type;
}

Sym *Syms;

Type *TypeVoid = &(Type){TYPE_VOID, 0, 0,  0, {{0}}};
Type *TypeChar = &(Type){TYPE_CHAR, 1, 1,  0, {{0}}};
Type *TypeI64 = &(Type){TYPE_I64, 4, 4, 0, {{0}}};
Type *TypeFloat = &(Type){TYPE_FLOAT, 4, 4,  0, {{0}}};

typedef struct CachedFuncType {
    Type **Params; // Type
    size_t NumParams;
    Type *Ret;
    Type *Func;
} CachedFuncType;

CachedFuncType *CachedFuncTypes;



typedef struct CachedPtrType {
    Type *Elem;
    Type *Ptr;
} CachedPtrType;


CachedPtrType *CachedPtrTypes;
Sym **GlobalSyms;

Sym **OrderedSyms;

enum {
    MAX_LOCAL_SYMS = 1024
};

Sym LocalSyms[MAX_LOCAL_SYMS];
Sym *local_syms_end = LocalSyms;

Sym *sym_enter(void) {
    return local_syms_end;
}

void sym_leave(Sym *sym) {
    local_syms_end = sym;
}