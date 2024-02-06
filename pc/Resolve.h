Operand
ResolveExpectedExpression(Expr *expr, Type *ExpectedType);

PList *Fields;

Sym*ResolveName(const char *Name);



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
    Type *type = TypeAlloc(TYPE_INCOMPLETE);
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
    
    buf_push(GlobalSyms, sym);
    
    if(decl->kind == DECL_ENUM)
    {
        
        EnumItem *EnumIt = NULL;
        for (size_t i = 0; i < decl->EnumDecl.NumItems; i++){
            
            buf_push(GlobalSyms,SymEnumConst(EnumIt->Name, decl));
            
        }
        
    }
    
    return sym;
}


Sym *
SymGet( const char *name)
{
    for (Sym *it = local_syms_end; it != LocalSyms; it--) {
        Sym *sym = it-1;
        if (strcmp(sym->Name,name) == 0) {
            return sym;
        }
    }
    for (Sym **it = GlobalSyms; it != buf_end(GlobalSyms); it++) {
        Sym *sym = *it;
        if (strcmp(sym->Name, name) ==0) {
            return sym;
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
    
    buf_push(GlobalSyms, sym);
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
    
    assert(type->Kind > TYPE_COMPLETING);
    
    assert(type->Size != 0);
    return type->Size;
}

Operand 
ResolveExpression(Expr *expr);
#include <assert.h>
size_t TypeAlignof(Type *type) {
    assert(type->Kind > TYPE_COMPLETING);
    return type->Align;
}

Type *TypeArray(Type *Elem, size_t Size) {
    
    
    
    for (CachedArrayType *it = CachedArrayTypes; it != buf_end(CachedArrayTypes); it++) {
        if(it->Elem == Elem && it->Size == Size) {
            
            return it->Array;
        }
    }
    
    CompleteType(Elem);
    
    Type *type = TypeAlloc(TYPE_ARRAY);
    
    type->Size = Size * TypeSizeof(Elem);
    type->Align = TypeAlignof(Elem);
    type->Array.Elem = Elem;
    type->Array.Size = Size;
    
    buf_push(CachedArrayTypes, (CachedArrayType){Elem, Size, type});
    return type;
}

int64_t ResolveConstExpression(Expr *expr) {
    Operand Result = ResolveExpression(expr);
    
    
    if (!Result.IsConst) {
        printf("%d\n",Result.type->Kind );
        printf("%s\n", expr->Name);
        //Fatal("Expected constant expression");
        
    }
    return Result.Val;
}

Type *
TypePointer(Type *Elem) {
    
    for (CachedPtrType *it = CachedPtrTypes; it != buf_end(CachedPtrTypes); it++) {
        if (it->Elem == Elem) {
            return it->Ptr;
        }
    }
    
    Type *type = TypeAlloc(TYPE_PTR);
    type->Size = PTR_SIZE;
    type->Align = PTR_ALIGN;
    type->Ptr.Elem = Elem;
    
    
    
    buf_push(CachedPtrTypes, (CachedPtrType){Elem, type} );
    
    return type;
    
}

Type * 
TypeFunc(Type **params, size_t num_of_params, Type *ret);

Type *
ResolveTypespec(Typespec *typespec)
{
    
    if(!typespec)
    {
        return TypeVoid;
    }
    
    Type *result = NULL;
    switch(typespec->kind)
    {
        case TYPESPEC_FUNC: {
            Type **Args = NULL;
            for (size_t i = 0; i < typespec->Func.NumArgs; i++) {
                buf_push(Args, ResolveTypespec(typespec->Func.Args[i]));
            }
            
            
            
            Type *Ret = TypeVoid;
            if (typespec->Func.Ret) {
                Ret = ResolveTypespec(typespec->Func.Ret);
            }
            result = TypeFunc(Args, buf_len(Args), Ret);
        }break;
        
        case TYPESPEC_NAME:
        {
            
            Sym *sym = ResolveName(typespec->name);
            if(sym->Kind != SYM_TYPE)
            {
                printf("%s must denote a type\n", typespec->name);
                exit(-1);
                return NULL;
            }
            
            result = sym->type;
            
        }break;
        
        case TYPESPEC_ARRAY:
        {
            
            int64_t Size = ResolveConstExpression(typespec->Array.Size);
            if (Size < 0) {
                Fatal("Negative array size");
            }
            result = TypeArray(ResolveTypespec(typespec->Array.Elem), Size);
            
            
        }break;
        
        case TYPESPEC_PTR:
        {
            result = TypePointer(ResolveTypespec(typespec->Ptr.Elem));
        }break;
        
        default:
        printf("default resolve typespec\n");
        return NULL;
    }
    
    //assert(!typespec->type ||  (memcmp(typespec->type, result, sizeof(Type)) == 0));
    
    
    typespec->type = result;
    return result;
}

Operand OperandNull;

Operand OperandConst(int64_t Val) {
    
    return(Operand)
    {
        .type = TypeI64, 
        .IsConst = true,
        .Val = Val,
    };
    
}

Operand
OperandRValue(Type *type)
{
    return (Operand){
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

Operand
ResolveExpressionBinary(Expr *expr)
{
    PCAssert((expr->kind == EXPR_BINARY), "ResolveExpresssionBinary\n");
    Operand Left = ResolveExpression(expr->Binary.Left);
    Operand Right = ResolveExpression(expr->Binary.Right);
    
    if (Left.type != TypeI64) {
        Fatal("left operand of + must be int");
    }
    if (Right.type != Left.type)  {
        Fatal("left and right operand of + must have same type");
    }
    if (Left.IsConst && Right.IsConst) {
        return OperandConst(EvalIntBinary(expr->Binary.Op, Left.Val, Right.Val));
    } else {
        return OperandRValue(Left.type);
    }
    
}

Operand
ResolveExpressionCall(Expr *expr)
{
    PCAssert((expr->kind == EXPR_CALL), "Not a call in ResolveExpressionCall\n");
    Operand Func = ResolveExpression(expr->Call.Expression);
    if (Func.type->Kind != TYPE_FUNC) {
        Fatal("Trying to call non-function value");
    }
    if (expr->Call.NumArgs != Func.type->Func.NumParams) {
        Fatal("Tried to call function with wrong number of arguments");
    }
    
    
    
    for (size_t i = 0; i < expr->Call.NumArgs; i++) {
        Type *param_type = Func.type->Func.Params[i];
        
        Operand Arg = ResolveExpectedExpression( expr->Call.Args[i], param_type);
        
        if (Arg.type != param_type) {
            Fatal("Call argument expression type doesn't match expected param type");
            
        }
        
    }
    
    return(OperandRValue(Func.type->Func.Ret));
    
}

Operand
OperandLValue(Type *type) {
    return (Operand){
        .type = type,
        .IsLValue = true,
    };
}

Operand
ResolveExpressionName(Expr *expr) {
    
    PCAssert((expr->kind == EXPR_NAME), "Not a name in resolveexprname\n");
    Sym *sym = ResolveName(expr->Name);
    if (sym->Kind == SYM_VAR) {
        return OperandLValue(sym->type);
    } else if (sym->Kind == SYM_CONST) {
        return(OperandConst(sym->Val));
    } else if (sym->Kind == SYM_FUNC) {
        return OperandRValue(sym->type);
    } else {
        printf("%s must be a var or const\n", expr->Name);
        exit(-1);
        return OperandNull;
    }
}

size_t AggregateFieldIndex(Type *type, const char *Name) {
    PCAssert((type->Kind == TYPE_STRUCT || type->Kind == TYPE_UNION), "AggregateFieldIndex");
    
    for (size_t i = 0; i < type->Aggregate.NumFields; i++) {
        
        if (strcmp(type->Aggregate.Fields[i].Name,Name) == 0) {
            return i;
        }
    }
    printf("Field '%s' in compound literal not found in struct/union", Name);
    exit(-1);
    return SIZE_MAX;
}

Operand 
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
        
        for (size_t i = 0; i < expr->Compound.NumFields; i++) {
            
            CompoundField field = expr->Compound.Fields[i];
            
            if(field.Kind == FIELD_INDEX)
            {
                Fatal("Index field initializer not allowed for struct/union compound literal");
            }
            
            else if (field.Kind == FIELD_NAME) {
                Index = AggregateFieldIndex(type, field.Name);
            }
            if (Index >= type->Aggregate.NumFields) {
                Fatal("Field initializer in struct/union compound literal out of range");
            }
            
            Operand init = ResolveExpectedExpression(expr->Compound.Fields[i].Init, type->Aggregate.Fields[Index].type);
            if (init.type != type->Aggregate.Fields[Index].type) {
                Fatal("Compound literal field type mismatch");
            }
            
            
            Index++;
        }
        
        
    } else {
        
        PCAssert((type->Kind == TYPE_ARRAY), "TypeArray\n");
        size_t Index = 0;
        
        for (size_t i = 0; i < expr->Compound.NumFields; i++) {
            CompoundField field = expr->Compound.Fields[i];
            
            if(field.Kind == FIELD_NAME)
            {
                Fatal("Named field initializer not allowed for array compound literals");
            }
            else if(field.Kind == FIELD_INDEX)
            {
                int64_t Result = ResolveConstExpression(field.Index);
                if(Result < 0)
                {
                    Fatal("Field initializer index cannot be negative");
                }
                
                Index = Result;
            }
            
            if (Index >= type->Array.Size) {
                Fatal("Field initializer in array compound literal out of range");
            }
            Operand Init = ResolveExpectedExpression(expr->Compound.Fields[i].Init, type->Array.Elem);
            if (Init.type != type->Array.Elem) {
                Fatal("Compound literal element type mismatch");
            }
            Index++;
            
        }
    }
    return OperandRValue(type);
    
}

Operand PtrDecay(Operand expr) {
    
    
    if (expr.type->Kind == TYPE_ARRAY) {
        return OperandRValue(TypePointer(expr.type->Array.Elem));
    } else {
        
        return expr;
    }
}

Operand
ResolveExpressionCast(Expr *expr) 
{
    PCAssert((expr->kind == EXPR_CAST), "ResolveExpressionCast\n");
    Type *type = ResolveTypespec(expr->Cast.Type);
    Operand Result = PtrDecay(ResolveExpression(expr->Cast.expr));
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
    return OperandRValue(type);
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

Operand ResolveExpressionUnary(Expr *expr) {
    PCAssert((expr->kind == EXPR_UNARY), "ResolveExpressionUnary");
    Operand Operand = ResolveExpression(expr->Unary.expr);
    Type *type = Operand.type;
    switch (expr->Unary.Op) {
        case TOK_MUL:
        Operand = PtrDecay(Operand);
        if (type->Kind != TYPE_PTR) {
            Fatal("Cannot deref non-ptr type");
        }
        return(OperandLValue(type->Ptr.Elem));
        case TOK_AND:
        if (!Operand.IsLValue) {
            Fatal("Cannot take address of non-lvalue");
        }
        return OperandRValue(TypePointer(type));
        default:
        
        if (type->Kind != TYPE_I64) {
            printf("Can only use unary %s with ints", TokToString(expr->Unary.Op));
        }
        if (Operand.IsConst) {
            return(OperandConst(EvalIntUnary(expr->Unary.Op, Operand.Val)));
        } else {
            return(OperandRValue(type));
        }
    }
}

Operand ResolveExpressionIndex(Expr *expr) {
    
    PCAssert((expr->kind == EXPR_INDEX), "ResolveExpressionIndex");
    
    Operand operand = PtrDecay(ResolveExpression(expr->Index.expr));
    
    
    if (operand.type->Kind != TYPE_PTR) {
        Fatal("Can only index arrays or pointers");
    }
    
    Operand Index = ResolveExpression(expr->Index.Index);
    if (Index.type->Kind != TYPE_I64) {
        Fatal("Index expression must have type int");
    }
    return(OperandLValue(operand.type->Ptr.Elem));
    
}

Operand 
ResolveExpressionTernary(Expr *expr, Type *ExpectedType) {
    PCAssert((expr->kind == EXPR_TERNARY), "ResolveExpressionTernary\n");
    Operand Condition = PtrDecay(ResolveExpression(expr->Ternary.Condition));
    if (Condition.type->Kind != TYPE_I64 && Condition.type->Kind != TYPE_PTR) {
        Fatal("Ternary cond expression must have type int or ptr\n");
    }
    Operand ThenExpression = PtrDecay(ResolveExpectedExpression(expr->Ternary.ThenExpression, ExpectedType));
    Operand ElseExpression = PtrDecay(ResolveExpectedExpression(expr->Ternary.ElseExpression, ExpectedType));
    
    if (ThenExpression.type != ElseExpression.type) {
        Fatal("Ternary then/else expressions must have matching types\n");
    }
    if (Condition.IsConst && ThenExpression.IsConst && ElseExpression.IsConst) {
        return OperandConst(Condition.Val ? ThenExpression.Val : ElseExpression.Val);
    } else {
        return OperandRValue(ThenExpression.type);
    }
}

Operand ResolveExpressionField(Expr *expr) {
    assert(expr->kind == EXPR_FIELD);
    Operand Left = ResolveExpression(expr->Field.expr);
    Type *type = Left.type;
    CompleteType(type);
    if (type->Kind != TYPE_STRUCT && type->Kind != TYPE_UNION) {
        Fatal("Can only access fields on aggregate types");
        return OperandNull;
    }
    
    
    
    for (size_t i = 0; i < type->Aggregate.NumFields; i++) {
        TypeField field = type->Aggregate.Fields[i];
        
        if (strcmp(field.Name, expr->Field.Name) == 0) {
            return (Left.IsLValue ? OperandLValue(field.type) : OperandRValue(field.type));
        }
        
    }
    
    printf("No field named '%s'", expr->Field.Name);
    exit(-1);
    return OperandNull;
}

Operand
ResolveExpectedExpression(Expr *expr, Type *ExpectedType) {
    
    Operand result;
    
    switch (expr->kind) {
        
        case EXPR_I64:
        
        result = OperandConst(expr->IntVal);
        break;
        case EXPR_FLOAT:
        
        result = OperandRValue(TypeFloat);
        break;
        case EXPR_STR:
        result = OperandRValue(TypePointer(TypeChar));
        break;
        case EXPR_NAME:
        result = ResolveExpressionName(expr);
        break;
        case EXPR_CAST:
        result = ResolveExpressionCast(expr);
        break;
        case EXPR_CALL:
        result = ResolveExpressionCall(expr);
        break;
        case EXPR_INDEX:
        
        result = ResolveExpressionIndex(expr);
        break;
        case EXPR_FIELD:
        
        result = ResolveExpressionField(expr);
        break;
        case EXPR_COMPOUND:
        
        result = ResolveExpressionCompound(expr, ExpectedType);
        break;
        case EXPR_UNARY:
        result =  ResolveExpressionUnary(expr);
        break;
        case EXPR_BINARY:
        
        result =  ResolveExpressionBinary(expr);
        break;
        case EXPR_TERNARY:
        result =  ResolveExpressionTernary(expr, ExpectedType);
        break;
        case EXPR_SIZEOF_EXPR: {
            
            Operand Result = ResolveExpression(expr->SizeofExpression);
            Type *type = Result.type;
            CompleteType(type);
            result =  OperandConst(TypeSizeof(type));
            break;
        }
        case EXPR_SIZEOF_TYPE: {
            
            Type *type = ResolveTypespec(expr->SizeofType);
            CompleteType(type);
            result =  OperandConst(TypeSizeof(type));
            break;
            
        }
        default:
        Fatal("Default case in ResolveExpectedExpression\n");
        exit(-1);
        result =  OperandNull;
    }
    
    if (result.type) {
        //assert(!expr->type || (memcmp(expr->type, result.type, sizeof(Type)) == 0));
        expr->type = result.type;
    }
    
    return result;
}

Operand ResolveExpression(Expr *expr) {
    return ResolveExpectedExpression(expr, NULL);
}
#define MAX(x, y) ((x) >= (y) ? (x) : (y))
void 
TypeCompleteStruct(Type *type, TypeField *fields, size_t NumFields) {
    PCAssert((type->Kind == TYPE_COMPLETING), "Not completing in TypeCompleteStruct\n");
    type->Kind = TYPE_STRUCT;
    type->Size = 0;
    
    type->Align = 0;
    
    
    for (TypeField *it = fields; it != fields + NumFields; it++) {
        assert(IS_POW2(TypeAlignof(it->type)));
        type->Size = TypeSizeof(it->type) + ALIGN_UP(type->Size, TypeAlignof(it->type));
        type->Align = MAX(type->Align, TypeAlignof(it->type));
        
    }
    
    
    type->Aggregate.Fields = memdup(fields, NumFields * sizeof(*fields));
    type->Aggregate.NumFields = NumFields;
    
}


void TypeCompleteUnion(Type *type, TypeField *fields, size_t NumFields) {
    
    
    PCAssert((type->Kind == TYPE_COMPLETING), "Not typecompleing\n");
    type->Kind = TYPE_UNION;
    type->Size = 0;
    
    type->Align = 0;
    for (TypeField *it = fields; it != fields + NumFields; it++) {
        assert(it->type->Kind > TYPE_COMPLETING);
        type->Size = MAX(type->Size, TypeSizeof(it->type));
        type->Align = MAX(type->Align, TypeAlignof(it->type));
    }
    
    type->Aggregate.Fields = memdup(fields, NumFields * sizeof(*fields));
    type->Aggregate.NumFields = NumFields;
}

bool32 DuplicateFields(TypeField *fields, size_t num_fields) {
    for (size_t i = 0; i < num_fields; i++) {
        for (size_t j = i+1; j < num_fields; j++) {
            if (fields[i].Name == fields[j].Name) {
                return true;
            }
        }
    }
    return false;
}

void CompleteType(Type *type) {
    
    if (type->Kind == TYPE_COMPLETING) {
        Fatal("Type completion cycle\n");
        
        
    } else if (type->Kind != TYPE_INCOMPLETE) {
        
        return;
    }
    
    type->Kind = TYPE_COMPLETING;
    Decl *decl = type->sym->decl;
    
    assert(decl->kind == DECL_STRUCT || decl->kind == DECL_UNION);
    
    TypeField *fields = NULL;
    for (size_t i = 0; i < decl->Aggregate.NumItems; i++) {
        
        AggregateItem item = decl->Aggregate.Items[i];
        Type *item_type = ResolveTypespec(item.Type);
        CompleteType(item_type);
        for (size_t j = 0; j < item.NumNames; j++) {
            buf_push(fields, (TypeField){item.Names[j], item_type});
        }
    }
    if (buf_len(fields) == 0) {
        Fatal("No fields");
    }
    if (DuplicateFields(fields, buf_len(fields))) {
        Fatal("Duplicate fields");
    }
    if (decl->kind == DECL_STRUCT) {
        TypeCompleteStruct(type, fields, buf_len(fields));
    } else {
        assert(decl->kind == DECL_UNION);
        TypeCompleteUnion(type, fields, buf_len(fields));
    }
    buf_push(OrderedSyms, type->sym);
    
    
    
    
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
        
        Operand Result = ResolveExpectedExpression(decl->var.expr, type);
        if (type && Result.type != type) {
            Fatal("Declared var type does not match inferred type\n");
            
        }
        type = Result.type;
    }
    
    CompleteType(type);
    return(type);
    
}


Type * 
TypeFunc(Type  **params, size_t num_params, Type *ret) {
    
    for (CachedFuncType *it = CachedFuncTypes; it != buf_end(CachedFuncTypes); it++) {
        if (it->NumParams == num_params && it->Ret == ret) {
            bool32 match = true;
            for (size_t i = 0; i < num_params; i++) {
                if (it->Params[i] != params[i]) {
                    match = false;
                    break;
                }
            }
            if (match) {
                return it->Func;
            }
        }
    }
    Type *type = TypeAlloc(TYPE_FUNC);
    type->Size = PTR_SIZE;
    type->Align = PTR_ALIGN;
    type->Func.Params = memdup(params, num_params * sizeof(*params));
    type->Func.NumParams = num_params;
    type->Func.Ret = ret;
    buf_push(CachedFuncTypes, (CachedFuncType){params, num_params, ret, type});
    return type;
}



Type *
ResolveDeclFunc(Decl *decl) {
    assert(decl->kind == DECL_FUNC);
    Type **params = NULL;
    for (size_t i = 0; i < decl->Func.NumParams; i++) {
        buf_push(params, ResolveTypespec(decl->Func.Params[i].Type));
    }
    Type *ret_type = TypeVoid;
    if (decl->Func.RetType) {
        ret_type = ResolveTypespec(decl->Func.RetType);
    }
    return TypeFunc(params, buf_len(params), ret_type);
}

Type *
ResolveDeclConst(Decl *decl, int64_t *Val) {
    PCAssert((decl->kind == DECL_CONST), "ResolveDeclConst\n");
    Operand Result = ResolveExpression(decl->ConstDecl.Expression);
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
    buf_push(OrderedSyms, sym);
    
}

void SymPushVar(const char *name, Type *type) {
    if (local_syms_end == LocalSyms + MAX_LOCAL_SYMS) {
        Fatal("Too many local symbols");
    }
    *local_syms_end++ = (Sym){
        .Name = name,
        .Kind = SYM_VAR,
        .State = SYM_RESOLVED,
        .type = type,
    };
}

void ResolveStatementBlock(StatementList block, Type *ret_type);

void ResolveCondExpression(Expr *expr) {
    Operand Cond = ResolveExpression(expr);
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
        
        for (size_t i = 0; i < stmt->IfStatement.NumElseIfs; i++) {
            ElseIf elseif = stmt->IfStatement.ElseIfs[i];
            
            ResolveCondExpression(elseif.Cond);
            ResolveStatementBlock(elseif.Block, RetType);
        }
        if (stmt->IfStatement.ElseBlock.Statements) {
            ResolveStatementBlock(stmt->IfStatement.ElseBlock, RetType);
        }
        break;
        
        case STMT_WHILE:
        case STMT_DO_WHILE:
        ResolveCondExpression(stmt->WhileStatement.Cond);
        ResolveStatementBlock(stmt->WhileStatement.Block, RetType);
        break;
        case STMT_FOR: {
            Sym *start = sym_enter();
            ResolveStatement(stmt->ForStatement.Init, RetType);
            ResolveCondExpression(stmt->ForStatement.Cond);
            ResolveStatementBlock(stmt->ForStatement.Block, RetType);
            ResolveStatement(stmt->ForStatement.Next, RetType);
            sym_leave(start);
            break;
        }
        case STMT_SWITCH: {
            Operand expr = ResolveExpression(stmt->SwitchStatement.expr);
            
            for (size_t i = 0; i < stmt->SwitchStatement.NumCases; i++) {
                SwitchCase switch_case = stmt->SwitchStatement.Cases[i];
                for (size_t j = 0; j < switch_case.NumExprs; j++) {
                    if (ResolveExpression(switch_case.exprs[j]).type != expr.type) {
                        Fatal("Switch case expression type mismatch");
                    }
                    ResolveStatementBlock(switch_case.Block, RetType);
                }
            }
            
            break;
            
        }
        
        case STMT_ASSIGN: {
            
            Operand Left = ResolveExpression(stmt->Assign.Left);
            if (stmt->Assign.Right) {
                Operand Right = ResolveExpectedExpression(stmt->Assign.Right, Left.type);
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

void ResolveStatementBlock(StatementList block, Type *ret_type) {
    
    Sym *scope = sym_enter();
    for (size_t i = 0; i < block.NumStatements; i++) {
        ResolveStatement(block.Statements[i], ret_type);
    }
    sym_leave(scope);
}


void ResolveFuncBody(Sym *sym) {
    Decl *decl = sym->decl;
    assert(decl->kind == DECL_FUNC);
    assert(sym->State == SYM_RESOLVED);
    Sym *scope = sym_enter();
    for (size_t i = 0; i < decl->Func.NumParams; i++) {
        FuncParam param = decl->Func.Params[i];
        SymPushVar(param.Name, ResolveTypespec(param.Type));
    }
    ResolveStatementBlock(decl->Func.Block, ResolveTypespec(decl->Func.RetType));
    sym_leave(scope);
}

void FinalizeSym(Sym *sym)
{
    
    ResolveSym(sym);
    if (sym->Kind == SYM_TYPE) {
        
        CompleteType(sym->type);
    }
    else if(sym->Kind == SYM_FUNC)
    {
        ResolveFuncBody(sym);
    }
    
}

void FinalizeSyms(void) {
    for (Sym **it = GlobalSyms; it != buf_end(GlobalSyms); it++) {
        Sym *sym = *it;
        FinalizeSym(sym);
    }
}