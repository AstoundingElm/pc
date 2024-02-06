
Statement *
ParseStatement();
StatementList 
StmtList();
Typespec *
ParseType();

Statement *StatementNew(StatementKind Kind) {
    Statement *S = malloc(sizeof(Statement));
    S->Kind = Kind;
    return S;
}

const char *
ParseName(void)
{
    
    const char *Name = Tok.Text;
    TokExpect(TOK_ID, "ID");
    return Name;
}

Typespec *TypespecFunc(Typespec **Args, size_t NumArgs, Typespec *Ret) {
    Typespec *T = TypespecNew(TYPESPEC_FUNC);
    T->Func.Args = AST_DUP(Args);
    
    T->Func.NumArgs = NumArgs;
    T->Func.Ret = Ret;
    return T;
}

Typespec *ParseTypeFunc(void) {
    Typespec **Args = NULL;
    TokExpect(TOK_LPAREN, "(");
    if (!IsToken(TOK_RPAREN)) {
        buf_push(Args, ParseType());
        
        while (MatchToken(TOK_COMMA)) {
            buf_push(Args, ParseType());
            
        }
    }
    TokExpect(TOK_RPAREN, ")");
    Typespec *Ret = NULL;
    if (MatchToken(TOK_COLON)) {
        Ret = ParseType();
    }
    return TypespecFunc(Args, buf_len(Args), Ret);
}

Typespec *
ParseBaseType()
{
    
    Typespec *Type = NULL;
    
    
    if(IsKeyword( "struct"))
    {
        Type = (Typespec *)malloc(sizeof(Typespec));
        Type->kind = TYPESPEC_ARRAY;
        Type->name = "struct";
        
    }
    
    
    else if(IsKeyword("union"))
    {
        Type = (Typespec *)malloc(sizeof(Typespec));
        Type->kind = TYPESPEC_ARRAY;
        Type->name = "union";
    }
    
    else if(IsKeyword("enum"))
    {
        Type = (Typespec *)malloc(sizeof(Typespec));
        Type->kind = TYPESPEC_ARRAY;
        Type->name = "enum";
    }
    
    else if(MatchKeyword( "func"))
    {
        
        
        return ParseTypeFunc(); 
        
    }
    else if(MatchToken(TOK_LPAREN))
    {
        
        Type = ParseType();
        TokExpect(TOK_RPAREN, ")");
        
    }
    
    else if(IsToken(TOK_ID) && !IsKeyword("enum") )
    {
        
        Type = TypespecName(Tok.Text);
        
        TokNext();
        
    }
    
    if(Type == NULL){
        //printf("Couldn't parse PType!\n");
        //exit(-1);
        return NULL;
    }
    
    return Type;
}

Typespec *
TypespecPtr(Typespec *Elem) 
{
    Typespec *T = TypespecNew(TYPESPEC_PTR);
    T->Ptr.Elem = Elem;
    return T;
}

Typespec *TypespecArray(Typespec *Elem, Expr *Size) {
    Typespec *T = TypespecNew(TYPESPEC_ARRAY);
    T->Array.Elem = Elem;
    T->Array.Size = Size;
    return T;
}

Typespec *
ParseType()
{
    Typespec *T = ParseBaseType();
    
    while(IsToken(TOK_LBRACK) || IsToken(TOK_MUL))
    {
        if(MatchToken(TOK_LBRACK))
        {
            Expr *expr = NULL;
            if(!IsToken(TOK_RBRACK))
            {
                expr = ParseExpression();
            }
            
            TokExpect(TOK_RBRACK, "]");
            
            T = TypespecArray(T, expr);
            
        }else
        {
            
            PCAssert(IsToken(TOK_MUL), "ParseType\n");
            TokNext();
            T = TypespecPtr(T);
            
        }
        
    }
    
    return T;
}

Decl *DeclPVar(const char *Name, Typespec *type, Expr *expr)
{
    Decl *decl = DeclNew( Name, DECL_VAR);
    decl->var.type = type;
    decl->var.expr = expr;
    return decl;
    
}




AggregateItem 
ParseDeclAggregateItem()
{
    const char **Names = NULL;
    buf_push(Names, ParseName());
    
    
    
    while(MatchToken(TOK_COMMA))
    {
        buf_push(Names, ParseName());
        
    }
    
    
    TokExpect(TOK_COLON, ":");
    Typespec *Type = ParseType();
    
    return (AggregateItem){Names, buf_len(Names), Type};
}


Decl *
DeclAggregate(DeclKind Kind, const char *Name, AggregateItem *Items, size_t NumItems)
{
    
    assert(Kind == DECL_STRUCT || Kind == DECL_UNION);
    
    Decl *D = DeclNew(Name, Kind);
    
    D->Aggregate.Items =  AST_DUP(Items);
    D->Aggregate.NumItems = NumItems;
    return D;
}



Decl *
ParseDeclStruct(DeclKind Kind, const char *Name)
{
    PCAssert((Kind == DECL_STRUCT || Kind == DECL_UNION), "ParseDeclStruct\n");
    
    TokNext();
    TokExpect(TOK_LBRACE, "{");
    
    AggregateItem *Items = NULL;
    
    while(!IsToken(TOK_RBRACE) && !IsToken(TOK_EOF))
    {
        
        buf_push(Items, ParseDeclAggregateItem());
        
    }
    
    TokExpect(TOK_RBRACE, "}");
    
    return DeclAggregate(Kind, Name, Items, buf_len(Items));
    
}

EnumItem 
ParseDeclEnumItem()
{
    
    const char *Name = ParseName();
    
    Expr *Init = NULL;
    
    if(MatchToken(TOK_ASSIGN)){
        
        Init = ParseExpression();
    }
    
    return (EnumItem){  Name, Init, NULL};
}

Decl *
DeclEnum(const char *name, EnumItem *Items, size_t NumItems)
{
    Decl *d = DeclNew( name, DECL_ENUM);
    d->EnumDecl.Items = AST_DUP(Items);
    d->EnumDecl.NumItems = NumItems;
    return d;
    
}

Decl *
ParseDeclEnum(const char *Name)
{
    
    TokNext();
    TokExpect(TOK_LBRACE, "{");
    
    EnumItem *items = NULL;
    
    if(!IsToken(TOK_RBRACE))
    {
        
        buf_push(items, ParseDeclEnumItem());
        
        while(MatchToken(TOK_COMMA)){
            
            buf_push(items, ParseDeclEnumItem());
            
        }
    }
    
    TokExpect(TOK_RBRACE, "}");
    
    return DeclEnum(Name, items, buf_len(items));
}

Decl *
DeclFunc(const char *Name, FuncParam *Params, size_t NumParams, Typespec *ReturnType, StatementList Block)
{
    Decl *Function = DeclNew(Name, DECL_FUNC);
    
    
    Function->Func.Params = AST_DUP(Params);
    Function->Func.NumParams = NumParams;
    Function->Func.RetType = ReturnType;
    Function->Func.Block = Block;
    return Function;
}


Decl *
ParseDeclOpt(void);

Statement *StatementDecl(Decl *decl)
{
    Statement *S = StatementNew(STMT_DECL);//malloc(sizeof(Statement));
    S->Declaration = decl;
    return S;
}

Expr *
ParseParentheseExpression(void) {
    
    TokNext();
    TokExpect(TOK_LPAREN, "(");
    Expr *expr = ParseExpression();
    TokExpect(TOK_RPAREN, ")");
    //TokNext();
    return(expr);
}

SwitchCase 
ParseStatementSwitchCase(void)
{
    Expr **exprs = NULL;
    bool32 IsDefault = false;
    
    while(IsKeyword("case") || IsKeyword("default"))
    {
        
        if(IsKeyword("case"))
        {
            TokNext();
            buf_push(exprs, ParseExpression());
            
        }
        else
        {
            if(!IsKeyword("default"))
            { printf("Failed to assert defaultkey in switchparse");
            }
            
            TokNext();
            
            if(IsDefault)
            {
                SyntaxError("Duplicate default labels in same switch case\n");
            }
            IsDefault = true;
        }
        
        
        TokExpect(TOK_COLON, ":");
        
        
    }
    
    Statement **stmts = NULL;
    while(!IsToken(TOK_EOF) && !IsToken(TOK_RBRACE) && !IsKeyword("case") && !IsKeyword("default"))
    {
        buf_push(stmts, ParseStatement());
        
    }
    
    return (SwitchCase){exprs, buf_len(exprs), IsDefault, StmtList(stmts, buf_len(stmts)), };
}



Statement *
StatementSwitch(Expr *expr, SwitchCase *Cases, size_t NumCases) {
    Statement *s = StatementNew(STMT_SWITCH);
    s->SwitchStatement.expr = expr;
    s->SwitchStatement.Cases = AST_DUP(Cases);
    s->SwitchStatement.NumCases = NumCases;
    return s;
}

Statement *ParseStatementSwitch(void)
{
    Expr *expr = ParseParentheseExpression();
    SwitchCase *SwitchCases = NULL;
    TokExpect(TOK_LBRACE, "{");
    
    while(!IsToken(TOK_EOF) && !IsToken(TOK_RBRACE))
    {
        buf_push(SwitchCases, ParseStatementSwitchCase());
        
        
    }
    
    TokExpect(TOK_RBRACE, "}");
    
    return StatementSwitch(expr, SwitchCases, buf_len(SwitchCases));
}

Statement *
StatementReturn(Expr *expr) {
    Statement *S = StatementNew(STMT_RETURN);
    S->Expression = expr;
    return S;
}

StatementList 
ParseStatementBlock();

Statement *
StatementIf(Expr *Cond, StatementList ThenBlock, ElseIf *ElseIfs, size_t NumElseIfs, StatementList ElseBlock) {
    Statement *S = StatementNew(STMT_IF);
    S->IfStatement.Cond = Cond;
    S->IfStatement.ThenBlock = ThenBlock;
    S->IfStatement.ElseIfs = AST_DUP(ElseIfs);
    S->IfStatement.NumElseIfs = NumElseIfs;
    S->IfStatement.ElseBlock = ElseBlock;
    
    return S;
}

Statement*
ParseStatementIf()
{
    Expr* Cond = NULL;
    TokNext();
    
    Cond = ParseExpression();
    
    StatementList ThenBlock = ParseStatementBlock();
    
    StatementList ElseBlock = {0};
    ElseIf *ElseIfs = NULL;
    
    while(MatchKeyword("else"))
    {
        
        
        if(!MatchKeyword("if"))
        {
            
            ElseBlock  = ParseStatementBlock();
            
            break;
        }
        
        Expr *ElseIfCond = ParseExpression();
        
        StatementList ElseIfBlock = ParseStatementBlock();
        
        buf_push(ElseIfs, (ElseIf){ElseIfCond, ElseIfBlock});
        
    }
    
    
    return StatementIf(Cond, ThenBlock, ElseIfs, buf_len(ElseIfs), ElseBlock);
}

Statement *StatementInit(const char *Name, Expr *expr) {
    Statement *s = StatementNew(STMT_INIT);
    s->Initialisation.Name = Name;
    s->Initialisation.Expression = expr;
    return s;
}

Statement *
StatementAssign(TokenKind Op, Expr *Left, Expr *Right) {
    Statement *S = StatementNew(STMT_ASSIGN);
    S->Assign.Op = Op;
    S->Assign.Left = Left;
    S->Assign.Right = Right;
    return S;
}

Statement *StatementExpression(Expr *expr) {
    Statement *s = StatementNew(STMT_EXPR);
    s->Expression = expr;
    return s;
}

bool32 IsAssignOp(void) {
    return TOK_FIRST_ASSIGN <= Tok.Kind && Tok.Kind <= TOK_LAST_ASSIGN;
}

Statement *ParseSimpleStatement(void) {
    Expr *expr = ParseExpression();
    Statement *stmt;
    //printf("%s\n", Tok.Text);
    if(!expr){
        Fatal("In ParseSimpleStatement\n");
    }
    
    if (MatchToken(TOK_COLON_ASSIGN)) {
        
        if (expr->kind != EXPR_NAME) {
            Fatal(":= must be preceded by a name");
            return NULL;
            
        }
        
        stmt = StatementInit(expr->Name, ParseExpression());
        
    } 
    else if(IsAssignOp())
    {
        
        TokenKind Op = Tok.Kind;
        TokNext();
        stmt = StatementAssign(Op, expr, ParseExpression());
    }
    
    else if(IsToken(TOK_INC) || IsToken(TOK_DEC))
    {
        //printf("%s\n", Tok.Text);
        
        TokenKind Op = Tok.Kind;
        TokNext();
        
        stmt = StatementAssign(Op, expr, NULL);
        
    }
    
    else {
        stmt = StatementExpression(expr);
    }
    
    return stmt;
}

Statement *
StatementFor(Statement *Init, Expr *Cond, Statement *Next, StatementList Block) {
    Statement *S = StatementNew(STMT_FOR);
    S->ForStatement.Init = Init;
    S->ForStatement.Cond = Cond;
    S->ForStatement.Next = Next;
    S->ForStatement.Block = Block;
    return S;
}

Statement*
ParseStatementFor()
{
    TokNext();
    Statement *Init = NULL;
    
    if(!IsToken(TOK_SEMI)){
        Init = ParseSimpleStatement();
    }
    
    TokExpect(TOK_SEMI, ";");
    
    Expr *Cond = NULL;
    if(!IsToken(TOK_SEMI))
    { 
        Cond = ParseExpression();
    }
    
    TokExpect(TOK_SEMI, ";");
    
    Statement *Next = NULL;
    
    if(!IsToken(TOK_RBRACE))
    {
        
        Next = ParseSimpleStatement();
        if(Next->Kind == STMT_INIT)
        {
            printf("Init statements not allowed in for-statement's next clause");
            exit(-1);
            
        }
        
    }
    
    return StatementFor(Init, Cond, Next, ParseStatementBlock());
    
}

Expr *ParseParenExpression(void) {
    TokExpect(TOK_LPAREN, "(");
    Expr *expr = ParseExpression();
    TokExpect(TOK_RPAREN, ")");
    return expr;
}
Statement *
StatementDoWhile(Expr *Cond, StatementList Block) {
    Statement *S = StatementNew(STMT_DO_WHILE);
    S->WhileStatement.Cond = Cond;
    S->WhileStatement.Block = Block;
    return S;
}


Statement *
ParseStatementDoWhile(void) {
    
    StatementList Block = ParseStatementBlock();
    if (!MatchKeyword("while")) {
        Fatal("Expected 'while' after 'do' block");
        return NULL;
    }
    Statement *Stmt = StatementDoWhile(ParseParenExpression(), Block);
    
    return Stmt;
}

Statement *StatementWhile(Expr *Cond, StatementList Block) {
    Statement *S = StatementNew(STMT_WHILE);
    S->WhileStatement.Cond = Cond;
    S->WhileStatement.Block = Block;
    return S;
}
Statement *ParseStatementWhile(void) {
    Expr *Cond = ParseParenExpression();
    return StatementWhile(Cond, ParseStatementBlock());
}

Statement *
StatementBlock(StatementList Block) {
    Statement *S = StatementNew(STMT_BLOCK);
    S->Block = Block;
    return S;
}

Statement *
ParseStatement()
{
    
    if(IsKeyword("if"))
    {
        
        return ParseStatementIf();
    }
    else if(MatchKeyword("while"))
    {
        
        return ParseStatementWhile();
    }
    else if(MatchKeyword("do"))
    {
        
        return ParseStatementDoWhile();
    }
    else if(IsKeyword("for"))
    {
        return ParseStatementFor();
    }
    else if(IsKeyword("switch"))
    {
        return ParseStatementSwitch();
        
    }
    else if(IsToken(TOK_LBRACE))
    {
        
        return StatementBlock(ParseStatementBlock());
    }
    
    
    else if(MatchKeyword("return"))
    {
        Expr *expr = NULL;
        if(!IsToken(TOK_RBRACE)){
            
            
            expr = ParseExpression();
        }
        
        return StatementReturn(expr);
    }
    
    else{
        
        
        
        
        Decl *decl = ParseDeclOpt();
        
        if(decl){
            
            return StatementDecl(decl);
        }
        
        Statement *stmt = ParseSimpleStatement();
        
        return stmt;
    }
    
}

StatementList 
StmtList(Statement **Statements, size_t NumStatements)
{
    return (StatementList){AST_DUP(Statements), NumStatements};
    
}

StatementList 
ParseStatementBlock()
{
    TokExpect(TOK_LBRACE, "{");
    Statement **stmts = NULL;
    
    while(!IsToken(TOK_EOF) && !IsToken(TOK_RBRACE))
    {
        buf_push(stmts, ParseStatement());
    }
    
    TokExpect(TOK_RBRACE, "}");
    return StmtList(stmts, buf_len(stmts));
}


FuncParam
ParseDeclFuncParams()
{
    const char *Name = ParseName();
    TokExpect(TOK_COLON, ":");
    Typespec *Type = ParseType();
    return (FuncParam){Name, Type};
    
}


FuncParam
ParseDeclFuncParamsNoError()
{
    FuncParam dummy = {0};
    if(IsToken(TOK_STR)){  GlobalBool = true; return dummy; }
    const char *Name = ParseName();
    TokExpectNoError(TOK_COLON);
    Typespec *Type = ParseType();
    return (FuncParam){Name, Type};
    
}

Decl *
ParseDeclFunctionNoError(const char *FnName)
{
    const char *Name = FnName;
    FuncParam *Params = NULL;
    
    
    
    if(!IsToken(TOK_RPAREN))
    {
        
        buf_push(Params, ParseDeclFuncParamsNoError());
        
        if(GlobalBool)
        {
            return NULL;
        }
        
        while(MatchToken(TOK_COMMA))
        {
            
            buf_push(Params, ParseDeclFuncParams());
            
        }
    }
    
    if(GlobalBool)
    {
        return NULL;
    }
    
    TokExpect(TOK_RPAREN, ")");
    
    Typespec *ReturnType = NULL;
    
    if(MatchToken(TOK_COLON)){
        ReturnType = ParseType();
        
    }
    StatementList Block = ParseStatementBlock();
    
    return DeclFunc(Name, Params, buf_len(Params), ReturnType, Block);
}

Decl *
DeclTypedef(const char *Name, Typespec *Type) {
    Decl *D = DeclNew(Name, DECL_TYPEDEF);
    D->TypedefDecl.Type = Type;
    return D;
}


Decl *
ParseDeclTypedef(void) {
    const char *Name = ParseName();
    TokExpect(TOK_ASSIGN, "=");
    return DeclTypedef(Name, ParseType());
}


Decl *ParseDeclConst(const char *Name) {
    
    //TokExpect(TOK_COLON, ":");
    TokExpect(TOK_ASSIGN, "=");
    
    return DeclConst(Name, ParseExpression());
}


bool32 PeekIsVarID(const char *Src)
{
    Src = " ";
    Src ++;
    return true;
}

Decl *
ParseDeclOpt(void)
{
    GlobalBool = 0;
    
    if(MatchKeyword("typedef"))
    {
        return ParseDeclTypedef();
    }
    else if(IsToken(TOK_ID)){
        
        
        if(IsKeyword("printf"))
        {
            //return NULL;
        }
        const char *Name = Tok.Text;
        
        const char *TempSrc = PSource;
        const char *TempText = Tok.Text;
        TokenKind TempKind = Tok.Kind;
        
        TokNext();
        
        
        if(((!IsToken(TOK_COLON)) && (!IsToken(TOK_LPAREN)) && (!IsToken(TOK_ASSIGN)) && (!IsToken(TOK_LBRACE)) ))
        {
            
            PSource = TempSrc;
            Tok.Text = TempText;
            Tok.Kind = TempKind;
            
            
            
            
            return NULL;
        }
        
        PSource = TempSrc;
        Tok.Text = TempText;
        Tok.Kind = TempKind;
        
        const char *FTempSrc = PSource;
        const char *FTempText = Tok.Text;
        TokenKind FTempKind = Tok.Kind;
        
        TokNext();
        
        
        Expr *expr = NULL;
        
        if(MatchToken(TOK_LPAREN))
        {
            
            Decl *d = ParseDeclFunctionNoError(Name);
            
            if( d == NULL)
            {
                PSource = FTempSrc;
                Tok.Text = FTempText;
                Tok.Kind = FTempKind;
                
                return NULL;
            }
            
            return d;
            
        }
        
        
        
        if(IsToken(TOK_ASSIGN))
        {
            TokExpect(TOK_ASSIGN, "=");
            expr = ParseExpression();
            
            return DeclPVar(Name, NULL, expr);
            
        }
        
        TokExpect(TOK_COLON, ":");
        
        if(IsToken(TOK_COLON))
        {
            TokExpect(TOK_COLON, ":");
            
            return ParseDeclConst(Name);
        }
        
        Typespec *Type = ParseType();
        
        if(IsKeyword("enum"))
            
        {
            
            return ParseDeclEnum( Name);
        }
        
        if(IsKeyword("union"))
        {
            
            return ParseDeclStruct(DECL_UNION, Name);
        }
        
        if(IsKeyword("struct"))
        {
            
            return ParseDeclStruct(DECL_STRUCT, Name);
        }
        
        
        
        if(IsToken(TOK_ASSIGN )){
            
            TokExpect(TOK_ASSIGN, "=");
            
            
            expr = ParseExpression();
            
            if(!expr) { 
                printf("Error: expr was null\n"); 
                exit(-1);
            }
            
            return DeclPVar(Name, Type, expr);
        }
        
        if(Type)
        {
            return DeclPVar(Name, Type, NULL);
        }
        /*if(expr)
        {
            printf("ddd");
            return DeclPVar(Name, NULL, expr);
        }*/
        
    }
    //printf("Null here: %s\n", Tok.Text);
    //printf("Should never get here in ParseDeclOpt\n");
    
    
    return NULL;
}

Decl *
ParseDecl(void)
{
    
    Decl *decl = ParseDeclOpt();
    if(!decl){ 
        
        printf("Expected declaration keyword, got %s\n", Tok.Text); 
        SyntaxError("ParseDecl\n");
        
    }
    
    return decl;
}
