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
    Sym *sym;
    size_t align;
    union{
        struct {
            struct Type *Elem;
        }Ptr;
        struct {
            struct Type *Elem;
            size_t Size;
        } Array;
        struct {
            PList *Fields;
            size_t NumFields;
        } Aggregate;
        struct {
            PList *Params;
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

char *EntityStateStrings[3] =
{
    "ENTITY_UNRESOLVED",
    "ENTITY_RESOLVING",
    "ENTITY_RESOLVED",
};

struct Sym
{
    const char *Name;
    SymKind Kind;
    SymState State;
    Decl *decl;
    Type *type;
    i64 Val;
    
};

PList *OrderedEntEntities;
PList *Entities;


enum {
    MAX_LOCAL_SYMS = 1024
};





void ResolveSym(Sym* sym);

typedef struct CachedArrayType {
    Type *Elem;
    size_t Size;
    Type *Array;
} CachedArrayType;

PList *CachedArrayTypes;

typedef struct ResolvedExpression {
    Type *type;
    bool32 IsLValue;
    bool32 IsConst;
    int64_t Val;
} ResolvedExpression;

Type *TypeAlloc(TypeKind Kind) {
    Type *type = calloc(1, sizeof(Type));
    type->Kind = Kind;
    return type;
}

PList *Syms;

Type *TypeVoid = &(Type){TYPE_VOID, 0, 0, 0,{{0}}};
Type *TypeChar = &(Type){TYPE_CHAR, 1, 0, 0, {{0}}};

Type *TypeFloat = &(Type){TYPE_FLOAT, 4, 0, 0, {{0}}};

Type *TypeI64 = &(Type){TYPE_I64, 4, 0, 0,{{0}}};

typedef struct CachedFuncType {
    PList *Params; // Type
    size_t NumParams;
    Type *Ret;
    Type *Func;
} CachedFuncType;

PList*CachedFuncTypes;



typedef struct CachedPtrType {
    Type *Elem;
    Type *Ptr;
} CachedPtrType;


PList *CachedPtrTypes;