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
    DECL_NONE,
    DECL_ENUM,
    DECL_CSTRUCT,
    DECL_PSTRUCT,
    DECL_UNION,
    DECL_CVAR,
    DECL_PVAR,
    DECL_CONST,
    DECL_TYPEDEF,
    DECL_FUNC,
    
} DeclKind;

char * DeclKindStrings[] = 
{
    "DECL_NONE",
    "DECL_ENUM",
    "DECL_CSTRUCT",
    "DECL_PSTRUCT",
    "DECL_UNION",
    "DECL_CVAR",
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
    TYPESPEC_ARRAY,
    TYPESPEC_PTR,
    TYPESPEC_CINT,
    TYPESPEC_I64,
} TypespecKind;


const char *TypespecKindStrings[ ] = 
{   "TYPESPEC_NONE",
    "TYPESPEC_NAME",
    "TYPESPEC_FUNC",
    "TYPESPEC_ARRAY",
    "TYPESPEC_PTR",
    "TYPESPEC_CINT",
    "TYPESPEC_INT",
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


typedef struct AggregateItem
{
    //const char **Names;
    Buffer * Names;
    size_t NumNames;
    Typespec *Type;
    
}AggregateItem;


typedef struct Decl {
    DeclKind kind;
    const char *name;
    union {
        //EnumDecl enum_decl;
        struct {
            //AggregateItem *items;
            Buffer *items;
            size_t num_items;
        } aggregate;
        //FuncDecl func;
        //TypedefDecl typedef_decl;
        VarDecl var;
        //ConstDecl const_decl;
    };
}Decl;
