
Statement *
ParseStatement();
StatementList *
StmtList();
Statement *StatementNew(StatementKind Kind);
//bool32 IsStruct = 0;
//bool32 CharArray = 0;
Typespec *
ParseBaseType()
{
    //IsStruct  = 0;
    //CharArray = 0;
    Typespec *Type = NULL;
    
    
    
    /*if(IsKeyword("bool"))
    {
        Type = TypespecNew(TYPESPEC_BOOL);
        Type->name = "bool";
        TokNext();
    }
    
    if(IsKeyword("char"))
    {
        
        Type = TypespecNew(TYPESPEC_CHAR);
        Type->name = "char";
        TokNext();
        //CharArray = 1;
        //return Type;
    }
    if(IsKeyword("i64"))
    {
        
        Type = TypespecNew(TYPESPEC_I64);
        Type->name = "i64";
        TokNext();
    }
    */
    if(IsKeyword( "struct"))
    {
        
        //IsStruct = 1;
        Type = (Typespec *)malloc(sizeof(Typespec));
        Type->kind = TYPESPEC_ARRAY;
        Type->name = "struct";
        
    }
    else if(IsKeyword("enum"))
    {
        //EnumFlag = 1;
        Type = (Typespec *)malloc(sizeof(Typespec));
        Type->kind = TYPESPEC_ENUM;
        Type->name = "enum";
        
    }
    
    else if(IsToken(TOK_ID) )
    {
        
        
        Type = TypespecName(Tok.Text);
        
        printf("%s\n", Tok.Text);
        
        TokNext();
        
    }
    
    /*
    else if(IsToken(TOK_ID) && !IsKeyword("i64"))
    {
        Type = TypespecName(Tok.Text);
        ///TokNext();
        
    }*/
    /*else if(IsKeyword("fn"))
    {
        //return ParseTypeFunc();
        Typespec *Type = (Typespec *)malloc(sizeof(Typespec));
        Type->kind = TYPESPEC_FUNC;
        Type->name = "fn";
    }*/
    
    if(Type == NULL){
        printf("Couldn't parse PType!\n");
        exit(-1);
        return NULL;
    }
    
    return Type;
    
    
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
    //if(CharArray)TokNext();
    //if(IsToken(TOK_LBRACK) || IsToken(TOK_MUL)){
    while(IsToken(TOK_LBRACK) || IsToken(TOK_MUL))
    {
        if(MatchToken(TOK_LBRACK))
        {
            Expr *expr = NULL;
            if(!IsToken(TOK_RBRACK))
            {
                expr = ParseExpression();
            }
            //printf("??? %lld\n", expr->IntVal);
            //TokNext();
            
            TokExpect(TOK_RBRACK, "]");
            
            T = TypespecArray(T, expr);
            
            //printf("Rightione: %lld\n", T->Array.Size->IntVal);
            //printf("Rightione: %lld\n", T->Array.Elem->Array.Size->IntVal);
        }else
        {
            PCAssert(IsToken(TOK_MUL), "ParseType\n");
            TokNext();
            //T = TypespecPointer(T);
            exit(-1);
        }
        
    }
    
    
    if(T == NULL){
        printf("ParseType fail");
        exit(-1);
        
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


AggregateItem *
ParseDeclAggregateItem()
{
    
    PList *Names = CreatePList();
    AddToPList(Names, (void *)Tok.Text);
    
    TokNext();
    
    TokExpect(TOK_COLON, ":");
    Typespec *Type = ParseType();
    
    AggregateItem *it = malloc(sizeof(AggregateItem));
    
    it->Names = Names;
    it->Type = Type;
    
    return it;
}


Decl *
DeclAggregate(DeclKind Kind, const char *Name, PList *Items, size_t NumItems)
{
    if(Kind == DECL_STRUCT || Kind == DECL_UNION){
        
        
        
        
        Decl *D = malloc(sizeof(Decl));
        
        D->name = Name;
        D->kind = Kind;
        D->aggregate.AggregateItems = Items; 
        D->aggregate.num_items = NumItems;
        
        return D;
        
    }
    
    
    printf("Not a struct or union");
    exit(-1);
    
}

Decl *
ParseDeclStruct(DeclKind Kind, const char *Name)
{
    if(Kind == DECL_STRUCT || Kind == DECL_UNION)
    {
        
        
        
        TokNext();
        TokExpect(TOK_LBRACE, "{");
        
        PList *Items = CreatePList();
        
        while(!IsToken(TOK_RBRACE) && !IsToken(TOK_EOF))
        {
            
            AddToPList(Items, ParseDeclAggregateItem());
            //TokNext();
            
        }
        
        TokExpect(TOK_RBRACE, "}");
        
        
        return DeclAggregate(DECL_STRUCT, Name, Items, ListLen(Items));
    }
    
    printf("ParseDeclstruct fail\n");
    exit(-1);
    
}

EnumItem *
ParseDeclEnumItem()
{
    
    const char *Name = Tok.Text;
    TokNext();
    Expr *Init = NULL;
    EnumItem *Item = malloc(sizeof(EnumItem));
    Item->Name = Name;
    Item->Init = Init;
    return Item;
}

Decl *
DeclEnum(const char *Name, PList *Items, size_t NumItems)
{
    Decl *D = malloc(sizeof(Decl));
    D->name = Name;
    D->kind = DECL_ENUM;
    D->EnumDecl.Items = Items;
    D->EnumDecl.NumItems = NumItems;
    return D;
    
}

Decl *
ParseDeclEnum(const char *Name)
{
    
    TokNext();
    TokExpect(TOK_LBRACE, "{");
    
    PList *EnumItems = CreatePList();
    
    if(!IsToken(TOK_RBRACE))
    {
        
        AddToPList(EnumItems, ParseDeclEnumItem());
        
        while(IsToken(TOK_COMMA)){
            TokNext();
            AddToPList( EnumItems, ParseDeclEnumItem());
            
        }
    }
    
    TokExpect(TOK_RBRACE, "}");
    
    return DeclEnum(Name, EnumItems, ListLen(EnumItems));
}

Decl *
DeclFunc(const char *Name, PList *Params, size_t NumOfParams, Typespec *ReturnType, StatementList *Block)
{
    Decl *Function = malloc(sizeof(Decl));
    
    Function->name = Name;
    Function->kind = DECL_FUNC;
    Function->Func.Params = Params;
    Function->Func.NumOfParams = NumOfParams;
    Function->Func.RetType = ReturnType;
    Function->Func.Block = Block;
    return Function;
}

FuncParam*
ParseDeclFuncParams()
{
    FuncParam*Param = malloc(sizeof(FuncParam));
    
    if(IsToken(TOK_ID)){
        Param->Name = Tok.Text;
        TokNext();
        
        TokExpect(TOK_COLON, ":");
        
        Typespec *Type = ParseType();
        Param->Type = Type;
    } else
    {
        printf("No func params\n");
        return NULL;
    }
    return Param;
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
    return expr;
}

SwitchCase *
ParseStatementSwitchCase(void)
{
    PList *Exprs = CreatePList();
    bool32 IsDefault = PFalse;
    
    while(IsKeyword("case") || IsKeyword("default"))
    {
        
        if(IsKeyword("case"))
        {
            //printf("Here");
            TokNext();
            AddToPList(Exprs, ParseExpression());
            
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
            IsDefault = PTrue;
        }
        
        
        TokExpect(TOK_COLON, ":");
        
        
    }
    
    //printf("One case\n");
    //printf("%s", Tok.Text);
    PList *Statements = CreatePList();
    while(!IsToken(TOK_EOF) && !IsToken(TOK_RBRACE) && !IsKeyword("case") && !IsKeyword("default"))
    {
        AddToPList(Statements, ParseStatement());
        
    }
    
    SwitchCase * Case = malloc(sizeof(SwitchCase));
    Case->Exprs = Exprs;
    Case->NumOfExprs = ListLen(Exprs);
    Case->IsDefault = IsDefault;
    Case->Block = StmtList(Statements, ListLen(Statements));
    return Case;
}

Statement *StatementNew(StatementKind Kind) {
    Statement *S = malloc(sizeof(Statement));
    S->Kind = Kind;
    return S;
}

Statement *
StatementSwitch(Expr *expr, PList *Cases, size_t NumOfCases) {
    Statement *S = StatementNew(STMT_SWITCH);
    S->SwitchStatement.expr = expr;
    S->SwitchStatement.Cases = Cases;
    S->SwitchStatement.NumOfCases = NumOfCases;
    return S;
}

Statement *ParseStatementSwitch(void)
{
    Expr *expr = ParseParentheseExpression();
    PList *SwitchCases = CreatePList();
    TokExpect(TOK_LBRACE, "{");
    
    while(!IsToken(TOK_EOF) && !IsToken(TOK_RBRACE))
    {
        AddToPList(SwitchCases, ParseStatementSwitchCase());
        
        
    }
    
    TokExpect(TOK_RBRACE, "}");
    
    return StatementSwitch(expr, SwitchCases, ListLen(SwitchCases));
}

Statement *
StatementReturn(Expr *expr) {
    Statement *S = StatementNew(STMT_RETURN);
    S->Expression = expr;
    return S;
}

StatementList *
ParseStatementBlock();

Statement *
StatementIf(Expr *Cond, StatementList *ThenBlock, PList *ElseIfs, size_t NumElseIfs, StatementList *ElseBlock) {
    Statement *S = StatementNew(STMT_IF);
    S->IfStatement.Cond = Cond;
    S->IfStatement.ThenBlock = ThenBlock;
    S->IfStatement.ElseIfs = ElseIfs;
    S->IfStatement.NumElseIfs = NumElseIfs;
    S->IfStatement.ElseBlock = ElseBlock;
    return S;
}

StatementList *
PParseStatementBlock();

Statement*
ParseStatementIf()
{
    Expr* Cond = NULL;
    TokNext();
    
    Cond = ParseExpression();
    
    StatementList *ThenBlock = ParseStatementBlock();
    
    StatementList *ElseBlock = NULL;
    PList *ElseIfs = CreatePList();
    
    while(MatchKeyword("else"))
    {
        
        if(!MatchKeyword("if"))
        {
            
            ElseBlock  = ParseStatementBlock();
            
            break;
        }
        
        Expr *ElseIfCond = ParseExpression();
        
        StatementList *ElseIfBlock = ParseStatementBlock();
        
        ElseIf *elseif = malloc(sizeof(ElseIf));
        elseif->Cond = ElseIfCond;
        elseif->Block = ElseIfBlock;
        AddToPList(ElseIfs, elseif);
        
    }
    
    return StatementIf(Cond, ThenBlock, ElseIfs, ListLen(ElseIfs), ElseBlock);
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

Statement *ParseSimpleStatement(void) {
    Expr *expr = ParseExpression();
    Statement *stmt;
    //printf("Right: %s\n", Tok.Text);
    if (IsToken(TOK_COLON)) {
        
        TokNext();
        if(IsToken(TOK_ASSIGN)){
            TokNext();
            
            if (expr->kind != EXPR_NAME) {
                printf(":= must be preceded by a name");
                return NULL;
            }
            stmt = StatementInit(expr->Name, ParseExpression());
        }
    } 
    else if(IsToken(TOK_INC))
    {
        TokenKind Op = Tok.Kind;
        TokNext();
        stmt = StatementAssign(Op, expr, NULL);
    }
    
    
    
    
    else if(IsToken(TOK_MUL_ASSIGN))
    {
        printf("asdasdRhere");
        exit(-1);
        TokNext();
        
        if(IsToken(TOK_ASSIGN))
        {
            TokNext();
            
            TokenKind Op = Tok.Kind;
            
            
            stmt = StatementAssign(Op, expr, NULL);
        }
        
        
    }
    
    else {
        stmt = StatementExpression(expr);
    }
    
    return stmt;
}

Statement *
StatementFor(Statement *Init, Expr *Cond, Statement *Next, StatementList *Block) {
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



Statement *
ParseStatement()
{
    
    
    if(IsKeyword("for"))
    {
        return ParseStatementFor();
    }
    
    if(IsKeyword("if"))
    {
        
        return ParseStatementIf();
    }
    
    if(MatchKeyword("return"))
    {
        
        Expr *expr = NULL;
        
        expr = ParseExpression();
        
        
        return StatementReturn(expr);
    }
    
    if(IsKeyword("switch"))
    {
        return ParseStatementSwitch();
        
    }else{
        
        Decl *decl = ParseDeclOpt();
        //exit(-1);
        
        /*if(!decl)
        {
            
            printf("Error in ParseStatement\n"); exit(-1);
        }*/
        if(decl){
            //if(AdvanceFlag){TokNext();}
            return StatementDecl(decl);
        }
        
        Statement *stmt = ParseSimpleStatement();
        
        return stmt;
    }
    
}

StatementList *
StmtList(PList *List, size_t NumOfStatements)
{
    StatementList *statement = malloc(sizeof(StatementList));
    statement->Statements = List;
    statement->NumOfStatements = NumOfStatements;
    return statement;
    
}

/*
StatementList *
PParseStatementBlock()
{
    
    TokExpect(TOK_LBRACE, "{");
    
    PList * RStatementList = CreatePList();
    
    while(!IsToken(TOK_EOF) && !IsToken(TOK_RBRACE))
    {
        
        AddToPList(RStatementList, ParseStatement());
        TokNext();
        
    }
    
    TokExpect(TOK_RBRACE, "}");
    
    
    return StmtList(RStatementList, ListLen(RStatementList));
}*/

StatementList *
ParseStatementBlock()
{
    TokExpect(TOK_LBRACE, "{");
    
    PList * RStatementList = CreatePList();
    
    while(!IsToken(TOK_EOF) && !IsToken(TOK_RBRACE))
    {
        
        AddToPList(RStatementList, ParseStatement());
        
        
    }
    
    TokExpect(TOK_RBRACE, "}");
    
    
    return StmtList(RStatementList, ListLen(RStatementList));
}

Decl *
ParseDeclFunction(const char *FnName)
{
    const char *Name = FnName;//Tok.Text;
    
    TokExpect(TOK_LPAREN, "(");
    PList *Params = CreatePList();
    
    if(!IsToken(TOK_RPAREN))
    {
        
        AddToPList(Params, ParseDeclFuncParams());
        
        while(MatchToken(TOK_COMMA))
        {
            
            AddToPList(Params, ParseDeclFuncParams());
            
        }
    }
    
    
    TokNext();
    
    Typespec *ReturnType = NULL;
    
    if(IsToken(TOK_COLON)){
        TokExpect(TOK_COLON, ":");
        
        ReturnType = ParseType();
        
    }
    
    StatementList *Block = ParseStatementBlock();
    
    
    return DeclFunc(Name, Params, 3, ReturnType, Block);
}


Decl *
ParseDeclOpt(void)
{
    //AdvanceFlag = 0;
    //EnumFlag = 0;
    
    if(IsKeyword("typedef"))
    {
        printf("UNIMPLEMENTED\n");
        return NULL;
    }
    
    
    if( IsToken(TOK_ID))
    {
        
        //printf("Name: %s\n", Tok.Text);
        const char *Name = Tok.Text;
        
        TokNext();
        
        if(IsToken(TOK_MUL_ASSIGN)){
            TokNext();
            return NULL;
        }
        
        Expr *expr = NULL;
        
        if(IsToken(TOK_LPAREN))
        {
            
            return ParseDeclFunction(Name);
            
        }
        
        /*if(IsToken(TOK_MUL))
        {
            return DeclPVar(Name, NULL, ParseExpression());
        }*/
        
        
        TokExpect(TOK_COLON, ":");
        
        if(IsToken(TOK_ASSIGN))
        {
            TokExpect(TOK_ASSIGN, "=");
            
            expr = ParseExpression();
            //printf("%d", expr->Op);
            //printf("VarName: %s\n", expr->Name);
            //printf("%s\n", ExprKindStrings[expr->kind]);
            if(expr->kind == EXPR_NAME){
                //printf("Here:%s\n", expr->Name);
                //printf("%d\n", expr->IntVal);
            }
            
            if(!expr) { 
                printf("Error: expr was null\n"); 
                exit(-1);
            }
            
            /*if(AdvanceFlag){
                TokNext();
            }*/
            //TokNext();
            
            return DeclPVar(Name, NULL, expr);
        }
        
        Typespec *Type = ParseType();
        
        //printf("%s", Tok.Text);
        if(IsKeyword("enum"))
        {
            
            return ParseDeclEnum( Name);
            
        }
        
        if(IsKeyword("struct"))
        {
            
            return ParseDeclStruct(DECL_STRUCT, Name);
        }
        
        //if(
        //TokNext();
        //TokNext();
        if(IsToken(TOK_ASSIGN )){
            
            TokExpect(TOK_ASSIGN, "=");
            
            
            expr = ParseExpression();
            
            if(!expr) { 
                printf("Error: expr was null\n"); 
                exit(-1);
            }
            /*if(AdvanceFlag){
                TokNext();
            }*/
            //TokNext();
            
            
            return DeclPVar(Name, Type, expr);
        }
        
        
        
        
        return DeclPVar(Name, Type, expr);
    }
    
    printf("Error in ParseVar\n");
    return NULL;
}

Decl *
ParseDecl(void)
{
    
    Decl *decl = ParseDeclOpt();
    if(!decl){ 
        
        printf("Expected declaration keyword, got %s\n", Tok.Text); 
        exit(-1);
    }
    
    return decl;
}
