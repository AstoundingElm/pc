ResolvedExpression
ResolveExpectedExpression(Expr *expr, Type *ExpectedType);

PList *Fields;

Sym*ResolveName(const char *Name);

/*Symb *
SymbolGet(const char *Name)
{
    Symbol *SymPtr = NULL;
    while((SymPtr = (Symbol*)RemoveFromPList(Syms)) != NULL)
    {
        if(SymPtr->Name == Name){
            printf("Found symbol: %s\n", SymPtr->Name);
            return SymPtr;
        }
    }
    
    return NULL;
}

void SymbolPut(Decl *decl)
{
    if(decl->name == NULL)
    {
        printf("No Name in SymbolPut");
        exit(-1);
    }
    if(!SymbolGet(decl->name)) printf( "Symbol already defined");
    Symbol *Sym = malloc(sizeof(Symbol));
    Sym->Name = decl->name;
    Sym->decl = decl;
    Sym->State = SYM_UNRESOLVED;
    AddToPList(Syms, Sym);
}*/


Sym *
SymNew(SymKind Kind, const char *Name, Decl *decl)
{
    Sym *sym = calloc(1, sizeof(Sym));
    
    sym->Kind = Kind;
    sym->Name = Name;
    sym->decl = decl;
    
    return(sym);
}

Type *TypeIncomplete(Sym *sym)
{
    Type *type = malloc(sizeof(Type));
    type->Kind = TYPE_INCOMPLETE;
    type->sym = sym;
    return(type);
}

Sym*
SymDecl(Decl *decl)
{
    SymKind kind = SYM_NONE;
    switch (decl->kind) {
        case DECL_STRUCT:
        case DECL_UNION:
        case DECL_TYPEDEF:
        case DECL_ENUM:
        
        kind = SYM_TYPE;
        
        break;
        case DECL_VAR:
        kind = SYM_VAR;
        break;
        case DECL_CONST:
        kind = SYM_CONST;
        break;
        case DECL_FUNC:
        kind = SYM_FUNC;
        break;
        default:
        PCAssert(0, "Default symdecl\n");
        break;
    }
    
    
    Sym *sym = SymNew(kind, decl->name, decl);
    if (decl->kind == DECL_STRUCT || decl->kind == DECL_UNION) {
        sym->State = SYM_RESOLVED;
        sym->type = TypeIncomplete(sym);
    }
    return sym;
}


Sym*
SymEnumConst(const char*Name, Decl *decl)
{
    return(SymNew(SYM_ENUM_CONST, Name, decl));
}

Sym*
SymGlobalDecl(Decl *decl)
{
    Sym *sym = SymDecl(decl);
    
    AddToPList(GlobalSyms, sym);
    
    if(decl->kind == DECL_ENUM)
    {
        
        EnumItem *EnumIt = NULL;
        while((EnumIt = (EnumItem*)RemoveFromPList(decl->EnumDecl.Items)) != NULL){
            
            AddToPList(GlobalSyms,SymEnumConst(EnumIt->Name, decl));
            
        }
        
    }
    
    return sym;
}


Sym *
SymGet( const char *Name)
{
    
    
    Sym *Lit = NULL;
    for(size_t l = 0; l < ListLen(LocalSyms); l++)
    {
        Lit = RemoveFromPListCopy(LocalSyms, LocalSymsTemp, l);
        
        if(strcmp(Lit->Name, Name) == 0)
        {
            
            
            return Lit;
        }
    }
    
    
    Sym *It = NULL;
    for(size_t i = 0; i < ListLen(GlobalSyms); i++)
    {
        It = RemoveFromPListCopy(GlobalSyms, Temp2, i);
        
        if(strcmp(It->Name, Name) == 0)
        {
            
            
            return It;
        }
        
        
    }
    
    return NULL;
    
}
void CompleteType(Type *type);

Sym *
SymGlobalType(const char* Name, Type *type)
{
    Sym *sym = SymNew(SYM_TYPE, Name, NULL);
    sym->State = SYM_RESOLVED;
    sym->type = type;
    
    AddToPList(GlobalSyms, sym);
    return sym;
}


Sym *ResolveName(const char *Name)
{
    
    Sym *sym = SymGet(Name);
    if(!sym)
    {
        printf("Non-existent name\n");
        printf("Name: %s\n", Name);
        exit(-1);
        return NULL;
    }
    
    ResolveSym(sym);
    return sym;
}

size_t 
TypeSizeof(Type *type) {
    
    PCAssert(((type->Kind) > TYPE_COMPLETING), "TypeSizeof");
    
    PCAssert((type->Size != 0), "TypeSizeof\n");
    return type->Size;
}

ResolvedExpression 
ResolveExpression(Expr *expr);


Type *TypeArray(Type *Elem, size_t Size) {
    
    
    CachedArrayType *It = NULL;
    while((It = RemoveFromPList(CachedArrayTypes)) != NULL){
        if(It->Elem == Elem && It->Size == Size) {
            
            return It->Array;
        }
    }
    
    CompleteType(Elem);
    
    Type *type = TypeAlloc(TYPE_ARRAY);
    
    type->Size = (Size * TypeSizeof(Elem));
    type->Array.Elem = Elem;
    type->Array.Size = Size;
    
    CachedArrayType *ArrayType = malloc(sizeof(CachedArrayType ));
    ArrayType->Elem = Elem;
    ArrayType->Size = Size;
    ArrayType->Array  = type;
    
    AddToPList(CachedArrayTypes, ArrayType );
    return type;
}

int64_t ResolveConstExpression(Expr *expr) {
    ResolvedExpression Result = ResolveExpression(expr);
    
    
    if (!Result.IsConst) {
        printf("%d\n",Result.type->Kind );
        printf("%s\n", expr->Name);
        //Fatal("Expected constant expression");
        
    }
    return Result.Val;
}

Type *
TypePointer(Type *Elem) {
    
    CachedPtrType *It = NULL;
    
    while((It = RemoveFromPList(CachedPtrTypes))!= NULL){
        if (It->Elem == Elem) {
            return It->Ptr;
        }
    }
    Type *type = TypeAlloc(TYPE_PTR);
    type->Size = PTR_SIZE;
    type->Ptr.Elem = Elem;
    
    CachedPtrType *PtrType = malloc( sizeof(CachedPtrType ));
    
    PtrType->Elem = Elem;
    PtrType->Ptr = type;
    
    AddToPList(CachedPtrTypes, PtrType );
    
    return type;
    
}

Type * 
TypeFunc(void *Params, size_t NumParams, Type *Ret);

Type *
ResolveTypespec(Typespec *typespec)
{
    
    if(!typespec)
    {
        return TypeVoid;
    }
    switch(typespec->kind)
    {
        case TYPESPEC_FUNC: {
            //PList *Args = CreatePList();
            
            PList *Args = CreatePList();
            
            
            Typespec *It = NULL;
            for (size_t i = 0; i < typespec->Func.NumArgs; i++) {
                //buf_push(args, resolve_typespec(typespec->func.args[i]));
                It = RemoveFromPListCopy(typespec->Func.Args, FuncTypeTemp, i);
                
                //AddBuf(Args, ResolveTypespec(It));
                AddToPList(Args, ResolveTypespec(It));
            }
            Type *Ret = TypeVoid;
            if (typespec->Func.Ret) {
                Ret = ResolveTypespec(typespec->Func.Ret);
            }
            return TypeFunc(Args, ListLen(Args), Ret);
        }
        
        case TYPESPEC_NAME:
        {
            
            Sym *sym = ResolveName(typespec->name);
            if(sym->Kind != SYM_TYPE)
            {
                printf("%s must denote a type\n", typespec->name);
                exit(-1);
                return NULL;
            }
            
            return(sym->type);
        }
        
        case TYPESPEC_ARRAY:
        {
            int64_t Size = ResolveConstExpression(typespec->Array.Size);
            if (Size < 0) {
                Fatal("Negative array size");
            }
            return TypeArray(ResolveTypespec(typespec->Array.Elem), Size);
            
            
        }
        
        case TYPESPEC_PTR:
        {
            return(TypePointer(ResolveTypespec(typespec->Ptr.Elem)));
        }
        
        default:
        printf("default resolve typespec\n");
        return NULL;
    }
}

ResolvedExpression ResolvedNull = {0};

ResolvedExpression ResolvedConst(int64_t Val) {
    
    return(ResolvedExpression)
    {
        .type = TypeI64, 
        .IsConst = 1,
        .Val = Val,
    };
    
}

ResolvedExpression
ResolvedRValue(Type *type)
{
    return (ResolvedExpression){
        .type = type,
    };
}


int64_t EvalIntBinary(TokenKind Op, int64_t Left, int64_t Right) {
    switch (Op) {
        case TOK_MUL:
        return Left * Right;
        case TOK_DIV:
        return Right != 0 ? Left / Right : 0;
        case TOK_MOD:
        return Right != 0 ? Left % Right : 0;
        case TOK_AND:
        return Left & Right;
        // TODO: Don't allow UB in shifts, etc
        case TOK_LSHIFT:
        return Left << Right;
        case TOK_RSHIFT:
        return Left >> Right;
        case TOK_ADD:
        return Left + Right;
        case TOK_SUB:
        return Left - Right;
        case TOK_OR:
        return Left | Right;
        case TOK_XOR:
        return Left ^ Right;
        case TOK_EQ:
        return Left == Right;
        case TOK_NOTEQ:
        return Left != Right;
        case TOK_LT:
        return Left < Right;
        case TOK_LTEQ:
        return Left <= Right;
        case TOK_GT:
        return Left > Right;
        case TOK_GTEQ:
        return Left >= Right;
        // TODO: Probably handle logical AND/OR separately
        case TOK_AND_AND:
        return Left && Right;
        case TOK_OR_OR:
        return Left || Right;
        default:
        PCAssert(0, "Default EvalIntBinary\n");
        return 0;
    }
}

ResolvedExpression
ResolveExpressionBinary(Expr *expr)
{
    PCAssert((expr->kind == EXPR_BINARY), "ResolveExpresssionBinary\n");
    ResolvedExpression Left = ResolveExpression(expr->Binary.Left);
    ResolvedExpression Right = ResolveExpression(expr->Binary.Right);
    
    if (Left.type != TypeI64) {
        Fatal("left operand of + must be int");
    }
    if (Right.type != Left.type)  {
        Fatal("left and right operand of + must have same type");
    }
    if (Left.IsConst && Right.IsConst) {
        return ResolvedConst(EvalIntBinary(expr->Binary.Op, Left.Val, Right.Val));
    } else {
        return ResolvedRValue(Left.type);
    }
    
}

ResolvedExpression 
ResolveExpressionCall(Expr *expr)
{
    PCAssert((expr->kind == EXPR_CALL), "Not a call in ResolveExpressionCall\n");
    ResolvedExpression Func = ResolveExpression(expr->Call.Expression);
    if (Func.type->Kind != TYPE_FUNC) {
        Fatal("Trying to call non-function value");
    }
    if (expr->Call.NumArgs != Func.type->Func.NumParams) {
        Fatal("Tried to call function with wrong number of arguments");
    }
    
    Type * It = NULL;
    
    while((It = RemoveFromPList(Func.type->Func.Params)) != NULL){
        
        Expr *ExprIt = NULL;
        while((ExprIt = RemoveFromPList(expr->Call.Args)) != NULL){
            
            ResolvedExpression Arg = ResolveExpectedExpression( ExprIt, It);
            
            if (Arg.type != It) {
                Fatal("Call argument expression type doesn't match expected param type");
            }
        }
        
    }
    
    return(ResolvedRValue(Func.type->Func.Ret));
    
}

ResolvedExpression
ResolvedLValue(Type *type) {
    return (ResolvedExpression){
        .type = type,
        .IsLValue = PTrue,
    };
}

ResolvedExpression
ResolveExpressionName(Expr *expr) {
    
    PCAssert((expr->kind == EXPR_NAME), "Not a name in resolveexprname\n");
    Sym *sym = ResolveName(expr->Name);
    if (sym->Kind == SYM_VAR) {
        return ResolvedLValue(sym->type);
    } else if (sym->Kind == SYM_CONST) {
        return(ResolvedConst(sym->Val));
    } else if (sym->Kind == SYM_FUNC) {
        return ResolvedRValue(sym->type);
    } else {
        printf("%s must be a var or const\n", expr->Name);
        exit(-1);
        return ResolvedNull;
    }
}

size_t AggregateFieldIndex(Type *type, const char *Name) {
    PCAssert((type->Kind == TYPE_STRUCT || type->Kind == TYPE_UNION), "AggregateFieldIndex");
    
    TypeField *It = NULL;
    for (size_t i = 0; i < type->Aggregate.NumFields; i++) {
        
        It = RemoveFromPListCopy(type->Aggregate.Fields, AggregateFieldTemp, i);
        
        if (strcmp(It->Name,Name) == 0) {
            return i;
        }
    }
    printf("Field '%s' in compound literal not found in struct/union", Name);
    exit(-1);
    return SIZE_MAX;
}

ResolvedExpression 
ResolveExpressionCompound(Expr *expr, Type *ExpectedType) {
    
    PCAssert((expr->kind == EXPR_COMPOUND), "ResolveExpressionCompound");
    if (!ExpectedType && !expr->Compound.Type) {
        Fatal("Implicitly typed compound literals used in context without expected type");
    }
    Type *type = NULL;
    if (expr->Compound.Type) {
        type = ResolveTypespec(expr->Compound.Type);
        
    } else {
        type = ExpectedType;
    }
    CompleteType(type);
    if (type->Kind != TYPE_STRUCT && type->Kind != TYPE_UNION && type->Kind != TYPE_ARRAY) {
        Fatal("Compound literals can only be used with struct and array types");
    }
    
    if (type->Kind == TYPE_STRUCT || type->Kind == TYPE_UNION) {
        if (expr->Compound.NumFields > type->Aggregate.NumFields) {
            Fatal("Compound literal has too many fields");
        }
        size_t Index = 0;
        
        CompoundField *It = NULL;
        
        
        for (size_t i = 0; i < expr->Compound.NumFields; i++) {
            
            It = RemoveFromPListCopy(expr->Compound.Fields, CompoundFieldTemp, i);
            
            if(It->Kind == FIELD_INDEX)
            {
                Fatal("Index field initializer not allowed for struct/union compound literal");
            }
            
            else if (It->Kind == FIELD_NAME) {
                Index = AggregateFieldIndex(type, It->Name);
            }
            if (Index >= type->Aggregate.NumFields) {
                Fatal("Field initializer in struct/union compound literal out of range");
            }
            
            //ResolvedExpression Init = ResolveExpectedExpression(expr->Compound.Fields[i].Head->Data->Init, type->Aggregate.Fields[Index].type);
            //if (Init.type != type->Aggregate.Fields[Index].type) {
            //Fatal("Compound literal field type mismatch");
            //}
            
            
            Index++;
        }
        
        
    } else {
        
        PCAssert((type->Kind == TYPE_ARRAY), "TypeArray\n");
        size_t Index = 0;
        
        CompoundField *Field = NULL;
        for(size_t i = 0; i < expr->Compound.NumFields; i++){
            
            Field = RemoveFromPListCopy(expr->Compound.Fields, CompoundFieldTemp, i);
            if(Field->Kind == FIELD_NAME)
            {
                Fatal("Named field initializer not allowed for array compound literals");
            }
            else if(Field->Kind == FIELD_INDEX)
            {
                int64_t Result = ResolveConstExpression(Field->Index);
                if(Result < 0)
                {
                    Fatal("Field initializer index cannot be negative");
                }
                
                Index = Result;
            }
            
            if (Index >= type->Array.Size) {
                Fatal("Field initializer in array compound literal out of range");
            }
            ResolvedExpression Init = ResolveExpectedExpression(Field->Init, type->Array.Elem);
            if (Init.type != type->Array.Elem) {
                Fatal("Compound literal element type mismatch");
            }
            Index++;
            
        }
    }
    return ResolvedRValue(type);
    
}

ResolvedExpression PtrDecay(ResolvedExpression expr) {
    
    
    if (expr.type->Kind == TYPE_ARRAY) {
        return ResolvedRValue(TypePointer(expr.type->Array.Elem));
    } else {
        
        return expr;
    }
}

ResolvedExpression
ResolveExpressionCast(Expr *expr) 
{
    PCAssert((expr->kind == EXPR_CAST), "ResolveExpressionCast\n");
    Type *type = ResolveTypespec(expr->Cast.Type);
    ResolvedExpression Result = PtrDecay(ResolveExpression(expr->Cast.expr));
    if (type->Kind == TYPE_PTR) {
        if (Result.type->Kind != TYPE_PTR && Result.type->Kind != TYPE_I64) {
            Fatal("Invalid cast to pointer type");
        }
    } else if (type->Kind == TYPE_I64) {
        if (Result.type->Kind != TYPE_PTR && Result.type->Kind != TYPE_I64) {
            Fatal("Invalid cast to int type");
        }
    } else {
        Fatal("Invalid target cast type");
    }
    return ResolvedRValue(type);
}

int64_t EvalIntUnary(TokenKind Op, int64_t Val) {
    switch (Op) {
        case TOK_ADD:
        return(+Val);
        case TOK_SUB:
        return -Val;
        case TOK_NEG:
        return ~Val;
        case TOK_NOT:
        return !Val;
        default:
        PCAssert(0, "Default case in EvalIntUnary\n");
        return 0;
    }
}

ResolvedExpression ResolveExpressionUnary(Expr *expr) {
    PCAssert((expr->kind == EXPR_UNARY), "ResolveExpressionUnary");
    ResolvedExpression Operand = ResolveExpression(expr->Unary.expr);
    Type *type = Operand.type;
    switch (expr->Unary.Op) {
        case TOK_MUL:
        Operand = PtrDecay(Operand);
        if (type->Kind != TYPE_PTR) {
            Fatal("Cannot deref non-ptr type");
        }
        return(ResolvedLValue(type->Ptr.Elem));
        case TOK_AND:
        if (!Operand.IsLValue) {
            Fatal("Cannot take address of non-lvalue");
        }
        return ResolvedRValue(TypePointer(type));
        default:
        
        if (type->Kind != TYPE_I64) {
            printf("Can only use unary %s with ints", TokToString(expr->Unary.Op));
        }
        if (Operand.IsConst) {
            return(ResolvedConst(EvalIntUnary(expr->Unary.Op, Operand.Val)));
        } else {
            return(ResolvedRValue(type));
        }
    }
}

ResolvedExpression ResolveExpressionIndex(Expr *expr) {
    
    PCAssert((expr->kind == EXPR_INDEX), "ResolveExpressionIndex");
    
    ResolvedExpression Operand = PtrDecay(ResolveExpression(expr->Index.expr));
    
    
    if (Operand.type->Kind != TYPE_PTR) {
        Fatal("Can only index arrays or pointers");
    }
    
    ResolvedExpression Index = ResolveExpression(expr->Index.Index);
    if (Index.type->Kind != TYPE_I64) {
        Fatal("Index expression must have type int");
    }
    return(ResolvedLValue(Operand.type->Ptr.Elem));
    
}

ResolvedExpression 
ResolveExpressionTernary(Expr *expr, Type *ExpectedType) {
    PCAssert((expr->kind == EXPR_TERNARY), "ResolveExpressionTernary\n");
    ResolvedExpression Condition = PtrDecay(ResolveExpression(expr->Ternary.Condition));
    if (Condition.type->Kind != TYPE_I64 && Condition.type->Kind != TYPE_PTR) {
        Fatal("Ternary cond expression must have type int or ptr\n");
    }
    ResolvedExpression ThenExpression = PtrDecay(ResolveExpectedExpression(expr->Ternary.ThenExpression, ExpectedType));
    ResolvedExpression ElseExpression = PtrDecay(ResolveExpectedExpression(expr->Ternary.ElseExpression, ExpectedType));
    
    if (ThenExpression.type != ElseExpression.type) {
        Fatal("Ternary then/else expressions must have matching types\n");
    }
    if (Condition.IsConst && ThenExpression.IsConst && ElseExpression.IsConst) {
        return ResolvedConst(Condition.Val ? ThenExpression.Val : ElseExpression.Val);
    } else {
        return ResolvedRValue(ThenExpression.type);
    }
}

ResolvedExpression ResolveExpressionField(Expr *expr) {
    PCAssert((expr->kind == EXPR_FIELD), "ResolveExpressionField\n");
    ResolvedExpression Left = ResolveExpression(expr->Field.expr);
    Type *type = Left.type;
    CompleteType(type);
    if (type->Kind != TYPE_STRUCT && type->Kind != TYPE_UNION) {
        Fatal("Can only access fields on aggregate types");
        return ResolvedNull;
    }
    
    TypeField *It = NULL;
    
    for(size_t i = 0; i < ListLen(type->Aggregate.Fields); i++){
        
        It = RemoveFromPListCopy(type->Aggregate.Fields, FieldTemp2, i);
        
        if (strcmp(It->Name, expr->Field.Name) == 0) {
            return (Left.IsLValue ? ResolvedLValue(It->type) : ResolvedRValue(It->type));
        }
        
    }
    
    printf("No field named '%s'", expr->Field.Name);
    exit(-1);
    return ResolvedNull;
}

ResolvedExpression
ResolveExpectedExpression(Expr *expr, Type *ExpectedType) {
    switch (expr->kind) {
        
        case EXPR_I64:
        
        return ResolvedConst(expr->IntVal);
        
        case EXPR_FLOAT:
        
        return ResolvedRValue(TypeFloat);
        case EXPR_STR:
        
        
        
        
        return ResolvedRValue(TypePointer(TypeChar));
        case EXPR_NAME:
        
        
        return ResolveExpressionName(expr);
        case EXPR_CAST:
        
        return ResolveExpressionCast(expr);
        case EXPR_CALL:
        return ResolveExpressionCall(expr);
        case EXPR_INDEX:
        
        return ResolveExpressionIndex(expr);
        
        case EXPR_FIELD:
        
        return ResolveExpressionField(expr);
        case EXPR_COMPOUND:
        
        return ResolveExpressionCompound(expr, ExpectedType);
        case EXPR_UNARY:
        return ResolveExpressionUnary(expr);
        case EXPR_BINARY:
        
        return ResolveExpressionBinary(expr);
        case EXPR_TERNARY:
        return ResolveExpressionTernary(expr, ExpectedType);
        case EXPR_SIZEOF_EXPR: {
            
            ResolvedExpression Result = ResolveExpression(expr->SizeofExpression);
            Type *type = Result.type;
            CompleteType(type);
            return ResolvedConst(TypeSizeof(type));
        }
        case EXPR_SIZEOF_TYPE: {
            
            Type *type = ResolveTypespec(expr->SizeofType);
            CompleteType(type);
            return ResolvedConst(TypeSizeof(type));
            
        }
        default:
        Fatal("Default case in ResolveExpectedExpression\n");
        exit(-1);
        return ResolvedNull;
    }
}

ResolvedExpression ResolveExpression(Expr *expr) {
    return ResolveExpectedExpression(expr, NULL);
}
#define MAX(x, y) ((x) >= (y) ? (x) : (y))
void 
TypeCompleteStruct(Type *type, PList *Fields, size_t NumFields) {
    PCAssert((type->Kind == TYPE_COMPLETING), "Not completing in TypeCompleteStruct\n");
    type->Kind = TYPE_STRUCT;
    type->Size = 0;
    
    TypeField *Fit = NULL;
    for(size_t i = 0; i < ListLen(Fields); i++)
    {
        Fit = RemoveFromPListCopy(Fields, FieldTemp, i);
        type->Size += TypeSizeof(Fit->type);
        
    }
    
    
    type->Aggregate.Fields = Fields;
    type->Aggregate.NumFields = NumFields;
    
}


void TypeCompleteUnion(Type *type, PList *Fields, size_t NumFields) {
    
    
    PCAssert((type->Kind == TYPE_COMPLETING), "Not typecompleing\n");
    type->Kind = TYPE_UNION;
    type->Size = 0;
    
    TypeField *It = NULL;
    for(size_t i = 0; i < ListLen(Fields); i++)
    {
        It = RemoveFromPListCopy(Fields, FieldTemp, i);
        PCAssert((It->type->Kind > TYPE_COMPLETING), "typecompleteunion\n");
        type->Size = MAX(type->Size, TypeSizeof(It->type));
        
    }
    
    type->Aggregate.Fields = Fields;//memdup(fields, num_fields * sizeof(*fields));
    type->Aggregate.NumFields = NumFields;
}

void CompleteType(Type *type) {
    
    if (type->Kind == TYPE_COMPLETING) {
        Fatal("Type completion cycle\n");
        
        
    } else if (type->Kind != TYPE_INCOMPLETE) {
        
        return;
    }
    
    type->Kind = TYPE_COMPLETING;
    Decl *decl = type->sym->decl;
    
    PCAssert(((decl->kind == DECL_STRUCT) || (decl->kind == DECL_UNION)), "Not a struct or union in CompleteType\n");
    
    AggregateItem *It = NULL;
    
    for(size_t i = 0; i < ListLen(decl->Aggregate.AggregateItems); i++){
        //while((It = RemoveFromPList(decl->Aggregate.AggregateItems)) != NULL){
        It = RemoveFromPListCopy(decl->Aggregate.AggregateItems, PrintFields, i);
        Type *ItemType = ResolveTypespec(It->Type);
        CompleteType(ItemType);
        
        const char  *NamesIt = NULL;
        
        for(size_t i = 0; i < ListLen(It->Names); i++){
            //while((NamesIt = RemoveFromPList(It->Names)) !=NULL){
            NamesIt = RemoveFromPListCopy(It->Names, NameTemp, i);
            TypeField *Field = malloc(sizeof(TypeField));
            Field->type = ItemType;
            Field->Name = NamesIt;
            AddToPList(Fields, Field);
            
        }
    }
    
    if (decl->kind == DECL_STRUCT) {
        
        TypeCompleteStruct(type, Fields, ListLen(Fields));
        
    } else {
        
        PCAssert((decl->kind == DECL_UNION), "not a union\n");
        TypeCompleteUnion(type, Fields, ListLen(Fields));
        
    }
    
    AddToPList(OrderedSyms, type->sym);
    
    
}

Type *ResolveDeclVar(Decl *decl)
{
    
    if(decl->kind != DECL_VAR)
    {
        printf("Not a DECL_VAR\n");
        exit(-1);
    }
    
    Type *type = NULL;
    
    if(decl->var.type)
    {
        
        type = ResolveTypespec(decl->var.type);
        
    }
    
    if (decl->var.expr) {
        
        ResolvedExpression Result = ResolveExpectedExpression(decl->var.expr, type);
        if (type && Result.type != type) {
            Fatal("Declared var type does not match inferred type\n");
            
        }
        type = Result.type;
    }
    
    CompleteType(type);
    return(type);
    
}


Type * 
TypeFunc(void *Params, size_t NumParams, Type *Ret) {
    
    CachedFuncType *It = NULL;
    
    for(size_t i = 0; i < ListLen(CachedFuncTypes); i++)
    {
        It = RemoveFromPListCopy(CachedFuncTypes, CachedFuncTypesTemp, i);
        
        if (It->NumParams == NumParams && It->Ret == Ret) 
        {
            bool32 Match = PTrue;
            
            Type *CachedParamIt = NULL;
            Type *LocalParamIt = NULL;
            
            for(size_t i = 0; i < ListLen(It->Params); i++){
                CachedParamIt = RemoveFromPListCopy(It->Params, CachedFuncParams, i);
                
                for(size_t e = 0; e < ListLen(Params); e++){
                    
                    LocalParamIt = RemoveFromPListCopy(Params, CachedFuncParamsLocal, e);
                    
                    if (CachedParamIt != LocalParamIt) 
                    {
                        Match = PFalse;
                        printf("Huh?");
                        exit(-1);
                        break;
                    }
                    
                }
                
            }
            
            if (!Match) 
            {
                return It->Func;
            }
            
            
        }
        
    }
    
    
    Type *type = TypeAlloc(TYPE_FUNC);
    type->Size = PTR_SIZE;
    type->align = PTR_ALIGN;
    type->Func.Params = Params;
    type->Func.NumParams = NumParams;
    type->Func.Ret = Ret;
    
    CachedFuncType *FuncType = malloc(sizeof(CachedFuncType ));
    FuncType->Params = Params;
    FuncType->NumParams = NumParams;
    FuncType->Ret = Ret;
    FuncType->Func = type;
    
    AddToPList(CachedFuncTypes, FuncType);
    
    return type;
    
}



Type *
ResolveDeclFunc(Decl *decl) {
    PCAssert((decl->kind == DECL_FUNC), "ResolveDeclFunc\n");
    PList *Params = CreatePList();
    //for (size_t i = 0; i < decl->Func.NumParams; i++) {
    FuncParam *It = NULL;
    //while((It = RemoveFromPList(decl->Func.Params))!= NULL){
    //printf("NumOfParams: %lld\n", decl->Func.NumOfParams);
    
    for(size_t i = 0; i < decl->Func.NumOfParams; i++)
    {
        It = RemoveFromPListCopy(decl->Func.Params, TempParams, i);
        
        //while((It = RemoveFromPList(decl->Func.Params))!= NULL){
        AddToPList(Params, ResolveTypespec(It->Type));
        //}
    }
    
    
    //printf("NumOfParams: %lld\n", decl->Func.NumOfParams);
    Type *RetType = TypeVoid;
    if (decl->Func.RetType) {
        RetType = ResolveTypespec(decl->Func.RetType);
    }
    return(TypeFunc(Params, ListLen(Params), RetType));
}

Type *
ResolveDeclConst(Decl *decl, int64_t *Val) {
    PCAssert((decl->kind == DECL_CONST), "ResolveDeclConst\n");
    ResolvedExpression Result = ResolveExpression(decl->ConstDecl.Expression);
    if (!Result.IsConst) {
        Fatal("Initializer for const is not a constant expression\n");
    }
    *Val = Result.Val;
    return(Result.type);
}

Type *ResolveDeclType(Decl *decl) {
    PCAssert((decl->kind == DECL_TYPEDEF), "ResolveDeclType\n");
    return(ResolveTypespec(decl->TypedefDecl.Type));
}

void ResolveSym(Sym* sym)
{
    
    if(sym->State == SYM_RESOLVED)
    {
        
        return;
    }
    
    else if (sym->State == SYM_RESOLVING) {
        printf("Cyclic dependency");
        return;
    }
    
    if(sym->State != SYM_UNRESOLVED)
    {
        printf("calloc unresolved");
        exit(-1);
    }
    
    sym->State = SYM_RESOLVING;
    
    switch (sym->Kind) {
        case SYM_TYPE:
        
        sym->type = ResolveDeclType(sym->decl);
        
        break;
        case SYM_VAR:
        
        sym->type = ResolveDeclVar(sym->decl);
        break;
        case SYM_CONST:
        
        sym->type = ResolveDeclConst(sym->decl, &sym->Val);
        break;
        case SYM_FUNC:
        sym->type = ResolveDeclFunc(sym->decl);
        break;
        default:
        
        printf( "Default case in ResolveSym\n");
        exit(-1);
        break;
    }
    
    sym->State = SYM_RESOLVED;
    AddToPList(OrderedSyms, sym);
    
}

void SymPushVar(const char *Name, Type *type) {
    /*if (local_syms_end == local_syms + MAX_LOCAL_SYMS) {
        fatal("Too many local symbols");
    }*/
    /**local_syms_end++ = (Sym){
        .name = name,
        .kind = SYM_VAR,
        .state = SYM_RESOLVED,
        .type = type,
    };*/
    
    Sym *sym = calloc(1, sizeof(Sym));
    sym->Name = Name;
    sym->Kind = SYM_VAR;
    sym->State = SYM_RESOLVED;
    sym->type  = type;
    
    
    AddToPList(LocalSyms, sym);
}

void ResolveStatementBlock(StatementList *Block, Type *RetType);

void ResolveCondExpression(Expr *expr) {
    ResolvedExpression Cond = ResolveExpression(expr);
    if (Cond.type != TypeI64) {
        Fatal("Conditional expression must have type int");
    }
}

void ResolveStatement(Statement *stmt, Type *RetType) {
    
    if(!stmt)
    {
        printf("Fail\n");
        exit(-1);
    }
    switch (stmt->Kind) {
        case STMT_RETURN:
        if (stmt->Expression) {
            if (ResolveExpectedExpression(stmt->Expression, RetType).type != RetType) {
                Fatal("Return type mismatch");
            }
        } else if (RetType != TypeVoid) {
            Fatal("Empty return expression for function with non-void return type");
        }
        break;
        case STMT_BREAK:
        case STMT_CONTINUE:
        // Do nothing
        break;
        case STMT_BLOCK:
        ResolveStatementBlock(stmt->Block, RetType);
        break;
        case STMT_IF:
        
        ResolveCondExpression(stmt->IfStatement.Cond);
        ResolveStatementBlock(stmt->IfStatement.ThenBlock, RetType);
        
        ElseIf *It = NULL;
        for (size_t i = 0; i < stmt->IfStatement.NumElseIfs; i++) {
            //ElseIf elseif = stmt->IfStatement.ElseIfs[i];
            It = RemoveFromPListCopy(stmt->IfStatement.ElseIfs, ElseIfTemp, i);
            
            ResolveCondExpression(It->Cond);
            ResolveStatementBlock(It->Block, RetType);
        }
        if (stmt->IfStatement.ElseBlock->Statements) {
            ResolveStatementBlock(stmt->IfStatement.ElseBlock, RetType);
        }
        break;
        
        case STMT_WHILE:
        case STMT_DO_WHILE:
        ResolveCondExpression(stmt->WhileStatement.Cond);
        ResolveStatementBlock(stmt->WhileStatement.Block, RetType);
        break;
        case STMT_FOR: {
            //Sym *start = sym_enter();
            ResolveStatement(stmt->ForStatement.Init, RetType);
            ResolveCondExpression(stmt->ForStatement.Cond);
            ResolveStatementBlock(stmt->ForStatement.Block, RetType);
            ResolveStatement(stmt->ForStatement.Next, RetType);
            //sym_leave(start);
            break;
        }
        case STMT_SWITCH: {
            ResolvedExpression expr = ResolveExpression(stmt->SwitchStatement.expr);
            
            SwitchCase *switch_case = NULL;
            for (size_t i = 0; i < stmt->SwitchStatement.NumOfCases; i++) {
                
                //stmt->switch_stmt.cases[i];
                switch_case = RemoveFromPListCopy(stmt->SwitchStatement.Cases, SwitchCasesTemp, i);
                
                
                Expr *exprs = NULL;
                for (size_t j = 0; j < switch_case->NumOfExprs; j++) {
                    exprs = RemoveFromPListCopy(switch_case->Exprs, ExprsTemp, j);
                    
                    if (ResolveExpression(exprs).type != expr.type) {
                        Fatal("Switch case expression type mismatch");
                        
                    }
                    ResolveStatementBlock(switch_case->Block, RetType);
                    
                }
            }
            
            break;
            
        }
        
        case STMT_ASSIGN: {
            
            ResolvedExpression Left = ResolveExpression(stmt->Assign.Left);
            if (stmt->Assign.Right) {
                ResolvedExpression Right = ResolveExpectedExpression(stmt->Assign.Right, Left.type);
                if (Left.type != Right.type) {
                    Fatal("Left/right types do not match in assignment statement");
                }
            }
            if (!Left.IsLValue) {
                Fatal("Cannot assign to non-lvalue");
            }
            if (stmt->Assign.Op != TOK_ASSIGN && Left.type != TypeI64) {
                Fatal("Can only use assignment operators with type int");
            }
            break;
        }
        case STMT_INIT:
        SymPushVar(stmt->Initialisation.Name, ResolveExpression(stmt->Initialisation.Expression).type);
        break;
        default:
        Fatal("StatementBlockResolve");
        break;
    }
}

void ResolveStatementBlock(StatementList *Block, Type *RetType) {
    //Sym *start = sym_enter();
    
    if(!Block)
    {
        printf("Block NULL\n");
        exit(-1);
    }
    Statement *It = NULL;
    for (size_t i = 0; i < Block->NumOfStatements; i++) {
        It = RemoveFromPListCopy(Block->Statements, StatementsTemp, i);
        //while((It = RemoveFromPList(Block->Statements))!= NULL)
        
        
        ResolveStatement(It, RetType);
        
        
    }
    //sym_leave(start);
}


void ResolveFunc(Sym *sym) {
    Decl *decl = sym->decl;
    PCAssert((decl->kind == DECL_FUNC), "ResolveFunc");
    PCAssert((sym->State == SYM_RESOLVED), "ResolveFunc");
    
    FuncParam *Param = NULL;
    for (size_t i = 0; i < decl->Func.NumOfParams; i++) {
        Param = RemoveFromPListCopy(decl->Func.Params, FuncParamsTemp, i); 
        
        SymPushVar(Param->Name, ResolveTypespec(Param->Type));
    }
    ResolveStatementBlock(decl->Func.Block, ResolveTypespec(decl->Func.RetType));
    //SymLeave(Start);
}

void CompleteSym(Sym *sym)
{
    
    ResolveSym(sym);
    if (sym->Kind == SYM_TYPE) {
        
        CompleteType(sym->type);
    }
    else if(sym->Kind == SYM_FUNC)
    {
        ResolveFunc(sym);
    }
    
}