
Expr *ExpressionNew(ExprKind Kind)
{
    Expr *E = malloc(sizeof(Expr));
    E->kind = Kind;
    return E;
}

Expr* ExprI64(int64_t Value)
{
    Expr *e = ExpressionNew(EXPR_I64);
    e->IntVal = Value;
    
    return e;
}

Expr *
ParseExpression();
CompoundField*
ParseExpressionCompoundField(void) {
    
    if (IsToken(TOK_LBRACK)) {
        TokNext();
        
        Expr *Index = ParseExpression();
        TokNext();
        TokExpect(TOK_RBRACK, "]");
        
        
        TokExpect(TOK_ASSIGN, "=");
        
        CompoundField *Field = malloc(sizeof(CompoundField));
        Field->Kind = FIELD_INDEX;
        Field->Init = ParseExpression();
        Field->Index = Index;
        
        return Field;
    } else {
        
        
        
        Expr *expr = ParseExpression();
        
        
        if (IsToken(TOK_ASSIGN)) {
            
            
            if (expr->kind != EXPR_NAME) {
                
                printf("Named initializer in compound literal must be preceded by field name");
                exit(-1);
            }
            
            CompoundField *Field = malloc(sizeof(CompoundField));
            Field->Kind = FIELD_NAME;
            TokNext();
            Field->Init = ParseExpression();
            Field->Name  = expr->Name;
            
            return Field;
            
        } else {
            CompoundField *Field = malloc(sizeof(CompoundField));
            Field->Kind = FIELD_DEFAULT;
            Field->Init = expr;
            
            return Field;
            
        }
    }
}

Expr *ExpressionCompound(Typespec *Type, PList *Fields, size_t NumFields) {
    Expr *E = ExpressionNew(EXPR_COMPOUND);
    E->Compound.Type = Type;
    E->Compound.Fields =  Fields;
    E->Compound.NumFields = NumFields;
    return E;
}

Expr *
ParseExpressionCompound(Typespec *Type)
{
    
    TokExpect(TOK_LBRACE, "{");
    PList *Fields = CreatePList();
    
    if(!IsToken(TOK_RBRACE))
    {
        
        AddToPList(Fields, ParseExpressionCompoundField());
        
        while(IsToken(TOK_COMMA))
        {
            
            TokNext();
            
            AddToPList(Fields, ParseExpressionCompoundField());
            
            
        }
    }
    
    return ExpressionCompound(Type, Fields, ListLen(Fields));
}

Expr *ExpressionString(const char *StringVal) {
    Expr *E = ExpressionNew(EXPR_STR);
    E->StringVal = StringVal;
    return E;
}


Typespec *
TypespecNew(TypespecKind Kind)
{
    Typespec *T = malloc(sizeof(Typespec));
    T->kind = Kind;
    
    return T;
}


Typespec *
TypespecName(const char *Name)
{
    
    
    Typespec *T = TypespecNew(TYPESPEC_NAME);
    
    T->name = Name;
    
    
    return T;
}

Expr *ExpressionName(const char *Name) {
    Expr *E = ExpressionNew(EXPR_NAME);
    E->Name = Name;
    return E;
}

Expr* 
ExpressionFloat(double FloatVal)
{
    Expr *E = ExpressionNew(EXPR_FLOAT);
    E->FloatVal = FloatVal;
    return E;
}

Typespec *
ParseType();

Expr *ExpressionSizeofType(Typespec *Type) {
    Expr *E = ExpressionNew(EXPR_SIZEOF_TYPE);
    E->SizeofType = Type;
    return E;
}

Expr *ParseExpressionOperand(void) {
    
    //AdvanceFlag = 0;
    if (IsToken(TOK_INTLIT)) {
        
        int64_t Val = Tok.Value;
        TokNext();
        //AdvanceFlag = 1;
        return ExprI64(Val);
    }
    /*else if(IsKeyword("true") || IsKeyword("false"))
    {
        const char *Name = Tok.Text;
        printf("Yes: %s\n", Name);
        TokNext();
        return ExpressionName(Name);
        //return ParseExpressionCompound(TypespecName(Name));
        printf("right here right now\n");
    }*/
    
    else if (IsToken(TOK_FLOAT)) {
        double Val = Tok.FloatValue;
        TokNext();
        return ExpressionFloat(Val);
    } else if (MatchToken(TOK_STR)) {
        
        const char *Val = Tok.Text;
        
        //AdvanceFlag = 1;
        TokNext();
        
        TokExpect(TOK_STR, "'");
        return ExpressionString(Val);
    } else if (IsToken(TOK_ID ) && !IsKeyword("sizeof")) {
        const char *Name = Tok.Text;
        //printf("Id: %s\n", Name);
        TokNext();
        if (IsToken(TOK_LBRACE)) {
            
            return ParseExpressionCompound(TypespecName(Name));
        } else {
            
            return ExpressionName(Name);
        }
    } /*else if (match_keyword(cast_keyword)) {
        expect_token(TOKEN_LPAREN);
        Typespec *type = parse_type();
        expect_token(TOKEN_COMMA);
        Expr *expr = parse_expr();
        expect_token(TOKEN_RPAREN);
        return expr_cast(type, expr);
    }*/ else if (IsKeyword("sizeof")) {
        //AdvanceFlag = 0;
        TokNext();
        TokExpect(TOK_LPAREN, "(");
        
        Typespec *type = ParseType();
        
        TokExpect(TOK_RPAREN, ")");
        //TokNext();
        //TokNext();
        return ExpressionSizeofType(type);
        //}
        /*else {
               Expr *expr = ParseExpression();
               TokExpect(TOKEN_RPAREN);
               return ExpressionSizeofExpression(expr);
           }*/
    } else if (strcmp(Tok.Text,"{") == 0) {
        
        return ParseExpressionCompound(NULL);
    }else if (MatchToken(TOK_LPAREN)) {
        
        printf("swah");
        exit(-1);
        if (MatchToken(TOK_COLON)) {
            /*
            Typespec *type = parse_type();
            expect_token(TOKEN_RPAREN);
            return parse_expr_compound(type);*/
        } else {
            Expr *expr = ParseExpression();
            TokExpect(TOK_RPAREN, ")");
            return expr;
        }
    } else {
        printf("Unexpected token %s in expression\n", Tok.Text);
        exit(-1);
        return NULL;
    }
}

Expr *
ExpressionCall(Expr *Expression, PList *Args, size_t NumArgs) {
    Expr *e = ExpressionNew(EXPR_CALL);
    e->Call.Expression = Expression;
    e->Call.Args = Args;
    e->Call.NumArgs = NumArgs;
    return e;
}

Expr *ParseExpressionBase(void) {
    Expr *expr = ParseExpressionOperand();
    
    PList*Args = CreatePList();
    //if(PeekToken(TOK_LPAREN)
    while (IsToken(TOK_LPAREN) || IsToken(TOK_LBRACK) || IsToken(TOK_DOT)) {
        if (MatchToken(TOK_LPAREN)) {
            
            
            if (!IsToken(TOK_RPAREN)) {
                
                AddToPList(Args, ParseExpression());
                /*while (MatchToken(TOK_COMMA)) {
                    TokNext();
                    AddToPList(Args, ParseExpression);
                    TokNext();
                    //buf_push(args, parse_expr());
                }*/
            }
            
            TokExpect(TOK_RPAREN, ")");
            expr = ExpressionCall(expr, Args, ListLen(Args));
        } else if (IsToken(TOK_LBRACK)) {
            /*Expr *index = parse_expr();
            expect_token(TOKEN_RBRACKET);
            expr = expr_index(expr, index);*/
        } else {
            //printf("jere");
            /*assert(is_token(TOKEN_DOT));
            next_token();
            const char *field = token.name;
            expect_token(TOKEN_NAME);
            expr = expr_field(expr, field);*/
        }
    }
    return expr;
}



Expr *
ExpressionBinary(TokenKind Op, Expr *Left, Expr *Right) {
    Expr *E = ExpressionNew(EXPR_BINARY);
    E->Binary.Op = Op;
    E->Binary.Left = Left;
    E->Binary.Right = Right;
    return E;
}

Expr *ExpressionUnary(TokenKind Op, Expr *expr) {
    Expr *E = ExpressionNew(EXPR_UNARY);
    E->Unary.Op = Op;
    E->Unary.expr = expr;
    return E;
}

bool32 IsUnaryOp(void) {
    return
        IsToken(TOK_ADD) ||
        IsToken(TOK_MUL) ||
        IsToken(TOK_AND) ||
        IsToken(TOK_NEG) ||
        IsToken(TOK_NOT);
}

Expr *ParseExpressionUnary(void) {
    
    
    if (IsUnaryOp() ) {
        printf("UnaryOp: %s\n", Tok.Text);
        
        TokenKind Op = Tok.Kind;
        
        TokNext();
        printf("%s\n", Tok.Text);
        
        return ExpressionUnary(Op, ParseExpressionUnary());
        
        
    } else {
        
        
        return ParseExpressionBase();
        
    }
}

Expr *
ParseExpressionMul()
{
    
    Expr *expr = ParseExpressionUnary();
    
    while (IsToken(TOK_MUL)) {
        TokenKind Op = Tok.Kind;
        TokNext();
        expr = ExpressionBinary(Op, expr, ParseExpressionUnary());
    }
    
    return expr;
}



Expr *
ParseExpressionAdd()
{
    
    Expr *expr = ParseExpressionMul();
    
    
    while(IsToken(TOK_ADD) || IsToken(TOK_NEG))
    {
        TokenKind Op = Tok.Kind;
        TokNext();
        
        expr = ExpressionBinary(Op, expr, ParseExpressionMul());
    }
    
    
    return expr;
}

bool32 IsCmpOp()
{
    if(IsToken(TOK_CMP) || IsToken(TOK_LTEQ))
    {
        //|| IsToken(TOK_LTEQ)
        return PTrue;
    }
    
    return PFalse;
}

Expr *
ParseExpressionCmp()
{
    
    Expr *expr = ParseExpressionAdd();
    
    while(IsCmpOp())
    {
        
        TokenKind Op = Tok.Kind;
        
        TokNext();
        
        expr = ExpressionBinary(Op, expr, ParseExpressionAdd());
    }
    
    return expr;
    
    
    
}

Expr *
ParseExpressionAnd()
{
    Expr *expr = ParseExpressionCmp();
    return expr;
}

Expr *
ParseExpressionOr()
{
    Expr *expr = ParseExpressionAnd();
    return expr;
}

Expr *
ExpressionTernary(Expr *Condition, Expr *ThenExpression, Expr *ElseExpression) 
{
    Expr *E = ExpressionNew(EXPR_TERNARY);
    E->Ternary.Condition = Condition;
    E->Ternary.ThenExpression = ThenExpression;
    E->Ternary.ElseExpression = ElseExpression;
    return E;
    
    
}


Expr *
ParseExpressionTernary()
{
    Expr *Expression = ParseExpressionOr();
    
    if(MatchToken(TOK_QUESTION)){
        
        Expr *ThenExpression = ParseExpressionTernary();
        
        TokExpect(TOK_COLON, ":");
        
        Expr *ElseExpression = ParseExpressionTernary();
        
        Expression = ExpressionTernary(Expression, ThenExpression, ElseExpression);
        
        return Expression;
    }
    
    return Expression;
    
}

Expr *
ParseExpression()
{
    return ParseExpressionTernary();
}

typedef uint64_t u64;


Expr *
ExpressionI64(u64 Value)
{
    Expr *E = ExpressionNew(EXPR_I64);
    E->IntVal = Value;
    return E;
}