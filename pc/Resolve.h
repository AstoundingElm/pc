ResolvedExpression
ResolveExpectedExpression(Expr *expr, Type *ExpectedType);

PList *Fields;

Entity *ResolveName(const char *Name);

Symbol *
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
}


Entity *
EntityNew(EntityKind Kind, const char *Name, Decl *decl)
{
    Entity *entity = calloc(1, sizeof(Entity));
    
    entity->Kind = Kind;
    entity->Name = Name;
    entity->decl = decl;
    
    return entity;
}

Type *TypeIncomplete(Entity *entity)
{
    Type *type = malloc(sizeof(Type));
    type->Kind = TYPE_INCOMPLETE;
    type->entity = entity;
    return type;
}

Entity*
EntityDecl(Decl *decl)
{
    EntityKind kind = ENTITY_NONE;
    switch (decl->kind) {
        case DECL_STRUCT:
        case DECL_UNION:
        case DECL_TYPEDEF:
        case DECL_ENUM:
        
        kind = ENTITY_TYPE;
        
        break;
        case DECL_VAR:
        kind = ENTITY_VAR;
        break;
        case DECL_CONST:
        kind = ENTITY_CONST;
        break;
        case DECL_FUNC:
        kind = ENTITY_FUNC;
        break;
        default:
        PCAssert(0, "Default entitydecl\n");
        break;
    }
    
    
    Entity *entity = EntityNew(kind, decl->name, decl);
    if (decl->kind == DECL_STRUCT || decl->kind == DECL_UNION) {
        entity->State = ENTITY_RESOLVED;
        entity->type = TypeIncomplete(entity);
    }
    return entity;
}



Entity*
EntityEnumConst(const char*Name, Decl *decl)
{
    return EntityNew(ENTITY_ENUM_CONST, Name, decl);
}

Entity*
EntityInstallDecl(Decl *decl)
{
    Entity *entity = EntityDecl(decl);
    
    AddToPList(Entities, entity);
    
    if(decl->kind == DECL_ENUM)
    {
        
        EnumItem *EnumIt = NULL;
        while((EnumIt = (EnumItem*)RemoveFromPList(decl->EnumDecl.Items)) != NULL){
            
            AddToPList(Entities,EntityEnumConst(EnumIt->Name, decl));
            
        }
        
    }
    
    return entity;
}


Entity *
EntityGet( const char *Name)
{
    
    Entity *It = NULL;
    
    for(size_t i = 0; i < ListLen(Entities); i++)
    {
        It = RemoveFromPListCopy(Entities, Temp2, i);
        
        if(strcmp(It->Name, Name) == 0)
        {
            
            
            return It;
        }
        
        
    }
    
    return NULL;
    
}
void CompleteType(Type *type);

Entity *
EntityInstallType(const char* Name, Type *type)
{
    Entity *entity = EntityNew(ENTITY_TYPE, Name, NULL);
    entity->State = ENTITY_RESOLVED;
    entity->type = type;
    
    AddToPList(Entities, entity);
    return entity;
}


Entity *ResolveName(const char *Name)
{
    
    Entity *entity = EntityGet(Name);
    if(!entity)
    {
        printf("Non-existent name\n");
        exit(-1);
        return NULL;
    }
    
    ResolveEntity(entity);
    return entity;
}

Type *TypeAlloc(TypeKind Kind) {
    Type *type = calloc(1, sizeof(Type));
    type->Kind = Kind;
    return type;
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
        Fatal("Expected constant expression");
    }
    return Result.Val;
}

Type *
TypePointer(Type *Elem) {
    //for (CachedPtrType *it = cached_ptr_types; it != buf_end(cached_ptr_types); it++) {
    
    
    CachedPtrType *It = NULL;
    
    while((It = RemoveFromPList(CachedPtrTypes))!= NULL){
        if (It->Elem == Elem) {
            return It->Ptr;
        }
    }
    Type *type = TypeAlloc(TYPE_PTR);
    type->Size = PTR_SIZE;
    type->Ptr.Elem = Elem;
    //buf_push(cached_ptr_types, (CachedPtrType){elem, type});
    
    CachedPtrType *PtrType = malloc( sizeof(CachedPtrType ));
    
    PtrType->Elem = Elem;
    PtrType->Ptr = type;
    
    AddToPList(CachedPtrTypes, PtrType );
    
    return type;
    
}

Type *
ResolveTypespec(Typespec *typespec)
{
    switch(typespec->kind)
    {
        case TYPESPEC_FUNC: {
            printf("typespec func\n");exit(-1);
        }
        
        case TYPESPEC_NAME:
        {
            
            Entity *entity = ResolveName(typespec->name);
            if(entity->Kind != ENTITY_TYPE)
            {
                printf("%s must denote a type\n", typespec->name);
                exit(-1);
                return NULL;
            }
            
            return entity->type;
        }
        
        case TYPESPEC_ARRAY:
        {
            
            return TypeArray(ResolveTypespec(typespec->Array.Elem), ResolveConstExpression(typespec->Array.Size));
        }
        
        case TYPESPEC_PTR:
        {
            return TypePointer(ResolveTypespec(typespec->Ptr.Elem));
        }
        
        default:
        printf("default resolve typespec\n");
        return NULL;
    }
}

ResolvedExpression ResolvedNull = {0};


ResolvedExpression ResolvedConst(int64_t Val) {
    
    
    ResolvedExpression expr = {0};
    expr.type = TypeI64;
    expr.IsConst = PTrue;
    expr.Val = Val;
    return expr;
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
    
    return ResolvedRValue(Func.type->Func.Ret);
    
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
    Entity *entity = ResolveName(expr->Name);
    if (entity->Kind == ENTITY_VAR) {
        return ResolvedLValue(entity->type);
    } else if (entity->Kind == ENTITY_CONST) {
        return ResolvedConst(entity->Val);
    } else if (entity->Kind == ENTITY_FUNC) {
        return ResolvedRValue(entity->type);
    } else {
        printf("%s must be a var or const\n", expr->Name);
        exit(-1);
        return ResolvedNull;
    }
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
        if (ExpectedType && ExpectedType != type) {
            Fatal("Explicit compound literal type does not match expected type");
        }
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
        for (size_t i = 0; i < expr->Compound.NumFields; i++) {
            
            Expr *EIt = NULL;
            while((EIt = RemoveFromPList(expr->Compound.Fields)) != NULL){
                ResolvedExpression Field = ResolveExpression(EIt);
                
                //while((It = RemoveFromPList(expr->Compound.Fields)) != NULL){
                
                TypeField *TypeIt = NULL;
                //while((TypeIt = RemoveFromPList(type->Aggregate.Fields)) != NULL){
                for(size_t  i = 0; i < ListLen(type->Aggregate.Fields); i++){
                    TypeIt = RemoveFromPListCopy(type->Aggregate.Fields, FieldTemp2, i);
                    
                    printf("Field: %d\n", Field.type->Kind);
                    printf("It: %d\n", TypeIt->type->Kind);
                    
                    //printf("%s\n", It->Name);
                    if (Field.type != TypeIt->type) {
                        printf("Compound literal field type mismatch\n");
                    }
                }
            }
        }
        
        
    } else {
        
        PCAssert((type->Kind == TYPE_ARRAY), "TypeArray\n");
        
        if (expr->Compound.NumFields > type->Array.Size) {
            Fatal("Compound literal has too many elements");
        }
        
        Expr *It = NULL;
        
        while((It = RemoveFromPList(expr->Compound.Fields)) != NULL){
            
            ResolvedExpression Elem = ResolveExpression(It);
            if (Elem.type != type->Array.Elem) {
                Fatal("Compound literal element type mismatch");
            }
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
        return +Val;
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
        return ResolvedLValue(type->Ptr.Elem);
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
            return ResolvedConst(EvalIntUnary(expr->Unary.Op, Operand.Val));
        } else {
            return ResolvedRValue(type);
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
    return ResolvedLValue(Operand.type->Ptr.Elem);
    
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
    
    //TODO: fix this!!!
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
    //for (size_t i = 0; i < type->aggregatne.num_fields; i++) {
    //TypeField field = type->aggregate.fields[i];
    
    TypeField *It = NULL;
    
    for(size_t i = 0; i < ListLen(type->Aggregate.Fields); i++){
        
        //while((It = RemoveFromPList(type->Aggregate.Fields)) != NULL){
        It = RemoveFromPListCopy(type->Aggregate.Fields, FieldTemp2, i);
        printf("It: %s\n",It->Name);
        printf("Expr: %s\n", expr->Field.Name);
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
        printf("Default case in ResolveExpectedExpression\n");
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
    //for (TypeField *it = fields; it != fields + num_fields; it++) {
    // TODO: Alignment, etc.
    //exit(-1);
    /*TypeField *It = NULL;
    while((It = RemoveFromPList(Fields)) != NULL){
        printf("725:%s\n", It->Name);
        type->Size += TypeSizeof(It->type);
        
    }*/
    
    TypeField *Fit = NULL;
    for(size_t i = 0; i < ListLen(Fields); i++)
    {
        Fit = RemoveFromPListCopy(Fields, FieldTemp, i);
        type->Size += TypeSizeof(Fit->type);
        
    }
    
    
    type->Aggregate.Fields = Fields;//memdup(fields, num_fields * sizeof(*fields));
    type->Aggregate.NumFields = NumFields;
    
}


void TypeCompleteUnion(Type *type, PList *Fields, size_t NumFields) {
    
    
    PCAssert((type->Kind == TYPE_COMPLETING), "Not typecompleing\n");
    type->Kind = TYPE_UNION;
    type->Size = 0;
    //for (TypeField *it = fields; it != fields + num_fields; it++) {
    /*TypeField *It = NULL;
    while((It = (TypeField*)RemoveFromPListCopy(Fields)) != NULL){
        PCAssert((It->type->Kind > TYPE_COMPLETING), "typecompleteunion\n");
        printf("%s\n", It->Name);
        type->Size = MAX(type->Size, TypeSizeof(It->type));
    }*/
    
    TypeField *It = NULL;
    for(size_t i = 0; i < ListLen(Fields); i++)
    {
        It = RemoveFromPListCopy(Fields, FieldTemp, i);
        PCAssert((It->type->Kind > TYPE_COMPLETING), "typecompleteunion\n");
        type->Size = MAX(type->Size, TypeSizeof(It->type));
        printf("Names:%s\n", It->Name);
    }
    
    type->Aggregate.Fields = Fields;//memdup(fields, num_fields * sizeof(*fields));
    type->Aggregate.NumFields = NumFields;
}


void CompleteType(Type *type) {
    
    
    
    if (type->Kind == TYPE_COMPLETING) {
        printf("Type completion cycle");
        exit(-1);
        
    } else if (type->Kind != TYPE_INCOMPLETE) {
        
        return;
    }
    
    type->Kind = TYPE_COMPLETING;
    Decl *decl = type->entity->decl;
    
    PCAssert(((decl->kind == DECL_STRUCT) || (decl->kind == DECL_UNION)), "Not a struct or union in CompleteType\n");
    
    
    
    AggregateItem *It = NULL;
    while((It = RemoveFromPList(decl->Aggregate.AggregateItems)) != NULL){
        
        
        Type *ItemType = ResolveTypespec(It->Type);
        CompleteType(ItemType);
        
        
        
        const char  *NamesIt = NULL;
        //for(size_t i = 0; i < ListLen(It->Names); i++){
        while((NamesIt = RemoveFromPList(It->Names)) !=NULL){
            
            TypeField *Field = malloc(sizeof(TypeField));
            Field->type = ItemType;
            Field->Name = NamesIt;
            printf("%s\n", Field->Name);
            AddToPList(Fields, Field);
            
            
        }
    }
    
    
    
    if (decl->kind == DECL_STRUCT) {
        
        
        TypeCompleteStruct(type, Fields, ListLen(Fields));
    } else {
        
        PCAssert((decl->kind == DECL_UNION), "not a union\n");
        TypeCompleteUnion(type, Fields, ListLen(Fields));
        
        
        
    }
    
    AddToPList(OrderedEntities, type->entity);
    //buf_push(ordered_entities, type->entity);
    
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
            printf("Declared var type does not match inferred type");
            exit(-1);
        }
        type = Result.type;
    }
    
    CompleteType(type);
    return type;
    
}


Type *   //type
TypeFunc(PList *Params, size_t NumParams, Type *Ret) {
    //for (CachedFuncType *it = cached_func_types; it != buf_end(cached_func_types); it++) {
    
    
    CachedFuncType *It = NULL;
    while((It = RemoveFromPList(CachedFuncTypes)) != NULL)
    {
        
        if (It->NumParams == NumParams && It->Ret == Ret) 
        {
            bool32 Match = PTrue;
            //for (size_t i = 0; i < num_params; i++) {
            
            Type *CachedParamIt = NULL;
            Type *LocalParamIt = NULL;
            while((CachedParamIt = RemoveFromPList(It->Params)) != NULL)
            { 
                while((LocalParamIt = RemoveFromPList(Params)) != NULL)
                { 
                    if (CachedParamIt != LocalParamIt) 
                    {
                        Match = PFalse;
                        break;
                    }
                }
                
            }
            
            if (Match) 
            {
                return It->Func;
            }
            
        }
        
        
    }
    
    Type *type = TypeAlloc(TYPE_FUNC);
    type->Size = PTR_SIZE;
    type->Func.Params = Params;//memdup(params, num_params * sizeof(*params));
    type->Func.NumParams = NumParams;
    type->Func.Ret = Ret;
    //buf_push(cached_func_types, (CachedFuncType){params, num_params, ret, type});
    
    CachedFuncType *FuncType = malloc(sizeof(CachedFuncType ));
    FuncType->Params = Params;
    FuncType->NumParams = NumParams;
    FuncType->Ret = Ret;
    FuncType->Func = type;
    
    AddToPList(CachedFuncTypes, FuncType);
    
    return type;
    
}

PList *Params;

Type *
ResolveDeclFunc(Decl *decl) {
    PCAssert((decl->kind == DECL_FUNC), "ResolveDeclFunc\n");
    Params = CreatePList();
    //for (size_t i = 0; i < decl->Func.NumParams; i++) {
    FuncParam *It = NULL;
    while((It = RemoveFromPList(decl->Func.Params))!= NULL){
        
        AddToPList(Params, ResolveTypespec(It->Type));
    }
    Type *RetType = TypeVoid;
    if (decl->Func.RetType) {
        RetType = ResolveTypespec(decl->Func.RetType);
    }
    return TypeFunc(Params, ListLen(Params), RetType);
}

Type *
ResolveDeclConst(Decl *decl, int64_t *Val) {
    PCAssert((decl->kind == DECL_CONST), "ResolveDeclConst\n");
    ResolvedExpression Result = ResolveExpression(decl->ConstDecl.Expression);
    if (!Result.IsConst) {
        Fatal("Initializer for const is not a constant expression\n");
    }
    *Val = Result.Val;
    return Result.type;
}

Type *ResolveDeclType(Decl *decl) {
    PCAssert((decl->kind == DECL_TYPEDEF), "ResolveDeclType\n");
    return ResolveTypespec(decl->TypedefDecl.Type);
}

void ResolveEntity(Entity* entity)
{
    
    if(entity->State == ENTITY_RESOLVED)
    {
        
        return;
    }
    
    else if (entity->State == ENTITY_RESOLVING) {
        printf("Cyclic dependency");
        return;
    }
    
    if(entity->State != ENTITY_UNRESOLVED)
    {
        printf("calloc unresolved");
        exit(-1);
    }
    
    entity->State = ENTITY_RESOLVING;
    
    switch (entity->Kind) {
        case ENTITY_TYPE:
        
        entity->type = ResolveDeclType(entity->decl);
        
        break;
        case ENTITY_VAR:
        
        entity->type = ResolveDeclVar(entity->decl);
        break;
        case ENTITY_CONST:
        
        entity->type = ResolveDeclConst(entity->decl, &entity->Val);
        break;
        case ENTITY_FUNC:
        entity->type = ResolveDeclFunc(entity->decl);
        break;
        default:
        
        printf( "Default case in ResolveEntity\n");
        exit(-1);
        break;
    }
    
    entity->State = ENTITY_RESOLVED;
    AddToPList(OrderedEntities, entity);
    
}

void CompleteEntity(Entity *entity)
{
    
    ResolveEntity(entity);
    if (entity->Kind == ENTITY_TYPE) {
        
        CompleteType(entity->type);
    }
    
}