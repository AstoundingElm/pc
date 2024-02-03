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
    
    if (MatchToken(TOK_LBRACK)) {
        
        
        Expr *Index = ParseExpression();
        TokExpect(TOK_RBRACK, "]");
        
        TokExpect(TOK_ASSIGN, "=");
        
        CompoundField *Field = malloc(sizeof(CompoundField));
        Field->Kind = FIELD_INDEX;
        Field->Init = ParseExpression();
        Field->Index = Index;
        
        return Field;
    } else {
        
        
        
        Expr *expr = ParseExpression();
        
        
        if (MatchToken(TOK_ASSIGN)) {
            
            //printf("Comp: %s\n", Tok.Text);
            if (expr->kind != EXPR_NAME) {
                
                printf("Named initializer in compound literal must be preceded by field name");
                exit(-1);
            }
            
            CompoundField *Field = malloc(sizeof(CompoundField));
            Field->Kind = FIELD_NAME;
            //TokNext();
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

Expr *ParseExpressionCompound(Typespec *Type) {
    TokExpect(TOK_LBRACE, "{");
    
    PList *Fields = CreatePList();
    if (!IsToken(TOK_RBRACE)) {
        
        AddToPList(Fields, ParseExpressionCompoundField());
        
        while (MatchToken(TOK_COMMA)) {
            
            AddToPList(Fields, ParseExpressionCompoundField());
            
        }
    }
    
    
    TokExpect(TOK_RBRACE, "}");
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

Expr *ExpressionSizeofExpression(Expr *expr) {
    Expr *E = ExpressionNew(EXPR_SIZEOF_EXPR);
    E->SizeofExpression = expr;
    return E;
}

Expr *ExpressionCast(Typespec *type, Expr *expr) {
    Expr *E = ExpressionNew(EXPR_CAST);
    E->Cast.Type = type;
    E->Cast.expr = expr;
    return E;
}

Expr *ParseExpressionOperand(void) {
    
    if (IsToken(TOK_INTLIT)) {
        
        int64_t Val = Tok.Value;
        TokNext();
        
        return ExprI64(Val);
    }
    
    else if (IsToken(TOK_FLOAT)) {
        double Val = Tok.FloatValue;
        
        TokNext();
        
        
        return ExpressionFloat(Val);
    } else if (MatchToken(TOK_STR)) {
        
        const char *Val = Tok.Text;
        
        TokNext();
        
        TokExpect(TOK_STR, "'");
        return ExpressionString(Val);
        
    } else if ((IsToken(TOK_ID)) && !(IsKeyword("cast")) && !(IsKeyword("sizeof"))) {
        const char *Name = Tok.Text;
        
        TokNext();
        if (IsToken(TOK_LBRACE)) {
            
            return ParseExpressionCompound(TypespecName(Name));
        } else {
            //printf("%s", Tok.Text);
            
            return ExpressionName(Name);
        }
    } else if (MatchKeyword("cast")) {
        
        TokExpect(TOK_LPAREN, "(");
        Typespec *type = ParseType();
        
        TokExpect(TOK_COMMA, ",");
        
        Expr *expr = ParseExpression();
        TokExpect(TOK_RPAREN, ")");
        
        
        return ExpressionCast(type, expr);
        
    }else if (MatchKeyword("sizeof")) {
        
        TokExpect(TOK_LPAREN, "(");
        
        if(MatchToken(TOK_COLON)){
            Typespec *type = ParseType();
            TokExpect(TOK_RPAREN, ")");
            
            return ExpressionSizeofType(type);
        }
        else 
        {
            Expr *expr = ParseExpression();
            TokExpect(TOK_RPAREN, ")");
            return ExpressionSizeofExpression(expr);
        }
    }else if (IsToken(TOK_LBRACE)) {
        
        
        return ParseExpressionCompound(NULL);
    }else if (MatchToken(TOK_LPAREN)) {
        if (MatchToken(TOK_COLON)) {
            
            Typespec *type = ParseType();
            TokExpect(TOK_RPAREN, ")");
            return ParseExpressionCompound(type);
        } else {
            Expr *expr = ParseExpression();
            TokExpect(TOK_RPAREN, ")");
            return expr;
        }
    } else {
        //TokNext();
        //printf("Unexpected token %s in expression\n", Tok.Text);
        //TokNext();
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

Expr *ExpressionIndex(Expr *expr, Expr *Index) {
    Expr *E = ExpressionNew(EXPR_INDEX);
    E->Index.expr = expr;
    E->Index.Index = Index;
    return E;
}

Expr *
ExpressionField(Expr *expr, const char *Name) {
    Expr *E = ExpressionNew(EXPR_FIELD);
    E->Field.expr = expr;
    E->Field.Name = Name;
    return E;
}

Expr *ParseExpressionBase(void) {
    Expr *expr = ParseExpressionOperand();
    
    PList*Args = CreatePList();
    
    while (IsToken(TOK_LPAREN) || IsToken(TOK_LBRACK) || IsToken(TOK_DOT)) {
        if (MatchToken(TOK_LPAREN)) {
            
            if (!IsToken(TOK_RPAREN)) {
                
                AddToPList(Args, ParseExpression());
                while (MatchToken(TOK_COMMA)) {
                    
                    AddToPList(Args, ParseExpression());
                    
                }
            }
            
            TokExpect(TOK_RPAREN, ")");
            expr = ExpressionCall(expr, Args, ListLen(Args));
        } else if (MatchToken(TOK_LBRACK)) {
            Expr *index = ParseExpression();
            TokExpect(TOK_RBRACK, "]");
            expr = ExpressionIndex(expr, index);
        } else {
            
            PCAssert(IsToken(TOK_DOT), "ParseExpression\n");
            TokNext();
            const char *Field = Tok.Text;
            TokExpect(TOK_ID, "Field name\n");
            
            
            
            
            expr = ExpressionField(expr, Field);
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
    return(IsToken(TOK_ADD) ||
           IsToken(TOK_SUB) ||
           IsToken(TOK_MUL) ||
           IsToken(TOK_AND) ||
           IsToken(TOK_NEG) ||
           IsToken(TOK_NOT));
}

Expr *ParseExpressionUnary(void) {
    
    if (IsUnaryOp()) {
        
        TokenKind Op = Tok.Kind;
        TokNext();
        return(ExpressionUnary(Op, ParseExpressionUnary()));
        
    } else {
        
        return(ParseExpressionBase());
    }
}

bool32 IsMulOp(void) {
    return(TOK_FIRST_MUL <= Tok.Kind && Tok.Kind <= TOK_LAST_MUL);
}

Expr *
ParseExpressionMul()
{
    
    Expr *expr = ParseExpressionUnary();
    
    while (IsMulOp()) {
        TokenKind Op = Tok.Kind;
        TokNext();
        expr = ExpressionBinary(Op, expr, ParseExpressionUnary());
    }
    
    return(expr);
}

bool32 IsAddOp(void) {
    return(TOK_FIRST_ADD <= Tok.Kind && Tok.Kind <= TOK_LAST_ADD);
}

Expr *
ParseExpressionAdd()
{
    
    Expr *expr = ParseExpressionMul();
    
    while(IsAddOp())
    {
        TokenKind Op = Tok.Kind;
        TokNext();
        
        expr = ExpressionBinary(Op, expr, ParseExpressionMul());
    }
    
    return(expr);
}

bool32 IsCmpOp(void)
{
    return(TOK_FIRST_CMP <= Tok.Kind && Tok.Kind <= TOK_LAST_CMP);
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
    
    while(MatchToken(TOK_AND_AND))
    {
        expr = ExpressionBinary(TOK_AND_AND, expr, ParseExpressionCmp());
    }
    return expr;
}

Expr *
ParseExpressionOr()
{
    Expr *expr = ParseExpressionAnd();
    while(MatchToken(TOK_OR_OR))
    {
        expr = ExpressionBinary(TOK_OR_OR, expr, ParseExpressionAnd());
    }
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
        
    }
    
    return Expression;
    
}

Expr *
ParseExpression()
{
    return ParseExpressionTernary();
}

Expr *
ExpressionI64(u64 Value)
{
    Expr *E = ExpressionNew(EXPR_I64);
    E->IntVal = Value;
    return E;
}