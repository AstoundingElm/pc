typedef struct PList PList;


typedef enum DeclKind {
    DECL_NONE,
    DECL_ENUM,
    DECL_STRUCT,
    DECL_UNION,
    DECL_VAR,
    DECL_CONST,
    DECL_TYPEDEF,
    DECL_FUNC,
    
} DeclKind;

const char * DeclKindStrings[] = 
{
    "DECL_NONE",
    "DECL_ENUM",
    "DECL_STRUCT",
    "DECL_UNION",
    "DECL_VAR",
    "DECL_CONST",
    "DECL_TYPEDEF",
    "DECL_FUNC",
};

typedef enum ExprKind {
    EXPR_NONE,
    EXPR_I64,
    EXPR_FLOAT,
    EXPR_STR,
    EXPR_NAME,
    EXPR_CAST,
    EXPR_CALL,
    EXPR_INDEX,
    EXPR_FIELD,
    EXPR_COMPOUND,
    EXPR_UNARY,
    EXPR_BINARY,
    EXPR_TERNARY,
    EXPR_SIZEOF_EXPR,
    EXPR_SIZEOF_TYPE,
} ExprKind;


const char *ExprKindStrings[] = {
    "EXPR_NONE",
    "EXPR_I64",
    "EXPR_FLOAT",
    "EXPR_STR",
    "EXPR_NAME",
    "EXPR_CAST",
    "EXPR_CALL",
    "EXPR_INDEX",
    "EXPR_FIELD",
    "EXPR_COMPOUND",
    "EXPR_UNARY",
    "EXPR_BINARY",
    "EXPR_TERNARY",
    "EXPR_SIZEOF",
};
typedef enum CompoundFieldKind {
    FIELD_DEFAULT,
    FIELD_NAME,
    FIELD_INDEX,
} CompoundFieldKind;

/*typedef struct CompoundField {
    CompoundFieldKind Kind;
    struct Expr *Init;
    union {
        const char *Name;
        struct Expr *Index;
    };
} CompoundField;*/


typedef enum TypespecKind {
    TYPESPEC_NONE,
    TYPESPEC_NAME,
    TYPESPEC_FUNC,
    TYPESPEC_ARRAY,
    TYPESPEC_PTR,
    
} TypespecKind;


const char *TypespecKindStrings[ ] = 
{   "TYPESPEC_NONE",
    "TYPESPEC_NAME",
    "TYPESPEC_FUNC",
    "TYPESPEC_ENUM",
    "TYPESPEC_ARRAY",
    "TYPESPEC_PTR",
    "TYPESPEC_I64",
    "TYPESPEC_CHAR",
    "TYPESEPC_BOOL",
};


typedef struct Typespec {
    TypespecKind kind;
    union {
        const char *name;
        
        struct {
            struct PList *Args;
            size_t NumArgs;
            struct Typespec *Ret;
        }Func;
        struct {
            struct Typespec *Elem;
            struct Expr *Size;
        }Array;
        
        struct {
            struct Typespec *Elem;
        }Ptr;
    };
}Typespec;

typedef struct Expr {
    ExprKind kind;
    union {
        int64_t IntVal;
        double FloatVal;
        const char *StringVal;
        const char *Name;
        struct {
            Typespec *Type;
            PList *Fields;
            size_t NumFields;
            
            
        }Compound;
        
        struct {
            struct Typespec *Type;
            struct Expr *expr;            
        }Cast;
        
        struct {
            TokenKind Op;
            struct Expr *expr;
        }Unary;
        Typespec *SizeofType;
        
        struct
        {
            TokenKind Op;
            struct Expr *Left;
            struct Expr *Right;
            
        }Binary;
        
        struct {
            struct Expr *Condition;
            struct Expr *ThenExpression;
            struct Expr *ElseExpression;
        }Ternary;
        
        struct {
            struct Expr *Expression;
            PList *Args;
            size_t NumArgs;            
        }Call;
        
        struct {
            struct Expr *expr;
            struct Expr *Index;
        }Index;
        struct {
            struct Expr *expr;
            const char *Name;
        }Field;
        
        struct Expr *SizeofExpression;
        
    };
}Expr;

typedef struct VarDecl {
    Typespec *type;
    Expr *expr;
} VarDecl;

typedef struct AggregateItem
{
    PList *Names;
    size_t NumNames;
    Typespec *Type;
    
}AggregateItem;

typedef struct EnumItem {
    const char *Name;
    Expr *Init;
    struct EnumItem *Next;
} EnumItem;


typedef struct FuncParam {
    const char *Name;
    Typespec *Type;
    struct FuncParam *Next;
} FuncParam;

typedef enum StatementKind {
    STMT_NONE,
    STMT_DECL,
    STMT_RETURN,
    STMT_BREAK,
    STMT_CONTINUE,
    STMT_BLOCK,
    STMT_IF,
    STMT_WHILE,
    STMT_DO_WHILE,
    STMT_FOR,
    STMT_SWITCH,
    STMT_ASSIGN,
    STMT_INIT,
    STMT_EXPR,
} StatementKind;

typedef struct Statement Statement;

typedef struct StatementList StatementList;
struct StatementList
{
    PList *Statements;
    size_t NumOfStatements;
    
};


typedef struct ElseIf
{
    
    Expr *Cond;
    StatementList *Block;
    
}ElseIf;


struct Statement
{
    StatementKind Kind;
    union
    {
        Expr *Expression;
        struct Decl *Declaration;
        struct
        {
            const char *Name;
            Expr *Expression;
        }Initialisation;
        
        struct {
            Expr *Cond;
            StatementList *Block;
        }WhileStatement;
        
        struct {
            Expr *expr;
            PList *Cases;
            size_t NumOfCases;            
        }SwitchStatement;
        
        struct
        {
            Expr *Cond;
            StatementList *ThenBlock;
            PList*ElseIfs;
            size_t NumElseIfs;
            StatementList *ElseBlock;   
            
        }IfStatement;
        
        struct {
            TokenKind Op;
            Expr *Left;
            Expr *Right;
        }Assign;
        
        struct {
            Statement *Init;
            Expr *Cond;
            Statement *Next;
            StatementList *Block;
        } ForStatement;
        
        StatementList *Block;
    };
    
};

typedef struct ConstantDecl
{
    Expr *Expression;
    
}ConstantDecl;

typedef struct Decl {
    
    DeclKind kind;
    const char *name;
    union {
        struct {
            PList*Items;
            size_t NumItems;
        } EnumDecl;
        struct {
            PList *AggregateItems;
            size_t NumItems;
        } Aggregate;
        
        struct {
            PList*Params;
            size_t NumOfParams;
            Typespec *RetType;
            StatementList*Block;
        }Func;
        
        struct {
            Typespec *Type;
        } TypedefDecl;
        
        
        VarDecl var;
        ConstantDecl ConstDecl;
        
    };
}Decl;

Decl *DeclNew(const char *Name, DeclKind Kind)
{
    Decl *D = malloc(sizeof(Decl));
    D->kind = Kind;
    D->name = Name;
    return D;
}



Decl *
DeclConst(const char *Name, Expr *Expression)
{
    Decl *D = DeclNew(Name, DECL_CONST);
    D->name = Name;
    D->ConstDecl.Expression = Expression;
    return D;
}


typedef struct SwitchCase
{
    PList *Exprs;
    size_t NumOfExprs;
    bool32 IsDefault;
    StatementList *Block;
    
}SwitchCase;