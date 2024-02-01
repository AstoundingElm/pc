void PrintTypespec(Typespec *type);

void PrintExpression(Expr *expr)
{
    Expr *e = expr;
    
    switch(e->kind)
    {
        case EXPR_NONE:{}break;
        case EXPR_I64:
        {
            //printf("\t");
            printf("%lld", e->IntVal);
        }break;
        
        case EXPR_FLOAT:
        {
            //printf("\t");
            printf("%f", e->FloatVal);
        }break;
        case EXPR_STR:
        {
            //printf("\t");
            printf("%s", e->StringVal); 
        }break;
        case EXPR_NAME:
        {
            //printf("\t");
            printf("%s", e->Name);
        }break;
        case EXPR_CAST:{}break;
        case EXPR_CALL:
        {
            PrintExpression(e->Call.Expression);
            
            Expr* ExprPtr = NULL;
            while((ExprPtr = RemoveFromPList(e->Call.Args)) != NULL){
                
                PrintExpression(ExprPtr);
            }
            
            
        }break;
        case EXPR_INDEX:
        {
            printf("\t");
            printf("\n");
            printf("Index");
            PrintExpression(e->Index.expr);
            printf("\n");
            printf("\t");
            PrintExpression(e->Index.Index);
        }break;
        case EXPR_FIELD:
        {
            PrintExpression(e->Field.expr);
            printf(" %s", e->Field.Name);
            
        }break;
        case EXPR_COMPOUND:
        {
            printf("\t");
            printf("EXPR_COMPOUND\n");
            if(e->Compound.Type)
            {
                PrintTypespec(e->Compound.Type);
                
            }
            
            Expr* ExprPtr = NULL;
            while((ExprPtr = RemoveFromPList(e->Compound.Fields)) != NULL){
                
                PrintExpression(ExprPtr);
            }
            
        }break;
        case EXPR_UNARY:
        {
            
            printf(" %s ", TokToString(e->Unary.Op));
            PrintExpression(e->Unary.expr);
            printf("\n");
        }break;
        case EXPR_BINARY:
        {
            PrintExpression(e->Binary.Left);
            
            printf(" %s ", TokToString(e->Binary.Op));
            
            PrintExpression(e->Binary.Right);
            printf("\n");
        }break;
        case EXPR_TERNARY:
        {
            printf("\t");
            printf("EXPR_TERNARY\n");
            PrintExpression(e->Ternary.Condition);
            PrintExpression(e->Ternary.ThenExpression);
            PrintExpression(e->Ternary.ElseExpression);
            
        }break;
        case EXPR_SIZEOF_EXPR:
        {
            printf("SizeofExpression");
            PrintExpression(e->SizeofExpression);
            
        }break;
        case EXPR_SIZEOF_TYPE:
        {
            printf("SizeofType ");
            PrintTypespec(e->SizeofType);
            
        }break;
        
        default:
        {
            printf("Default in PrintExpression"); 
            exit(-1);
        }
    }
    
}

void PrintAggregateDecl(Decl *decl)
{
    Decl *d = decl;
    
    AggregateItem* ItemPtr = NULL;
    while((ItemPtr = RemoveFromPList(d->Aggregate.AggregateItems)) != NULL){
        
        
        const char* NamesPtr = NULL;
        while((NamesPtr = RemoveFromPList(ItemPtr->Names)) != NULL){
            
            printf("\t");
            printf("Names: %s\n", NamesPtr);
            
            PrintTypespec(ItemPtr->Type);
        }
        
    }
}

void PrintDecl(Decl *decl);
void PrintExpression(Expr *expr);
void PrintStatementBlock(StatementList *List);
void PrintStatement(Statement *stmt) {
    Statement *s = stmt;
    switch (s->Kind) {
        case STMT_DECL:
        PrintDecl(s->Declaration);
        break;
        case STMT_RETURN:
        printf("\t");
        printf("return ");
        if (s->Expression) {
            
            PrintExpression(s->Expression);
        }
        
        break;
        case STMT_BREAK:
        printf("\t");
        printf("break\n");
        break;
        case STMT_CONTINUE:
        printf("\t");
        printf("continue\n");
        break;
        case STMT_BLOCK:
        PrintStatementBlock(s->Block);
        break;
        case STMT_IF:
        printf("\t");
        printf("if ");
        PrintExpression(s->IfStatement.Cond);
        
        PrintStatementBlock(s->IfStatement.ThenBlock);
        
        ElseIf *It = NULL;
        while((It = RemoveFromPList(s->IfStatement.ElseIfs)) != NULL){
            printf("\t");
            printf("else if ");
            PrintExpression(It->Cond);
            
            PrintStatementBlock(It->Block);
        }
        if (s->IfStatement.ElseBlock->NumOfStatements != 0) {
            
            printf("\t");
            printf("else ");
            
            PrintStatementBlock(s->IfStatement.ElseBlock);
        }
        
        
        break;
        case STMT_WHILE:
        printf("\t");
        printf("while\n");
        PrintExpression(s->WhileStatement.Cond);
        
        PrintStatementBlock(s->WhileStatement.Block);
        
        break;
        case STMT_DO_WHILE:
        printf("do-while ");
        PrintExpression(s->WhileStatement.Cond);
        PrintStatementBlock(s->WhileStatement.Block);
        break;
        case STMT_FOR:
        
        
        printf("for");
        
        PrintStatement(s->ForStatement.Init);
        PrintExpression(s->ForStatement.Cond);
        PrintStatement(s->ForStatement.Next);
        
        PrintStatementBlock(s->ForStatement.Block);
        
        break;
        case STMT_SWITCH:
        printf("\t");
        printf("switch ");
        
        PrintExpression(s->SwitchStatement.expr);
        printf("\t");
        
        
        SwitchCase *SwitchIt = NULL;
        while((SwitchIt = RemoveFromPList(s->SwitchStatement.Cases)) != NULL)
        {
            printf("\n");
            //printf("\t");
            printf("\t");
            printf("case %s", SwitchIt->IsDefault ? " default" : "");
            
            
            Expr *ExprIt = NULL;
            while((ExprIt = RemoveFromPList(SwitchIt->Exprs)) != NULL)
            {
                //printf("\t");
                
                PrintExpression(ExprIt);
                //printf("\n");
            }
            
            
            printf("\n");
            PrintStatementBlock(SwitchIt->Block);
            
        }
        
        break;
        case STMT_ASSIGN:
        
        printf("%s ", TokToString(s->Assign.Op));
        PrintExpression(s->Assign.Left);
        if (s->Assign.Right) {
            printf("\t");
            PrintExpression(s->Assign.Right);
        }
        
        break;
        case STMT_INIT:
        
        printf(":= %s ", s->Initialisation.Name);
        PrintExpression(s->Initialisation.Expression);
        
        break;
        case STMT_EXPR:
        
        PrintExpression(s->Expression);
        break;
        default:
        printf("Default case in PrintStatement\n");
        exit(-1);
        break;
    }
    
    //printf("\n");
}

void PrintStatementBlock(StatementList *List)
{
    Statement *It = NULL;
    
    while((It = RemoveFromPList(List->Statements)) != NULL)
    {
        PrintStatement(It);
    }
}

void PrintTypespec(Typespec *type) {
    Typespec *t = type;
    switch (t->kind) {
        case TYPESPEC_NAME:
        printf("\t");
        printf("%s\n", t->name);
        break;
        case TYPESPEC_FUNC:
        printf("func");
        
        Typespec *It = NULL;
        while((It = RemoveFromPList(t->Func.Args)) != NULL)
        {
            PrintTypespec(It);
        }
        printf(" ) ");
        PrintTypespec(t->Func.Ret);
        printf(")");
        break;
        case TYPESPEC_ARRAY:
        printf("\t");
        printf("array \n");
        PrintTypespec(t->Array.Elem);
        printf("\t");
        printf("Index: ");
        PrintExpression(t->Array.Size);
        
        break;
        case TYPESPEC_PTR:
        printf("(ptr ");
        PrintTypespec(t->Ptr.Elem);
        //printf(")");
        break;
        default:
        PCAssert(0, "PrintTypespec default case\n");
        break;
    }
}

void PrintDecl(Decl *decl)
{
    Decl *d = decl;
    switch(d->kind){
        
        case DECL_NONE: {}break;
        case DECL_ENUM: 
        {
            printf("DECL_ENUM:\n");
            printf("\t");
            printf(" %s\n", d->name);
            
            EnumItem* ItemPtr = NULL;
            while((ItemPtr = RemoveFromPList(d->EnumDecl.Items)) != NULL){
                
                printf("Names: %s\n", ItemPtr->Name);
                //PrintExpression(ItemPtr);
            }
            
        }break;
        case DECL_STRUCT:
        {
            
            printf("DECL_STRUCT:\n");
            printf("\t");
            printf("%s\n", d->name);
            
            PrintAggregateDecl(d);
            
        }break;
        case DECL_UNION: 
        {
            printf("DECL_UNION: \n");
            printf("\t");
            printf(" %s\n", d->name);
            
            PrintAggregateDecl(d);
            
        }break;
        case DECL_VAR: {
            
            printf("DECL_VAR: \n");
            
            printf("\t");
            printf("VarName: %s\n", d->name);
            
            if (d->var.type) {
                PrintTypespec(d->var.type);
            }
            
            if(d->var.expr)
            {
                printf("\t");
                PrintExpression(d->var.expr);
            }
            
            printf("\n");
        }break;
        
        case DECL_CONST:
        {
            
        }break;
        case DECL_TYPEDEF: 
        {
            
        }break;
        case DECL_FUNC: 
        {
            
            printf("DECL_FUNC:\n");
            printf("\t");
            printf("%s\n", d->name);
            FuncParam *It = NULL;
            
            while((It = RemoveFromPList(d->Func.Params)) != NULL)
            {
                printf("\t");
                printf("Params: %s\n", It->Name);
                PrintTypespec(It->Type);
            }
            
            printf("\n");
            
            if(d->Func.RetType)
            {
                PrintTypespec(d->Func.RetType);
            }
            
            PrintStatementBlock(d->Func.Block);
            
        }break;
        default:
        {
            printf("Default case in PrintDecl\n");
            exit(-1);
        }
        
    }
    
    printf("\n");
}