int Indent;

void PrintNewline(void) {
    printf("\n%.*s", 2*Indent, "                                                                      ");
}

void PrintTypespec(Typespec *type);

void PrintExpression(Expr *expr)
{
    Expr *e = expr;
    
    switch(e->kind)
    {
        case EXPR_NONE:{ printf("NONE");}break;
        case EXPR_I64:
        {
            
            printf("%lld ", e->IntVal);
        }break;
        
        case EXPR_FLOAT:
        {
            
            printf("%f ", e->FloatVal);
        }break;
        case EXPR_STR:
        {
            
            printf("%s ", e->StringVal); 
        }break;
        case EXPR_NAME:
        {
            
            printf("%s ", e->Name);
        }break;
        case EXPR_CAST:
        {
            PrintTypespec(e->Cast.Type);
            printf(" ");
            PrintExpression(e->Cast.expr);
            printf(")");
            
        }break;
        case EXPR_CALL:
        {
            PrintExpression(e->Call.Expression);
            
            for (Expr **it = e->Call.Args; it != e->Call.Args + e->Call.NumArgs; it++) {
                
                PrintExpression(*it);
            }
            
            
        }break;
        case EXPR_INDEX:
        {
            
            printf("Index");
            PrintExpression(e->Index.expr);
            
            PrintExpression(e->Index.Index);
        }break;
        case EXPR_FIELD:
        {
            printf("(Field ");
            PrintExpression(e->Field.expr);
            printf(" %s)", e->Field.Name);
            
            
        }break;
        case EXPR_COMPOUND:
        {
            
            printf("(");
            if(e->Compound.Type)
            {
                PrintTypespec(e->Compound.Type);
                
            }
            
            for (CompoundField *it = e->Compound.Fields; it != e->Compound.Fields + e->Compound.NumFields; it++) {
                
                
                if(it->Kind == FIELD_DEFAULT)
                {
                    printf("Nil ");
                }
                else if(it->Kind == FIELD_NAME)
                {
                    
                    printf(" Name: %s", it->Name);
                }
                else
                {
                    PCAssert((it->Kind == FIELD_INDEX), "EXPR_COMPOUND PRINT");
                    printf("Index ");
                    PrintExpression(it->Index);
                    
                }
                
                PrintExpression(it->Init);
            }
            
            
        }break;
        case EXPR_UNARY:
        {
            
            printf("(%s ", TokToString(e->Unary.Op));
            PrintExpression(e->Unary.expr);
            
        }break;
        case EXPR_BINARY:
        {
            printf("(%s", TokToString(e->Binary.Op));
            PrintExpression(e->Binary.Left);
            
            PrintExpression(e->Binary.Right);
            
        }break;
        case EXPR_TERNARY:
        {
            
            printf("(");
            PrintExpression(e->Ternary.Condition);
            PrintExpression(e->Ternary.ThenExpression);
            PrintExpression(e->Ternary.ElseExpression);
            
        }break;
        case EXPR_SIZEOF_EXPR:
        {
            printf("(");
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
    
    for (AggregateItem *it = d->Aggregate.Items; it != d->Aggregate.Items + d->Aggregate.NumItems; it++) {
        
        PrintNewline();
        
        
        for (const char **name = it->Names; name != it->Names + it->NumNames; name++) {
            
            printf("%s", *name);
        }
        
        PrintTypespec(it->Type);
        
    }
    
    PrintNewline();
    
}

void PrintDecl(Decl *decl);
void PrintExpression(Expr *expr);
void PrintStatementBlock(StatementList List);
void PrintStatement(Statement *stmt) {
    Statement *s = stmt;
    switch (s->Kind) {
        case STMT_DECL:
        PrintDecl(s->Declaration);
        break;
        case STMT_RETURN:
        
        printf("return ");
        if (s->Expression) {
            
            PrintExpression(s->Expression);
        }
        
        break;
        case STMT_BREAK:
        
        printf("break");
        break;
        case STMT_CONTINUE:
        
        printf("continue");
        break;
        case STMT_BLOCK:
        printf("block");
        PrintStatementBlock(s->Block);
        break;
        case STMT_IF:
        
        printf("if ");
        PrintExpression(s->IfStatement.Cond);
        Indent++;
        PrintNewline();
        PrintStatementBlock(s->IfStatement.ThenBlock);
        
        for (ElseIf *it = s->IfStatement.ElseIfs; it != s->IfStatement.ElseIfs + s->IfStatement.NumElseIfs; it++) {
            
            PrintNewline();
            printf("else if ");
            PrintExpression(it->Cond);
            PrintNewline();
            PrintStatementBlock(it->Block);
        }
        
        if(s->IfStatement.ElseBlock.NumStatements != 0){
            PrintNewline();
            printf("else ");
            PrintNewline();
            PrintStatementBlock(s->IfStatement.ElseBlock);
        }
        Indent--;
        
        break;
        case STMT_WHILE:
        
        printf("while");
        PrintExpression(s->WhileStatement.Cond);
        Indent++;
        PrintNewline();
        PrintStatementBlock(s->WhileStatement.Block);
        Indent--;
        break;
        case STMT_DO_WHILE:
        printf("do-while ");
        PrintExpression(s->WhileStatement.Cond);
        Indent++;
        PrintNewline();
        PrintStatementBlock(s->WhileStatement.Block);
        Indent--;
        break;
        case STMT_FOR:
        
        
        printf("for");
        
        PrintStatement(s->ForStatement.Init);
        PrintExpression(s->ForStatement.Cond);
        PrintStatement(s->ForStatement.Next);
        Indent++;
        PrintNewline();
        PrintStatementBlock(s->ForStatement.Block);
        Indent--;
        break;
        case STMT_SWITCH:
        
        printf("switch ");
        
        PrintExpression(s->SwitchStatement.expr);
        Indent++;
        
        for (SwitchCase *it = s->SwitchStatement.Cases; it != s->SwitchStatement.Cases + s->SwitchStatement.NumCases; it++) {
            PrintNewline();
            printf("case %s", it->IsDefault ? " default" : "");
            
            
            for (Expr **expr = it->exprs; expr != it->exprs + it->NumExprs; expr++) 
            {
                
                PrintExpression(*expr);
                //printf("\n");
            }
            Indent++;
            PrintNewline();
            PrintStatementBlock(it->Block);
            Indent--;
        }
        Indent--;
        break;
        case STMT_ASSIGN:
        
        printf("(%s ", TokToString(s->Assign.Op));
        PrintExpression(s->Assign.Left);
        
        if (s->Assign.Right) {
            
            PrintExpression(s->Assign.Right);
        }
        printf(")");
        break;
        case STMT_INIT:
        //printf("(");
        printf("(:= %s", s->Initialisation.Name);
        PrintExpression(s->Initialisation.Expression);
        printf(")");
        
        
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

void PrintStatementBlock(StatementList block)
{
    printf("Block");
    Indent++;
    for (Statement **it = block.Statements; it != block.Statements + block.NumStatements; it++) 
    {
        PrintNewline();
        PrintStatement(*it);
    }
    Indent--;
    //printf("enblock End");
}

void PrintTypespec(Typespec *type) {
    Typespec *t = type;
    
    if(t){
        switch (t->kind) {
            case TYPESPEC_NAME:
            
            printf(" %s", t->name);
            break;
            case TYPESPEC_FUNC:
            printf("func");
            
            for (Typespec **it = t->Func.Args; it != t->Func.Args + t->Func.NumArgs; it++) 
            {
                PrintTypespec(*it);
            }
            printf(" ) ");
            PrintTypespec(t->Func.Ret);
            printf(")");
            break;
            case TYPESPEC_ARRAY:
            
            printf("array");
            PrintTypespec(t->Array.Elem);
            
            printf("Index:");
            PrintExpression(t->Array.Size);
            
            break;
            case TYPESPEC_PTR:
            printf("(ptr ");
            PrintTypespec(t->Ptr.Elem);
            printf(")");
            
            break;
            default:
            PCAssert(0, "PrintTypespec default case\n");
            break;
        }
    }
}

void PrintDecl(Decl *decl)
{
    Decl *d = decl;
    switch(d->kind){
        
        case DECL_NONE: {}break;
        case DECL_ENUM: 
        {
            printf("DECL_ENUM:");
            
            printf(" %s", d->name);
            Indent++;
            for (EnumItem *it = d->EnumDecl.Items; it != d->EnumDecl.Items + d->EnumDecl.NumItems; it++) {
                
                PrintNewline();
                printf("Names: %s", it->Name);
                if(it->Init){
                    PrintExpression(it->Init);
                }
            }
            Indent--;
            
        }break;
        case DECL_STRUCT:
        {
            
            
            printf("(%s", d->name);
            Indent++;
            PrintAggregateDecl(d);
            Indent--;
            
        }break;
        case DECL_UNION: 
        {
            printf("( ");
            
            printf(" %s", d->name);
            Indent++;
            
            PrintAggregateDecl(d);
            Indent--;
        }break;
        case DECL_VAR: {
            
            printf("Var %s ", d->name);
            
            if (d->var.type) {
                PrintTypespec(d->var.type);
            }
            
            if(d->var.expr)
            {
                
                PrintExpression(d->var.expr);
            }
            
            
        }break;
        
        case DECL_CONST:
        {
            printf("const %s ", d->name);
            PrintExpression(d->ConstDecl.Expression);
            
        }break;
        case DECL_TYPEDEF: 
        {
            
        }break;
        case DECL_FUNC: 
        {
            
            printf("DECL_FUNC:");
            
            printf("%s", d->name);
            
            for (FuncParam *it = d->Func.Params; it != d->Func.Params + d->Func.NumParams; it++) 
            {
                printf("Params: %s", it->Name);
                PrintTypespec(it->Type);
            }
            
            if(d->Func.RetType)
            {
                PrintTypespec(d->Func.RetType);
            }
            
            Indent++;
            PrintNewline();
            PrintStatementBlock(d->Func.Block);
            Indent--;
            
        }break;
        default:
        {
            printf("Default case in PrintDecl\n");
            exit(-1);
        }
        
    }
    
    //printf("\n");
    
}