
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
        //case DECL_CONST:
        //kind = ENTITY_CONST;
        //break;
        case DECL_FUNC:
        kind = ENTITY_FUNC;
        break;
        default:
        PAssert(0, "Default entitydecl\n");
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
        printf("Non-existent name");
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
    
    PCAssert(type->Size != 0, "TypeSizeof\n");
    return type->Size;
}

ResolvedExpression 
ResolveExpression(Expr *expr);


Type *TypeArray(Type *Elem, size_t Size) {
    
    CachedArrayTypes = CreatePList();
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
    
    CachedArrayType *ArrayType = malloc(sizeof(CachedArrayType *));
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
ResolveTypespec(Typespec *typespec)
{
    switch(typespec->kind)
    {
        
        
        case TYPESPEC_NAME:
        {
            
            Entity *entity = ResolveName(typespec->name);
            if(entity->Kind != ENTITY_TYPE)
            {
                printf("%s must denote a type\n", typespec->name);
                return NULL;
            }
            
            return entity->type;
        }
        
        case TYPESPEC_ARRAY:
        {
            
            return TypeArray(ResolveTypespec(typespec->Array.Elem), ResolveConstExpression(typespec->Array.Size));
        }
        
        default:
        printf("default resolve typespec\n");
        return NULL;
    }
}

ResolvedExpression ResolvedNull;

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

ResolvedExpression
ResolveExpressionBinary(Expr *expr)
{
    
    ResolvedExpression Expression = {0};
    return Expression;
}

ResolvedExpression
ResolveExpectedExpression(Expr *expr, Type *ExpectedType) {
    switch (expr->kind) {
        case EXPR_I64:
        
        return ResolvedConst(expr->IntVal);
        
        case EXPR_FLOAT:
        //return ResolvedRValue(TypeFloat);
        case EXPR_STR:
        //return resolved_rvalue(type_ptr(type_char));
        case EXPR_NAME:
        printf("namasdasdadasdasde");
        exit(-1);
        //return resolve_expr_name(expr);
        case EXPR_CAST:
        //return resolve_expr_cast(expr);
        case EXPR_CALL:
        //return resolve_expr_call(expr);
        case EXPR_INDEX:
        exit(-1);
        //return resolve_expr_index(expr);
        case EXPR_FIELD:
        printf("field\n");
        exit(-1);
        //return resolve_expr_field(expr);
        case EXPR_COMPOUND:
        exit(-1);
        //return resolve_expr_compound(expr, expected_type);
        case EXPR_UNARY:
        exit(-1);
        //return resolve_expr_unary(expr);
        case EXPR_BINARY:
        
        return ResolveExpressionBinary(expr);
        case EXPR_TERNARY:
        //return resolve_expr_ternary(expr, expected_type);
        case EXPR_SIZEOF_EXPR: {
            /*ResolvedExpr result = resolve_expr(expr->sizeof_expr);
            Type *type = result.type;
            complete_type(type);
            return resolved_const(type_sizeof(type));*/
        }
        case EXPR_SIZEOF_TYPE: {
            /*Type *type = resolve_typespec(expr->sizeof_type);
            complete_type(type);
            return resolved_const(type_sizeof(type));*/
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

void CompleteType(Type *type) {
    
    
    
    
    if (type->Kind == TYPE_COMPLETING) {
        printf("Type completion cycle");
        exit(-1);
        
    } else if (type->Kind != TYPE_INCOMPLETE) {
        
        return;
    }
    
    
    
    type->Kind = TYPE_COMPLETING;
    Decl *decl = type->entity->decl;
    
    if(decl->kind == DECL_STRUCT || decl->kind == DECL_UNION){
        //TypeField *fields = NULL;
        /*for (size_t i = 0; i < decl->aggregate.num_items; i++) {
            AggregateItem item = decl->aggregate.items[i];
            Type *item_type = resolve_typespec(item.type);
            complete_type(item_type);
            for (size_t j = 0; j < item.num_names; j++) {
                buf_push(fields, (TypeField){item.names[j], item_type});
            }
        }*/
        if (decl->kind == DECL_STRUCT) {
            //type_complete_struct(type, fields, buf_len(fields));
        } else {
            if(decl->kind == DECL_UNION){
                //type_complete_union(type, fields, buf_len(fields));
            }
            printf("Not a union in CompleteType");
            exit(-1);
        }
        //buf_push(ordered_entities, type->entity);
    }
    
    printf("Not a union in CompleteType");
    exit(-1);
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

//Type *resolve_decl_type(Decl *decl) {
//assert(decl->kind == DECL_TYPEDEF);
//return Resolve_typespec(decl->typedef_decl.type);
//}

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
        exit(-1);
        //entity->teype = ResolveDeclType(entity->decl);
        break;
        case ENTITY_VAR:
        
        entity->type = ResolveDeclVar(entity->decl);
        break;
        case ENTITY_CONST:
        exit(-1);
        //entity->type = resolve_decl_const(entity->decl, &entity->val);
        break;
        case ENTITY_FUNC:
        //entity->type = resolve_decl_func(entity->decl);
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