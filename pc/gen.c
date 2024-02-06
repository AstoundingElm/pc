#include <stdarg.h>

char *gen_buf = NULL;
FILE *Output = NULL;
int gen_indent;

void genf(const char *Buf)
{
    fprintf(Output, Buf);
}

void genln(void) {
    fprintf(Output, "\n%.*s", gen_indent * 4, "                                                                  ");
}

void PrintNewLine()
{
    fprintf(Output, "\n");
}

char *type_to_cdecl(Type *type, const char *str);
char *typespec_to_cdecl(Typespec *typespec, const char *str);
void gen_stmt_block(StatementList block);

char *strf(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    size_t n = 1 + vsnprintf(NULL, 0, fmt, args);
    va_end(args);
    char *str = malloc(n);
    va_start(args, fmt);
    vsnprintf(str, n, fmt, args);
    va_end(args);
    return str;
}



const char *cdecl_paren(const char *str, bool32 b) {
    return b ? strf("(%s)", str) : str;
}

void gen_expr(Expr *expr) {
    switch (expr->kind) {
        case EXPR_I64:
        fprintf(Output, "%lld", expr->IntVal);
        break;
        case EXPR_FLOAT:
        fprintf(Output, "%f", expr->FloatVal);
        break;
        case EXPR_STR:
        // TODO: proper quoted string escaping
        fprintf(Output, "\"%s\"", expr->StringVal);
        break;
        case EXPR_NAME:
        fprintf(Output, "%s", expr->Name);
        break;
        case EXPR_CAST:
        fprintf(Output, "(%s)(", type_to_cdecl(expr->Cast.Type->type, ""));
        gen_expr(expr->Cast.expr);
        genf(")");
        PrintNewLine();
        break;
        case EXPR_CALL:
        gen_expr(expr->Call.Expression);
        genf("(");
        for (size_t i = 0; i < expr->Call.NumArgs; i++) {
            if (i != 0) {
                genf(", ");
            }
            gen_expr(expr->Call.Args[i]);
        }
        genf(")");
        PrintNewline();
        break;
        case EXPR_INDEX:
        gen_expr(expr->Index.expr);
        genf("[");
        gen_expr(expr->Index.Index);
        genf("]");
        PrintNewLine();
        break;
        case EXPR_FIELD:
        gen_expr(expr->Field.expr);
        fprintf(Output, ".%s", expr->Field.Name);
        break;
        case EXPR_COMPOUND:
        if (expr->Compound.Type) {
            fprintf(Output, "(%s){", typespec_to_cdecl(expr->Compound.Type, ""));
        } else {
            fprintf(Output,"(%s){", type_to_cdecl(expr->type, ""));
        }
        for (size_t i = 0; i < expr->Compound.NumFields; i++) {
            if (i != 0) {
                genf(", ");
            }
            CompoundField field = expr->Compound.Fields[i];
            if (field.Kind == FIELD_NAME) {
                fprintf(Output, ".%s = ", field.Name);
            } else if (field.Kind == FIELD_INDEX) {
                genf("[");
                gen_expr(field.Index);
                genf("] = ");
            }
            gen_expr(field.Init);
        }
        genf("}");
        break;
        case EXPR_UNARY:
        fprintf(Output, "%s(", TokToString(expr->Unary.Op));
        gen_expr(expr->Unary.expr);
        genf(")");
        
        break;
        case EXPR_BINARY:
        genf("(");
        gen_expr(expr->Binary.Left);
        fprintf(Output,") %s (", TokToString(expr->Binary.Op));
        gen_expr(expr->Binary.Right);
        genf(")");
        
        break;
        case EXPR_TERNARY:
        genf("(");
        gen_expr(expr->Ternary.Condition);
        genf(" ? ");
        gen_expr(expr->Ternary.ThenExpression);
        genf(" : ");
        gen_expr(expr->Ternary.ElseExpression);
        genf(")");
        break;
        case EXPR_SIZEOF_EXPR:
        genf("sizeof(");
        gen_expr(expr->SizeofExpression);
        genf(")");
        break;
        case EXPR_SIZEOF_TYPE:
        fprintf(Output, "sizeof(%s)", type_to_cdecl(expr->SizeofType->type, ""));
        break;
        default:
        assert(0);
    }
}



const char *gen_expr_str(Expr *expr) {
    char *temp = gen_buf;
    gen_buf = NULL;
    gen_expr(expr);
    const char *result = gen_buf;
    gen_buf = temp;
    return result;
}

char *typespec_to_cdecl(Typespec *typespec, const char *str) {
    // TODO: Figure out how to handle type vs typespec in C gen for inferred types. How to prevent "flattened" const values?
    switch (typespec->kind) {
        case TYPESPEC_NAME:
        return strf("%s%s%s", typespec->name, *str ? " " : "", str);
        case TYPESPEC_PTR:
        return typespec_to_cdecl(typespec->Ptr.Elem, cdecl_paren(strf("*%s", str), *str));
        case TYPESPEC_ARRAY:
        return typespec_to_cdecl(typespec->Array.Elem, cdecl_paren(strf("%s[%s]", str, gen_expr_str(typespec->Array.Size)), *str));
        case TYPESPEC_FUNC: {
            char *result = NULL;
            fprintf(Output, result, "%s(", cdecl_paren(strf("*%s", str), *str));
            if (typespec->Func.NumArgs == 0) {
                fprintf(Output, result, "void");
            } else {
                for (size_t i = 0; i < typespec->Func.NumArgs; i++) {
                    fprintf(Output, result, "%s%s", i == 0 ? "" : ", ", typespec_to_cdecl(typespec->Func.Args[i], ""));
                }
            }
            fprintf(Output, result, ")");
            
            return typespec_to_cdecl(typespec->Func.Ret, result);
        }
        default:
        assert(0);
        return NULL;
    }
}

const char *cdecl_name(Type *type) {
    switch (type->Kind) {
        case TYPE_VOID:
        return "void";
        case TYPE_CHAR:
        return "char";
        case TYPE_I64:
        return "int";
        case TYPE_FLOAT:
        return "float";
        case TYPE_STRUCT:
        case TYPE_UNION:
        return type->sym->Name;
        default:
        assert(0);
        return NULL;
    }
}

char *type_to_cdecl(Type *type, const char *str) {
    
    
    switch (type->Kind) {
        case TYPE_VOID:
        case TYPE_CHAR:
        case TYPE_I64:
        case TYPE_FLOAT:
        case TYPE_STRUCT:
        case TYPE_UNION:
        return strf("%s%s%s", cdecl_name(type), *str ? " " : "", str);
        case TYPE_PTR:
        return type_to_cdecl(type->Ptr.Elem, cdecl_paren(strf("*%s", str), *str));
        case TYPE_ARRAY:
        return type_to_cdecl(type->Array.Elem, cdecl_paren(strf("%s[%llu]", str, type->Array.Size), *str));
        case TYPE_FUNC: {
            char *result = NULL;
            fprintf(Output, result, "%s(", cdecl_paren(strf("*%s", str), *str));
            if (type->Func.NumParams == 0) {
                fprintf(Output, result, "void");
            } else {
                for (size_t i = 0; i < type->Func.NumParams; i++) {
                    fprintf(Output,result, "%s%s", i == 0 ? "" : ", ", type_to_cdecl(type->Func.Params[i], ""));
                }
            }
            fprintf(Output, result, ")");
            return type_to_cdecl(type->Func.Ret, result);
        }
        default:
        assert(0);
        return NULL;
    }
    
    
}


void gen_simple_stmt(Statement *stmt) {
    
    
    switch (stmt->Kind) {
        case STMT_EXPR:
        gen_expr(stmt->Expression);
        break;
        case STMT_INIT:
        fprintf(Output, "%s = ", type_to_cdecl(stmt->Initialisation.Expression->type, stmt->Initialisation.Name));
        gen_expr(stmt->Initialisation.Expression);
        break;
        case STMT_ASSIGN:
        gen_expr(stmt->Assign.Left);
        if (stmt->Assign.Right) {
            fprintf(Output," %s ", TokToString(stmt->Assign.Op));
            gen_expr(stmt->Assign.Right);
        } else {
            fprintf(Output,"%s", TokToString(stmt->Assign.Op));
        }
        break;
        default:
        assert(0);
    }
    
}

void gen_stmt(Statement *stmt) {
    switch (stmt->Kind) {
        case STMT_RETURN:
        fprintf(Output, "return");
        if (stmt->Expression) {
            genf(" ");
            gen_expr(stmt->Expression);
        }
        genf(";");
        break;
        case STMT_BREAK:
        fprintf(Output, "break;");
        break;
        case STMT_CONTINUE:
        genf("continue;");
        break;
        case STMT_BLOCK:
        genln();
        gen_stmt_block(stmt->Block);
        break;
        case STMT_IF:
        genf("if (");
        gen_expr(stmt->IfStatement.Cond);
        genf(") ");
        gen_stmt_block(stmt->IfStatement.ThenBlock);
        for (size_t i = 0; i < stmt->IfStatement.NumElseIfs; i++) {
            ElseIf elseif = stmt->IfStatement.ElseIfs[i];
            genf(" else if (");
            gen_expr(elseif.Cond);
            genf(") ");
            gen_stmt_block(elseif.Block);
        }
        if (stmt->IfStatement.ElseBlock.Statements) {
            genf(" else ");
            gen_stmt_block(stmt->IfStatement.ElseBlock);
        }
        break;
        case STMT_WHILE:
        genf("while (");
        gen_expr(stmt->WhileStatement.Cond);
        genf(") ");
        gen_stmt_block(stmt->WhileStatement.Block);
        break;
        case STMT_DO_WHILE:
        genf("do ");
        gen_stmt_block(stmt->WhileStatement.Block);
        genf(" while (");
        gen_expr(stmt->WhileStatement.Cond);
        genf(");");
        break;
        case STMT_FOR:
        genf("for (");
        if (stmt->ForStatement.Init) {
            gen_simple_stmt(stmt->ForStatement.Init);
        }
        genf(";");
        if (stmt->ForStatement.Cond) {
            genf(" ");
            gen_expr(stmt->ForStatement.Cond);
        }
        genf(";");
        if (stmt->ForStatement.Next) {
            genf(" ");
            gen_simple_stmt(stmt->ForStatement.Next);
        }
        genf(") ");
        gen_stmt_block(stmt->ForStatement.Block);
        break;
        case STMT_SWITCH:
        genf("switch (");
        gen_expr(stmt->SwitchStatement.expr);
        genf(") {");
        for (size_t i = 0; i < stmt->SwitchStatement.NumCases; i++) {
            SwitchCase switch_case = stmt->SwitchStatement.Cases[i];
            for (size_t j = 0; j < switch_case.NumExprs; j++) {
                genf("case ");
                gen_expr(switch_case.exprs[j]);
                genf(":");
                
            }
            if (switch_case.IsDefault) {
                genf("default:");
            }
            genf(" ");
            gen_stmt_block(switch_case.Block);
        }
        genf("}");
        break;
        default:
        genln();
        gen_simple_stmt(stmt);
        genf(";");
        break;
    }
}


void gen_stmt_block(StatementList block) {
    genf("{");
    PrintNewLine();
    gen_indent++;
    for (size_t i = 0; i < block.NumStatements; i++) {
        gen_stmt(block.Statements[i]);
    }
    gen_indent--;
    genf("}");
    PrintNewLine();
}

void gen_func_decl(Decl *decl) {
    assert(decl->kind == DECL_FUNC);
    if (decl->Func.RetType) {
        fprintf(Output, "%s(", typespec_to_cdecl(decl->Func.RetType, decl->name));
    } else {
        fprintf(Output, "void %s(", decl->name);
    }
    if (decl->Func.NumParams == 0) {
        genf("void");
    } else {
        for (size_t i = 0; i < decl->Func.NumParams; i++) {
            FuncParam param = decl->Func.Params[i];
            if (i != 0) {
                genf(", ");
            }
            fprintf(Output, "%s", typespec_to_cdecl(param.Type, param.Name));
        }
    }
    genf(")");
}

void gen_func(Decl *decl) {
    assert(decl->kind == DECL_FUNC);
    gen_func_decl(decl);
    genf(" ");
    gen_stmt_block(decl->Func.Block);
}

void GenForwardDecls(void) {
    for (size_t i = 0; i < buf_len(GlobalSyms); i++) {
        
        
        Sym *sym = GlobalSyms[i];
        Decl *decl = sym->decl;
        if (!decl) {
            continue;
        }
        switch (decl->kind) {
            
            case DECL_STRUCT:
            fprintf(Output, "typedef struct %s %s;\n", sym->Name, sym->Name);
            PrintNewLine();
            break;
            case DECL_UNION:
            fprintf(Output,"typedef union %s %s;\n", sym->Name, sym->Name);
            PrintNewLine();
            break;
            case DECL_FUNC:
            gen_func_decl(sym->decl);
            fprintf(Output, ";\n");
            PrintNewLine();
            break;
            default:
            // Do nothing.
            break;
        }
    }
}

void gen_aggregate(Decl *decl) {
    assert(decl->kind == DECL_STRUCT || decl->kind == DECL_UNION);
    fprintf(Output, "%s %s {", decl->kind == DECL_STRUCT ? "struct" : "union", decl->name);
    gen_indent++;
    for (size_t i = 0; i < decl->Aggregate.NumItems; i++) {
        AggregateItem item = decl->Aggregate.Items[i];
        for (size_t j = 0; j < item.NumNames; j++) {
            fprintf(Output,"%s;", typespec_to_cdecl(item.Type, item.Names[j]));
        }
    }
    gen_indent--;
    genf("};");
}

void gen_sym(Sym *sym) {
    Decl *decl = sym->decl;
    if (!decl) {
        return;
    }
    switch (decl->kind) {
        case DECL_CONST:
        fprintf(Output, "enum { %s = ", sym->Name);
        gen_expr(decl->ConstDecl.Expression);
        genf(" };");
        PrintNewLine();
        break;
        case DECL_VAR:
        if (decl->var.type) {
            fprintf(Output, "%s", typespec_to_cdecl(decl->var.type, sym->Name));
        } else {
            fprintf(Output, "%s", type_to_cdecl(sym->type, sym->Name));
        }
        if (decl->var.expr) {
            genf(" = ");
            gen_expr(decl->var.expr);
        }
        genf(";");
        PrintNewLine();
        break;
        case DECL_FUNC:
        gen_func(sym->decl);
        PrintNewLine();
        break;
        case DECL_STRUCT:
        case DECL_UNION:
        gen_aggregate(sym->decl);
        PrintNewLine();
        break;
        case DECL_TYPEDEF:
        fprintf(Output,"typedef %s;", type_to_cdecl(sym->type, sym->Name));
        PrintNewLine();
        break;
        default:
        assert(0);
        break;
    }
}

void GenTypes()
{
    genf("#include <stdio.h>\n");
    genf("#include <stdint.h>\n");
    genf("typedef int64_t i64;\n");
}

void gen_ordered_decls(void) {
    for (size_t i = 0; i < buf_len(OrderedSyms); i++) {
        gen_sym(OrderedSyms[i]);
    }
}

void GenAll()
{
    //Genf("// Forward declarations");
    
    Output = fopen("out.c", "wb");
    if(Output){
        
        
        GenTypes();
        GenForwardDecls();
        
        genln();
        //Genln("// Ordered declarations");
        gen_ordered_decls();
        
    }
}