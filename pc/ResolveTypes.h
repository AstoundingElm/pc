typedef enum TypeKind {
    TYPE_NONE,
    TYPE_INCOMPLETE,
    TYPE_COMPLETING,
    TYPE_VOID,
    TYPE_CHAR,
    TYPE_INT,
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
    struct {
        struct Type *Base;
    }Ptr;
    struct {
        struct Type *Elem;
        size_t Size;
    } Array;/*
    struct {
        TypeField *fields;
        size_t num_fields;
    } aggregate;
    struct {
        Type **params;
        size_t num_params;
        Type *ret;
    } func;*/
    
    
}Type;

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
    i64 val;
    
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

Type TypeIntVal = {TYPE_INT, 4};
Type TypeFLoatVal = {TYPE_FLOAT};

Type *TypeI64 = &TypeIntVal;
Type *TypeFloatInt = &TypeFLoatVal;
Type *
TypePtr(Type *Base)
{
    return NULL;
}
