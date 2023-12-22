typedef struct ptoken
{
    int Kind;
    int Value;
    char *ID;
    const char *Text;
    
    
}PToken;

const char *PSource;

typedef enum TokenKind
{
    TOK_EOF,
    
    TOK_ID,
    TOK_INTLIT,
    
    TOK_LPAREN,
    TOK_RPAREN,
    TOK_LBRACE,
    TOK_RBRACE,
    TOK_LBRACK,
    TOK_RBRACK,
    
    TOK_SEMI,
    TOK_BIN_OP,
    
    TOK_STAR = TOK_BIN_OP,
    TOK_SLASH,
    TOK_PERCENT,
    TOK_PLUS,
    TOK_EQUALS,
    TOK_MINUS,
    TOK_COMMA,
    TOK_BIN_OP_END,
    TOK_KW,
    TOK_COLON,
    TOK_COUNT,
}TokenKind;

PToken Tok;

typedef enum DeclKind {
    DECL_ROOT,
    DECL_NONE,
    DECL_ENUM,
    DECL_PSTRUCT,
    DECL_UNION,
    DECL_PVAR,
    DECL_CONST,
    DECL_TYPEDEF,
    DECL_FUNC,
    
} DeclKind;

char * DeclKindStrings[] = 
{
    "DECL_ROOT",
    "DECL_NONE",
    "DECL_ENUM",
    "DECL_PSTRUCT",
    "DECL_UNION",
    "DECL_PVAR",
    "DECL_CONST",
    "DECL_TYPEDEF",
    "DECL_FUNC",
};

typedef enum ExprKind {
    EXPR_NONE,
    EXPR_INT,
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
    EXPR_SIZEOF,
} ExprKind;

typedef struct Expr {
    ExprKind kind;
    union {
        uint64_t int_val;
        double float_val;
        const char *str_val;
        const char *name;
        /*CompoundExpr compound;
        CastExpr cast;
        UnaryExpr unary;
        BinaryExpr binary;
        TernaryExpr ternary;
        CallExpr call;
        IndexExpr index;
        FieldExpr field;
        SizeofExpr sizeof_expr;*/
    };
}Expr;


typedef enum TypespecKind {
    TYPESPEC_NONE,
    TYPESPEC_NAME,
    TYPESPEC_FUNC,
    TYPESPEC_ENUM,
    TYPESPEC_ARRAY,
    TYPESPEC_PTR,
    TYPESPEC_I64,
} TypespecKind;


const char *TypespecKindStrings[ ] = 
{   "TYPESPEC_NONE",
    "TYPESPEC_NAME",
    "TYPESPEC_FUNC",
    "TYPESPEC_ENUM",
    "TYPESPEC_ARRAY",
    "TYPESPEC_PTR",
    "TYPESPEC_I64",
};


typedef struct Typespec {
    TypespecKind kind;
    union {
        const char *name;
        //FuncTypespec func;
        //ArrayTypespec array;
        //PtrTypespec ptr;
    };
}Typespec;

typedef struct VarDecl {
    Typespec *type;
    Expr *expr;
} VarDecl;


typedef struct AggItemName
{
    const char *Name;
    struct AggItemName *Next;
    
}AggItemName;

typedef struct AggregateItem
{
    //const char **Names;
    //const char *Name;
    AggItemName *Names;
    size_t NumNames;
    Typespec *Type;
    struct AggregateItem *Next;
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

typedef struct PList PList;


typedef struct Statement Statement;

typedef struct StatementList StatementList;
struct StatementList
{
    PList *Statements;
    size_t NumOfStatements;
    
};


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
        //StatementList *Block;
        PList *Block;
    };
    
};

typedef struct Decl {
    struct Decl *Next;
    DeclKind kind;
    const char *name;
    union {
        struct {
            EnumItem *Items;
            size_t NumItems;
            struct EnumDecl *Next;
        } EnumDecl;
        struct {
            //AggregateItem *items;
            //Buffer *items;
            AggregateItem *Items;
            size_t num_items;
        } aggregate;
        
        struct {
            FuncParam *Params;
            size_t NumOfParams;
            Typespec *RetType;
            StatementList *Block;
        }Func;
        //FuncDecl func;
        //TypedefDecl typedef_decl;
        VarDecl var;
        //ConstDecl const_decl;
    };
}Decl;
