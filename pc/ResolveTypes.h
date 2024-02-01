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

typedef struct Entity Entity;



typedef struct Type
{
    TypeKind Kind;
    size_t Size;
    Entity *entity;
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
    
}Type;

typedef struct TypeField {
    const char *Name;
    Type *type;
} TypeField;

PList *OrderedEntities;
PList *Entities;

typedef enum EntityKind {
    ENTITY_NONE,
    ENTITY_VAR,
    ENTITY_CONST,
    ENTITY_FUNC,
    ENTITY_TYPE,
    ENTITY_ENUM_CONST,
} EntityKind;

typedef enum EntityState {
    ENTITY_UNRESOLVED,
    ENTITY_RESOLVING,
    ENTITY_RESOLVED,
} EntityState;

char *EntityStateStrings[3] =
{
    "ENTITY_UNRESOLVED",
    "ENTITY_RESOLVING",
    "ENTITY_RESOLVED",
};

struct Entity
{
    const char *Name;
    EntityKind Kind;
    EntityState State;
    Decl *decl;
    Type *type;
    i64 Val;
    
};

void ResolveEntity(Entity* entity);

typedef enum SymbolState
{
    SYM_UNRESOLVED,
    SYM_RESOLVING,
    SYM_RESOLVED,
    
}SymbolState;

typedef struct Symbol
{
    const char *Name;
    Decl *decl;
    SymbolState State;
    Entity *entity;
    
}Symbol;

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

PList *Syms;

Type *TypeVoid = &(Type){TYPE_VOID, 0, 0, {{0}}};
Type *TypeChar = &(Type){TYPE_CHAR, 1, 0, {{0}}};

Type *TypeFloat = &(Type){TYPE_FLOAT, 4, 0, {{0}}};

Type *TypeI64 = &(Type){TYPE_I64, 4, 0, {{0}}};



/*Type *TypePtr(Type *Base)
{
    //for (CachedPtrType *it = cached_ptr_types; it != buf_end(cached_ptr_types); it++) {
    
    CachedPtrTypes;
    if (it->elem == elem) {
        return it->ptr;
    }
}
Type *type = type_alloc(TYPE_PTR);
type->size = PTR_SIZE;
type->ptr.elem = elem;
buf_push(cached_ptr_types, (CachedPtrType){elem, type});
return type;
}*/



typedef struct CachedFuncType {
    PList *Params; // Type
    size_t NumParams;
    Type *Ret;
    Type *Func;
} CachedFuncType;

PList*CachedFuncTypes;

size_t PTR_SIZE = 8;

typedef struct CachedPtrType {
    Type *Elem;
    Type *Ptr;
} CachedPtrType;


PList *CachedPtrTypes;