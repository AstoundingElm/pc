Typespec *parse_ion_type(void);

void optional_token(TokenKind kind) {
    if(token.kind == kind) { next_token(); }
}

bool is_block_stmt = false;
Decl *parse_decl_opt(void);
Decl *parse_decl(void);
Typespec *parse_type(void);
Stmt *parse_stmt(void);
Expr *parse_expr(void);
const char *parse_name(void);
Notes parse_notes(void);
bool is_p_func = false;
Typespec *parse_type_func_param(void) {
    Typespec *type = parse_type();
    if (match_token(TOKEN_COLON)) {
        if (type->kind != TYPESPEC_NAME) {
            error_here("Colons in parameters of func types must be preceded by names.");
        }
        type = parse_type();
    }
    return type;
}

Typespec *parse_type_func(void) {
    SrcPos pos = token.pos;
    Typespec **args = NULL;
    bool has_varargs = false;
    expect_token(TOKEN_LPAREN);
    if (!is_token(TOKEN_RPAREN)) {
        buf_push(args, parse_type_func_param());
        while (match_token(TOKEN_COMMA)) {
            if (match_token(TOKEN_ELLIPSIS)) {
                if (has_varargs) {
                    error_here("Multiple ellipsis instances in function type");
                }
                has_varargs = true;
            } else {
                if (has_varargs) {
                    error_here("Ellipsis must be last parameter in function type");
                }
                buf_push(args, parse_type_func_param());
            }
        }
    }
    expect_token(TOKEN_RPAREN);
    Typespec *ret = NULL;
    if (match_token(TOKEN_COLON)) {
        ret = parse_type();
    }
    return new_typespec_func(pos, args, buf_len(args), ret, has_varargs);
}

Typespec *parse_type_tuple(void) {
    SrcPos pos = token.pos;
    Typespec **fields = NULL;
    while (!is_token(TOKEN_RBRACE)) {
        Typespec *field = parse_type();
        buf_push(fields, field);
        if (!match_token(TOKEN_COMMA)) {
            break;
        }
    }
    expect_token(TOKEN_RBRACE);
    return new_typespec_tuple(pos, fields, buf_len(fields));
}

Decl * parse_decl_struct(const char *, SrcPos, DeclKind);
Typespec *parse_type_base(void) {

    if (is_token(TOKEN_NAME) || match_keyword(struct_keyword)) {


        SrcPos pos = token.pos;
        const char **names = NULL;
        buf_push(names, token.name);
        next_token();
        while (match_token(TOKEN_DOT)) {
            buf_push(names, parse_name());
        }
        return new_typespec_name(pos, names, buf_len(names));
    } else if (match_keyword(func_keyword)) {
        return parse_type_func();
    } 
    
    else if (match_token(TOKEN_LPAREN)) {
        Typespec *type = parse_type();
        expect_token(TOKEN_RPAREN);
        return type;
    } else if (match_token(TOKEN_LBRACE)) {
        return parse_type_tuple();
    } else {
       
        fatal_error_here("Unexpected token %s in type", token_info());
        return NULL;
    }
}

Typespec * p_get_type(const char * name, SrcPos pos) {
    const char **names = NULL;
    buf_push(names, name);
    return new_typespec_name(pos, names, buf_len(names));
    
}

Token temp_token;
size_t start;

void save_state() {
    memcpy(&temp_token, &token, sizeof(token));
    start = strlen(stream);
 }

void restore_state() {

    while(start != strlen(stream))
    {
        --stream;
    }

    token  = temp_token;
    
}

Typespec * parse_dereference(){
    printf("JHSHHSHS");
    //exit(-1);
    Typespec * type = new_typespec_ptr(token.pos, type);

    return type;
}

Typespec * get_type(){
    save_state(); 

    while(is_token(TOKEN_PTR)) {
            assert(is_token(TOKEN_PTR));
            next_token();
        }
        /*if(is_token(TOKEN_ASSIGN)){
            return parse_dereference();
            //next_token();
            //goto parse_base;
        }*/
         if(match_token(TOKEN_LBRACKET)) {
            if (!is_token(TOKEN_RBRACKET)) {
                Expr *size = parse_expr();
            }

            expect_token(TOKEN_RBRACKET);
        }
    
    parse_base:
    Typespec *type = parse_type_base();
    restore_state();
    return type;
}

Typespec *parse_type(void) {

    SrcPos pos = token.pos;
    Typespec  *p_type = NULL;

    if(is_token(TOKEN_COLON))
    next_token();

    if(match_token(TOKEN_LBRACKET)) {
            Expr *size = NULL;
            if (!is_token(TOKEN_RBRACKET)) {
                size = parse_expr();
            }

            expect_token(TOKEN_RBRACKET);

            p_type = parse_type_base();
            p_type = new_typespec_array(pos, p_type, size);
            return p_type;
    }

        p_type = get_type();
           
        if(is_token(TOKEN_PTR)){
        while(is_token(TOKEN_PTR)) {
            assert(is_token(TOKEN_PTR));
            next_token();
            p_type = new_typespec_ptr(pos, p_type);

        }

        if(match_token(TOKEN_LBRACKET)) {
            Expr *size = NULL;
            if (!is_token(TOKEN_RBRACKET)) {
                size = parse_expr();
            }

            expect_token(TOKEN_RBRACKET);

            p_type = new_typespec_array(pos, p_type, size);
        }

        next_token();

        return p_type;
    }


    Typespec  *type = parse_type_base();
     
     while (is_token(TOKEN_LBRACKET) || is_token(TOKEN_MUL) || is_keyword(const_keyword)) {
        if (match_token(TOKEN_LBRACKET)) {
            Expr *size = NULL;
            if (!is_token(TOKEN_RBRACKET)) {
                size = parse_expr();
            }
            expect_token(TOKEN_RBRACKET);
            type = new_typespec_array(pos, type, size);
        } else if (match_keyword(const_keyword)) {
            type = new_typespec_const(pos, type);
        } else {
            //printf("YUYUYUY");
            assert(is_token(TOKEN_MUL));
            next_token();
            type = new_typespec_ptr(pos, type);
        
        }
    }

    return type;
}

CompoundField parse_expr_compound_field(void) {
    SrcPos pos = token.pos;
    if (match_token(TOKEN_LBRACKET)) {
        Expr *index = parse_expr();
        expect_token(TOKEN_RBRACKET);
        expect_token(TOKEN_ASSIGN);
        return (CompoundField){FIELD_INDEX, pos, parse_expr(), .index = index};
    } else {
        Expr *expr = parse_expr();
        if (match_token(TOKEN_ASSIGN)) {
            if (expr->kind != EXPR_NAME) {
                fatal_error_here("Named initializer in compound literal must be preceded by field name");
            }
            return (CompoundField){FIELD_NAME, pos, parse_expr(), .name = expr->name};
        } else {
            return (CompoundField){FIELD_DEFAULT, pos, expr};
        }
    }
}

Expr *parse_expr_compound(Typespec *type) {
    SrcPos pos = token.pos;
    expect_token(TOKEN_LBRACE);
    CompoundField *fields = NULL;
    while (!is_token(TOKEN_RBRACE)) {
        buf_push(fields, parse_expr_compound_field());
        if (!match_token(TOKEN_COMMA)) {
            break;
        }
    }
    expect_token(TOKEN_RBRACE);
    return new_expr_compound(pos, type, fields, buf_len(fields));
}

Expr *parse_expr_new(SrcPos pos) {
    Expr *alloc = NULL;
    if (match_token(TOKEN_LPAREN)) {
        alloc = parse_expr();
        expect_token(TOKEN_RPAREN);
    }
    Expr *len = NULL;
    if (match_token(TOKEN_LBRACKET)) {
        len = parse_expr();
        expect_token(TOKEN_RBRACKET);
    }
    Expr *arg = NULL;
    if (!match_keyword(undef_keyword)) {
        arg = parse_expr();
    }
    return new_expr_new(pos, alloc, len, arg);
}

Expr *parse_expr_unary(void);

Expr *parse_expr_operand(void) {

    SrcPos pos = token.pos;

     if (is_token(TOKEN_INT)) {
        unsigned long long val = token.int_val;
        TokenMod mod = token.mod;
        TokenSuffix suffix = token.suffix;
        next_token();
        return new_expr_int(pos, val, mod, suffix);
    } else if (is_token(TOKEN_FLOAT)) {
        const char *start = token.start;
        const char *end = token.end;
        double val = token.float_val;
        TokenSuffix suffix = token.suffix;
        next_token();
        return new_expr_float(pos, start, end, val, suffix);
    } else if (is_token(TOKEN_STR)) {
        const char *val = token.str_val;
        TokenMod mod = token.mod;
        next_token();
        return new_expr_str(pos, val, mod);
    } else if (is_token(TOKEN_NAME)) {
        const char *name = token.name;
        next_token();
        if (is_token(TOKEN_LBRACE)) {
            return parse_expr_compound(new_typespec_name(pos, &name, 1));
        } 
        else {
            
            return new_expr_name(pos, name);
        }
    } else if (match_keyword(new_keyword)) {
        return parse_expr_new(pos);
    } else if (match_keyword(sizeof_keyword)) {
        expect_token(TOKEN_LPAREN);
        if (match_token(TOKEN_COLON)) {
            Typespec *type = parse_type();
            expect_token(TOKEN_RPAREN);
            return new_expr_sizeof_type(pos, type);
        } else {
            Expr *expr = parse_expr();
            expect_token(TOKEN_RPAREN);
            return new_expr_sizeof_expr(pos, expr);
        }
    } else if (match_keyword(alignof_keyword)) {
        expect_token(TOKEN_LPAREN);
        if (match_token(TOKEN_COLON)) {
            Typespec *type = parse_type();
            expect_token(TOKEN_RPAREN);
            return new_expr_alignof_type(pos, type);
        } else {
            Expr *expr = parse_expr();
            expect_token(TOKEN_RPAREN);
            return new_expr_alignof_expr(pos, expr);
        }
    } else if (match_keyword(typeof_keyword)) {
        expect_token(TOKEN_LPAREN);
        if (match_token(TOKEN_COLON)) {
            Typespec *type = parse_type();
            expect_token(TOKEN_RPAREN);
            return new_expr_typeof_type(pos, type);
        } else {
            Expr *expr = parse_expr();
            expect_token(TOKEN_RPAREN);
            return new_expr_typeof_expr(pos, expr);
        }
    } else if (match_keyword(offsetof_keyword)) {
        expect_token(TOKEN_LPAREN);
        Typespec *type = parse_type();
        expect_token(TOKEN_COMMA);
        const char *name = parse_name();
        expect_token(TOKEN_RPAREN);
        return new_expr_offsetof(pos, type, name);
    } else if (is_token(TOKEN_LBRACE)) {
        return parse_expr_compound(NULL);
    } else if (match_token(TOKEN_LPAREN)) {
        if (match_token(TOKEN_COLON)) {
            Typespec *type = parse_type();
            expect_token(TOKEN_RPAREN);
            if (is_token(TOKEN_LBRACE)) {
                return parse_expr_compound(type);
            } else {


                Expr *expr =  new_expr_cast(pos, type, parse_expr_unary());
                

                return expr;
            }
        } else {
            Expr *expr = parse_expr();
            expect_token(TOKEN_RPAREN);
            return new_expr_paren(pos, expr);
        }
    } 
     
    else {
        printf("%s\n", token.name);
      fatal_error_here("Unexpected token %s in expression", token_info());
        
        return NULL;
    }
}

//bool is_array = false;

Expr *parse_expr_base(void) {
    Expr *expr = parse_expr_operand();

    while (is_token(TOKEN_LPAREN) || is_token(TOKEN_LBRACKET) || is_token(TOKEN_DOT) || is_token(TOKEN_INC) || is_token(TOKEN_DEC)) {
        SrcPos pos = token.pos;
        if (match_token(TOKEN_LPAREN)) {
            Expr **args = NULL;
            if (!is_token(TOKEN_RPAREN)) {
                buf_push(args, parse_expr());
                while (match_token(TOKEN_COMMA)) {
                    buf_push(args, parse_expr());
                }
            }
            expect_token(TOKEN_RPAREN);
            expr = new_expr_call(pos, expr, args, buf_len(args));
            //  optional_token(TOKEN_SEMICOLON)
        } 

        else if (match_token(TOKEN_LBRACKET)) {
            
            //printf("Index\n");
           // if(is_token(TOKEN_NAME) || is_token(TOKEN_INT)){
            Expr *index = parse_expr();
        //}
            expect_token(TOKEN_RBRACKET);
            expr = new_expr_index(pos, expr, index);
        } else if (is_token(TOKEN_DOT)) {
            next_token();
            const char *field = token.name;
            expect_token(TOKEN_NAME);
            expr = new_expr_field(pos, expr, field);
        } else {
            assert(is_token(TOKEN_INC) || is_token(TOKEN_DEC));
            TokenKind op = token.kind;
            next_token();
            expr = new_expr_modify(pos, op, true, expr);
        }
    }
    return expr;
}

bool is_unary_op(void) {
    return
    is_token(TOKEN_ADD) ||
    is_token(TOKEN_SUB) ||
    is_token(TOKEN_MUL) ||
    is_token(TOKEN_AND) ||
    is_token(TOKEN_NEG) ||
    is_token(TOKEN_NOT) ||
    is_token(TOKEN_INC) ||
    is_token(TOKEN_DEC);
}

Expr *parse_expr_unary(void) {
  /*save_state();
if (is_token(TOKEN_NAME)) {
  
     SrcPos pos = token.pos;
    
        const char *name = token.name;
next_token();
     if(is_token(TOKEN_PTR))
        {
           
            next_token();
            if(is_token(TOKEN_ASSIGN)){

                TokenKind op = TOKEN_PTR;
                //next_token();
                return new_expr_unary(pos, op, new_expr_name(pos, name));
            }
             
            
        }

   
    }
  restore_state();*/
    if (is_unary_op()) {
        SrcPos pos = token.pos;
        TokenKind op = token.kind;
        next_token();
        if (op == TOKEN_INC || op == TOKEN_DEC) {
        
            return new_expr_modify(pos, op, false, parse_expr_unary());
        }  
        else {
            //printf("Hell yeah\n");

            return new_expr_unary(pos, op, parse_expr_unary());
        }
    } else {
       return parse_expr_base();
    }
}

Expr *parse_expr_unary_deref(void) {

}

bool is_mul_op(void) {
    return TOKEN_FIRST_MUL <= token.kind && token.kind <= TOKEN_LAST_MUL;
}

Expr *parse_expr_mul(void) {
    Expr *expr = parse_expr_unary();
  
       while (is_mul_op()) {
        SrcPos pos = token.pos;
        TokenKind op = token.kind;
        next_token();
      

        expr = new_expr_binary(pos, op, expr, parse_expr_unary());
    }
    return expr;
}

bool is_add_op(void) {
    return TOKEN_FIRST_ADD <= token.kind && token.kind <= TOKEN_LAST_ADD;
}

Expr *parse_expr_add(void) {
    Expr *expr = parse_expr_mul();
/*if(is_block_stmt && is_token(TOKEN_PTR)){
return expr;
}*/

    /*if(is_token(TOKEN_PTR)){
        save_state();
        next_token();
        if(is_token(TOKEN_ASSIGN))
        //printf("JHHHH");
        //exit(-1);

    }*/

    while (is_add_op()) {
        SrcPos pos = token.pos;
        TokenKind op = token.kind;
        next_token();
        expr = new_expr_binary(pos, op, expr, parse_expr_mul());
    }

    return expr;
}

bool is_cmp_op(void) {
    return TOKEN_FIRST_CMP <= token.kind && token.kind <= TOKEN_LAST_CMP;
}

Expr *parse_expr_cmp(void) {
    Expr *expr = parse_expr_add();
    while (is_cmp_op()) {
        SrcPos pos = token.pos;
        TokenKind op = token.kind;
        next_token();
        expr = new_expr_binary(pos, op, expr, parse_expr_add());
    }
    return expr;
}

Expr *parse_expr_and(void) {
    Expr *expr = parse_expr_cmp();
    while (match_token(TOKEN_AND_AND)) {
        SrcPos pos = token.pos;
        expr = new_expr_binary(pos, TOKEN_AND_AND, expr, parse_expr_cmp());
    }
    return expr;
}

Expr *parse_expr_or(void) {
    Expr *expr = parse_expr_and();
    while (match_token(TOKEN_OR_OR)) {
        SrcPos pos = token.pos;
        expr = new_expr_binary(pos, TOKEN_OR_OR, expr, parse_expr_and());
    }
    return expr;
}

Expr *parse_expr_ternary(void) {
    SrcPos pos = token.pos;
    Expr *expr = parse_expr_or();
    if (match_token(TOKEN_QUESTION)) {
        Expr *then_expr = parse_expr_ternary();
        expect_token(TOKEN_COLON);
        Expr *else_expr = parse_expr_ternary();
        expr = new_expr_ternary(pos, expr, then_expr, else_expr);
    }
    return expr;
}

Expr *parse_expr(void) {


    return parse_expr_ternary();
}

Expr *parse_paren_expr(void) {
    expect_token(TOKEN_LPAREN);
    Expr *expr = parse_expr();
    expect_token(TOKEN_RPAREN);
    return expr;
}

StmtList parse_stmt_block_no_brace(void) {
    SrcPos pos = token.pos;
    Stmt **stmts = NULL;

    while (!is_token_eof()) {

  /*  if(is_token(TOKEN_NAME))
    {

        save_state();

        expect_token(TOKEN_NAME);

        if(is_keyword(fn_keyword) || is_keyword(struct_keyword) || is_token(TOKEN_AT)){

            //printf("yeah");
            restore_state();
            break;
        }

        restore_state();
    }*/


        buf_push(stmts, parse_stmt());
    
    }

    return new_stmt_list(pos, stmts, buf_len(stmts));

   }


StmtList parse_stmt_block(void) {
    SrcPos pos = token.pos;

    expect_token(TOKEN_LBRACE);

    Stmt **stmts = NULL;
    while (!is_token_eof() && !is_token(TOKEN_RBRACE)) {
        buf_push(stmts, parse_stmt());
    }

    expect_token(TOKEN_RBRACE);

    return new_stmt_list(pos, stmts, buf_len(stmts));
}


Stmt *parse_init_stmt(Expr *left);

Stmt *parse_stmt_if(SrcPos pos) {
   optional_token(TOKEN_LPAREN);
   Expr *cond;
 /*  if(is_token(TOKEN_NAME)){
    save_state();

    const char *name = parse_name();
    if(match_token(TOKEN_PTR)){
        TokenKind op = TOKEN_PTR;
        cond = new_expr_unary(pos, op, new_expr_name(pos, name));

        goto rest;
    }
    restore_state();
   }*/
    cond = parse_expr();
    //rest:
    Stmt *init = parse_init_stmt(cond);

    if (init) {
        if (match_token(TOKEN_SEMICOLON)) {
            cond = parse_expr();
        } else {
            cond = NULL;
        }
    }

    if(is_token(TOKEN_RPAREN)){
     expect_token(TOKEN_RPAREN);
    }
    StmtList then_block = parse_stmt_block();
    StmtList else_block = {0};
    ElseIf *elseifs = NULL;
    while (match_keyword(else_keyword)) {
        if (!match_keyword(if_keyword)) {
            else_block = parse_stmt_block();
            break;
        }
        Expr *elseif_cond = parse_expr();//parse_paren_expr();
        StmtList elseif_block = parse_stmt_block();
        buf_push(elseifs, (ElseIf){elseif_cond, elseif_block});
    }
    return new_stmt_if(pos, init, cond, then_block, elseifs, buf_len(elseifs), else_block);
}

Stmt *parse_stmt_while(SrcPos pos) {
    Expr *cond = parse_expr(); //parse_paren_expr();
    return new_stmt_while(pos, cond, parse_stmt_block());
}

Stmt *parse_stmt_do_while(SrcPos pos) {
    StmtList block = parse_stmt_block();
    if (!match_keyword(while_keyword)) {
        fatal_error_here("Expected 'while' after 'do' block");
        return NULL;
    }
    Stmt *stmt = new_stmt_do_while(pos, parse_paren_expr(), block);
    //expect_token(TOKEN_SEMICOLON);
    optional_token(TOKEN_SEMICOLON);
    return stmt;
}

bool is_assign_op(void) {
    return TOKEN_FIRST_ASSIGN <= token.kind && token.kind <= TOKEN_LAST_ASSIGN;
}


Stmt * parse_init_stmt_no_colon(Expr * left)
{
     if (match_token(TOKEN_COLON_ASSIGN)) {
        if (left->kind != EXPR_NAME) {
            fatal_error_here(":= must be preceded by a name");
            return NULL;
        }
        return new_stmt_init(left->pos, left->name, NULL, parse_expr(), false);
    } else if (match_token(TOKEN_COLON)) {

        
        if (left->kind != EXPR_NAME) {
            fatal_error_here(": must be preceded by a name");
            return NULL;
        }
        const char *name = left->name;
        Typespec *type = parse_type();
        Expr *expr = NULL;
        bool is_undef = false;
        if (match_token(TOKEN_ASSIGN)) {
            is_undef = match_keyword(undef_keyword);
            if (!is_undef) {
                expr = parse_expr();
            }
        }

       // optional_token(TOKEN_SEMICOLON);
        return new_stmt_init(left->pos, name, type, expr, is_undef);
    } 
    else{

 if (left->kind != EXPR_NAME) {
            fatal_error_here(": must be preceded by a name");
            return NULL;
        }
        const char *name = left->name;
        Typespec *type = parse_type();
        // printf("%s\n", token.name);
        Expr *expr = NULL;
        bool is_undef = false;
        if (match_token(TOKEN_ASSIGN)) {
            is_undef = match_keyword(undef_keyword);
            if (!is_undef) {
                expr = parse_expr();
            }
        }
        //optional_token(TOKEN_SEMICOLON);
        return new_stmt_init(left->pos, name, type, expr, is_undef);
    }


    return NULL;
}

Stmt *parse_init_stmt(Expr *left) {
    if (match_token(TOKEN_COLON_ASSIGN)) {
        if (left->kind != EXPR_NAME) {
            fatal_error_here(":= must be preceded by a name");
            return NULL;
        }
        return new_stmt_init(left->pos, left->name, NULL, parse_expr(), false);
    } else if (match_token(TOKEN_COLON)) {

        
        if (left->kind != EXPR_NAME) {
            fatal_error_here(": must be preceded by a name");
            return NULL;
        }
        const char *name = left->name;
        Typespec *type = parse_type();
        Expr *expr = NULL;
        bool is_undef = false;
        if (match_token(TOKEN_ASSIGN)) {
            is_undef = match_keyword(undef_keyword);
            if (!is_undef) {
                expr = parse_expr();
            }
        }
        return new_stmt_init(left->pos, name, type, expr, is_undef);
    } 
     return NULL;

 
}

  
Stmt *parse_simple_stmt()  {
    SrcPos pos = token.pos;
    Expr *expr  = NULL;
    if(is_token(TOKEN_NAME)) {
        //handle dererefernces
        save_state();
        const char *name = parse_name();
        if(match_token(TOKEN_PTR)) {
            if(is_token(TOKEN_ASSIGN) || is_token(TOKEN_SEMICOLON)){
                TokenKind op = TOKEN_PTR;
                expr = new_expr_unary(pos, op, new_expr_name(pos, name));
                goto pfunc;
            } 
        }
            //Handle arrays/indexes
            if(is_token(TOKEN_LBRACKET)) {
                expect_token(TOKEN_LBRACKET);
                if(is_token(TOKEN_NAME) || is_token(TOKEN_INT)) {
                    Expr *index_expr = parse_expr();
                }
                expect_token(TOKEN_RBRACKET);
                if(is_token(TOKEN_NAME)) {
                    restore_state();
                    is_p_func = true;
                    expr = new_expr_name(pos, name);
                    expect_token(TOKEN_NAME);
                    goto pfunc;
                }
            }
        restore_state();
    }
    expr = parse_expr();
    //if its not an array and not a dereference its p stmt (no semicolon)
    //can we have a p_parse_simple_stmt and a ion_parse_simple_stmt?
    pfunc:
    if(expr->kind == EXPR_NAME && is_p_func) {
        if (is_assign_op()) {
        TokenKind op = token.kind;
        next_token();
        Stmt *assign_stmt = new_stmt_assign(pos, op, expr, parse_expr());
        return assign_stmt;
    }
        
    Stmt *no_colon_stmt = parse_init_stmt_no_colon(expr);
        if (!no_colon_stmt) {
            no_colon_stmt = new_stmt_expr(pos, expr); 
        }       
        return no_colon_stmt;
    }

    Stmt *stmt = parse_init_stmt(expr);
    if (!stmt) {
        if (is_assign_op()) {
            TokenKind op = token.kind;
            next_token();
            stmt = new_stmt_assign(pos, op, expr, parse_expr());
        } else {
            stmt = new_stmt_expr(pos, expr);
        }
    }
    return stmt;
}

Stmt *parse_stmt_for(SrcPos pos) {
    Stmt *init = NULL;
    Expr *cond = NULL;
    Stmt *next = NULL;
    if (!is_token(TOKEN_LBRACE)) {

        if(is_token(TOKEN_LPAREN)){
            next_token();
        }
        
        if (!is_token(TOKEN_COMMA) || !is_token(TOKEN_SEMICOLON)) {
            init = parse_simple_stmt();
        }
        if (match_token(TOKEN_COMMA) || match_token(TOKEN_SEMICOLON)) {
            if (!is_token(TOKEN_SEMICOLON || !is_token(TOKEN_COMMA))) {
                

                if(is_token(TOKEN_NAME)){
                save_state();
                const char *name  = parse_name();
                if(match_token(TOKEN_PTR)){

                TokenKind op = TOKEN_PTR;
                cond = new_expr_unary(pos, op, new_expr_name(pos, name));
                goto next;
                } 
                restore_state();
            } 
                
                cond = parse_expr();
            
                
            }
            next:
            if (match_token(TOKEN_COMMA) || match_token(TOKEN_SEMICOLON)) {
                if (!is_token(TOKEN_LBRACE)) {
                    next = parse_simple_stmt();
                    if (next->kind == STMT_INIT) {
                        error_here("Init statements not allowed in for-statement's next clause");
                    }
                }
            }
        }

        if(is_token(TOKEN_RPAREN))
        {
            next_token();
        }
       
       // expect_token(TOKEN_LBRACE);
    }
    return new_stmt_for(pos, init, cond, next, parse_stmt_block());
}

SwitchCasePattern parse_switch_case_pattern(void) {
    Expr *start = parse_expr();
    Expr *end = NULL;
    if (match_token(TOKEN_ELLIPSIS)) {
        end = parse_expr();
    }
    return (SwitchCasePattern){start, end};
}

SwitchCase parse_stmt_switch_case(void) {
    SwitchCasePattern *patterns = NULL;
    bool is_default = false;
    bool is_first_case = true;
    while (is_keyword(case_keyword) || is_keyword(default_keyword)) {
        if (match_keyword(case_keyword)) {
            if (!is_first_case) {
                warning_here("Use comma-separated expressions to match multiple values with one case label");
                is_first_case = false;
            }
            buf_push(patterns, parse_switch_case_pattern());
            while (match_token(TOKEN_COMMA)) {
                buf_push(patterns, parse_switch_case_pattern());
            }
        } else {
            assert(is_keyword(default_keyword));
            next_token();
            if (is_default) {
                error_here("Duplicate default labels in same switch clause");
            }
            is_default = true;
        }
        expect_token(TOKEN_COLON);
    }
    SrcPos pos = token.pos;
    Stmt **stmts = NULL;
    while (!is_token_eof() && !is_token(TOKEN_RBRACE) && !is_keyword(case_keyword) && !is_keyword(default_keyword)) {
        buf_push(stmts, parse_stmt());
    }
    return (SwitchCase){patterns, buf_len(patterns), is_default, new_stmt_list(pos, stmts, buf_len(stmts))};
}

Stmt *parse_stmt_switch(SrcPos pos) {
    Expr *expr = parse_paren_expr(); 
    SwitchCase *cases = NULL;
    expect_token(TOKEN_LBRACE);
    while (!is_token_eof() && !is_token(TOKEN_RBRACE)) {
        buf_push(cases, parse_stmt_switch_case());
    }
    expect_token(TOKEN_RBRACE);
    return new_stmt_switch(pos, expr, cases, buf_len(cases));
}

Note parse_note(void);

Stmt *parse_stmt(void) {
    Notes notes = parse_notes();
    SrcPos pos = token.pos;
    Stmt *stmt = NULL;
    if (match_keyword(if_keyword)) {
        stmt = parse_stmt_if(pos);
    } else if (match_keyword(while_keyword)) {
        stmt = parse_stmt_while(pos);
    } else if (match_keyword(do_keyword)) {
        stmt = parse_stmt_do_while(pos);
    } else if (match_keyword(for_keyword)) {

        is_block_stmt = true;
        stmt = parse_stmt_for(pos);
    } else if (match_keyword(switch_keyword)) {
        stmt = parse_stmt_switch(pos);
    } else if (is_token(TOKEN_LBRACE)) {
        stmt = new_stmt_block(pos, parse_stmt_block());
    } else if (match_keyword(break_keyword)) {
        optional_token(TOKEN_SEMICOLON);
        //expect_token(TOKEN_SEMICOLON);
        stmt = new_stmt_break(pos);
    } else if (match_keyword(continue_keyword)) {
        optional_token(TOKEN_SEMICOLON);
        //expect_token(TOKEN_SEMICOLON);
        stmt = new_stmt_continue(pos);
    } else if (match_keyword(return_keyword)) {
        Expr *expr = NULL;
       // is_array = false;
        if (!is_token(TOKEN_SEMICOLON)) {
            expr = parse_expr();
            /*if(is_array)
            {

                printf("Hell uyeah;");
            }*/
        //expect_token(TOKEN_SEMICOLON);
        stmt = new_stmt_return(pos, expr);
        optional_token(TOKEN_SEMICOLON);
    } else {
        
        expect_token(TOKEN_SEMICOLON);
        stmt = new_stmt_null_return(pos, NULL);


    }

    } else if (match_token(TOKEN_POUND)) {
        Note note = parse_note();
        optional_token(TOKEN_SEMICOLON);
        //expect_token(TOKEN_SEMICOLON);
        stmt = new_stmt_note(pos, note);
    } else if (match_token(TOKEN_COLON)) {
    
        stmt = new_stmt_label(pos, parse_name());
    } else if (match_keyword(goto_keyword)) {
        stmt = new_stmt_goto(pos, parse_name());
        optional_token(TOKEN_SEMICOLON);
        //expect_token(TOKEN_SEMICOLON);
    } else {
        stmt = parse_simple_stmt();
        optional_token(TOKEN_SEMICOLON);
        //expect_token(TOKEN_SEMICOLON);
    }
    stmt->notes = notes;
    return stmt;
}

const char *parse_name(void) {
    const char *name = token.name;

    expect_token(TOKEN_NAME);
    return name;
}

EnumItem parse_decl_enum_item(void) {
    SrcPos pos = token.pos;
    const char *name = parse_name();
    Expr *init = NULL;
    if (match_token(TOKEN_ASSIGN)) {
        init = parse_expr();
    }
    return (EnumItem){pos, name, init};
}

Decl *parse_decl_enum(const char * Name, SrcPos pos) {
    const char *name = NULL;
    if (is_token(TOKEN_NAME)) {
        
        name = parse_name();
    }

    name = Name;
    Typespec *type = NULL;
    if (match_token(TOKEN_ASSIGN)) {
        type = parse_type();
    }
    expect_token(TOKEN_LBRACE);
    EnumItem *items = NULL;
    while (!is_token(TOKEN_RBRACE)) {
        buf_push(items, parse_decl_enum_item());
        if (!match_token(TOKEN_COMMA)) {
            break;
        }
    }
    expect_token(TOKEN_RBRACE);
    return new_decl_enum(pos, name, type, items, buf_len(items));
}

Aggregate *parse_aggregate(AggregateKind kind);
//bool is_p_struct;
AggregateItem parse_decl_aggregate_item(void) {

begin:
      SrcPos pos = token.pos;

        const char **names = NULL;
        const char *name = token.name;
  
      if (match_keyword(union_keyword) || match_keyword(struct_keyword)) {
        return (AggregateItem){
            .pos = pos,
            .kind = AGGREGATE_ITEM_SUBAGGREGATE,
            .subaggregate = parse_aggregate(AGGREGATE_UNION),
        };
    }

    if(match_keyword(anonymousstruct_keyword)){

         return (AggregateItem){
            .pos = pos,
            .kind = AGGREGATE_ITEM_SUBAGGREGATE,
            .subaggregate = parse_aggregate(AGGREGATE_STRUCT),
        };
    }

        buf_push(names, parse_name());


        while (match_token(TOKEN_COMMA) ) {

            buf_push(names, parse_name());

        }

        if(is_token(TOKEN_COLON))
        {

            next_token();
        }

 if(match_keyword(struct_keyword)){

Typespec *type = p_get_type(name, pos);


          return (AggregateItem) {
            .pos = pos,
            .kind = AGGREGATE_ITEM_FIELD,
            .names = names,
            .num_names = buf_len(names),
            .internal_struct = parse_decl_struct(name, pos, DECL_STRUCT),
            .type = type,
            .is_internal_struct = true,
          
                };
            
        }

    else{

    Typespec *type = parse_type();
    optional_token(TOKEN_SEMICOLON);
         return (AggregateItem){
            .pos = pos,
            .kind = AGGREGATE_ITEM_FIELD,
            .names = names,
            .num_names = buf_len(names),
            .type = type,
          
            };

        }

}

Aggregate *parse_aggregate(AggregateKind kind) {
    SrcPos pos = token.pos;

    if(!is_token(TOKEN_LBRACE)){

         AggregateItem *items = NULL;

          while (!is_token_eof()) {


         buf_push(items, parse_decl_aggregate_item());
            

        }

        return new_aggregate(pos, kind, items, buf_len(items));

    } else {

        expect_token(TOKEN_LBRACE);

    AggregateItem *items = NULL;
    while (!is_token_eof() && !is_token(TOKEN_RBRACE)) {

        buf_push(items, parse_decl_aggregate_item());

    }

    expect_token(TOKEN_RBRACE);
    
    return new_aggregate(pos, kind, items, buf_len(items));
    }

    fatal_error_here("Parse struct fail\n");
}

Aggregate *parse_ion_aggregate(AggregateKind kind);

AggregateItem parse_decl_ion_aggregate_item(void) {
    SrcPos pos = token.pos;
    if (match_keyword(struct_keyword)) {
        return (AggregateItem){
            .pos = pos,
            .kind = AGGREGATE_ITEM_SUBAGGREGATE,
            .subaggregate = parse_ion_aggregate(AGGREGATE_STRUCT),
        };
    } else if (match_keyword(union_keyword)) {
        return (AggregateItem){
            .pos = pos,
            .kind = AGGREGATE_ITEM_SUBAGGREGATE,
            .subaggregate = parse_ion_aggregate(AGGREGATE_UNION),
        };
    } else {
        const char **names = NULL;
        buf_push(names, parse_name());
        while (match_token(TOKEN_COMMA)) {
            buf_push(names, parse_name());
        }
        expect_token(TOKEN_COLON);
        Typespec *type = parse_ion_type();
        expect_token(TOKEN_SEMICOLON);
        return (AggregateItem){
            .pos = pos,
            .kind = AGGREGATE_ITEM_FIELD,
            .names = names,
            .num_names = buf_len(names),
            .type = type,
        };
    }
}

Aggregate *parse_ion_aggregate(AggregateKind kind) {
    SrcPos pos = token.pos;
    expect_token(TOKEN_LBRACE);
    AggregateItem *items = NULL;
    while (!is_token_eof() && !is_token(TOKEN_RBRACE)) {
        buf_push(items, parse_decl_ion_aggregate_item());
    }
    expect_token(TOKEN_RBRACE);
    return new_aggregate(pos, kind, items, buf_len(items));
}

Decl *parse_decl_ion_aggregate(SrcPos pos, DeclKind kind) {
    assert(kind == DECL_STRUCT || kind == DECL_UNION);
    const char *name = parse_name();
    AggregateKind aggregate_kind = kind == DECL_STRUCT ? AGGREGATE_STRUCT : AGGREGATE_UNION;
    if (match_token(TOKEN_SEMICOLON)) {
        Decl *decl = new_decl_aggregate(pos, kind, name, new_aggregate(pos, aggregate_kind, NULL, 0));
        decl->is_incomplete = true;
        return decl;
    } else {
        return new_decl_aggregate(pos, kind, name, parse_ion_aggregate(aggregate_kind));
    }
}





Decl *parse_decl_aggregate(SrcPos pos, DeclKind kind) {
    assert(kind == DECL_STRUCT || kind == DECL_UNION);
    const char *name = parse_name();
    AggregateKind aggregate_kind = kind == DECL_STRUCT ? AGGREGATE_STRUCT : AGGREGATE_UNION;
    if (match_token(TOKEN_SEMICOLON)) {
        Decl *decl = new_decl_aggregate(pos, kind, name, new_aggregate(pos, aggregate_kind, NULL, 0));
        decl->is_incomplete = true;
        return decl;
    } else {
        return new_decl_aggregate(pos, kind, name, parse_aggregate(aggregate_kind));
    }
}

Decl *parse_decl_struct(const char *name, SrcPos pos, DeclKind kind) {
    assert(kind == DECL_STRUCT || kind == DECL_UNION);

    //const char *name = parse_name();
    AggregateKind aggregate_kind = kind == DECL_STRUCT ? AGGREGATE_STRUCT : AGGREGATE_UNION;
    if (match_token(TOKEN_SEMICOLON)) {
        Decl *decl = new_decl_aggregate(pos, kind, name, new_aggregate(pos, aggregate_kind, NULL, 0));
        decl->is_incomplete = true;
        return decl;
    } else {
        return new_decl_aggregate(pos, kind, name, parse_aggregate(aggregate_kind));
    }
}

Decl *parse_decl_var(SrcPos pos) {
    const char *name = parse_name();
    if (match_token(TOKEN_ASSIGN)) {
        Expr *expr = parse_expr();
      optional_token(TOKEN_SEMICOLON);
        return new_decl_var(pos, name, NULL, expr);
    } else if (match_token(TOKEN_COLON)) {
        Typespec *type = parse_type();
        Expr *expr = NULL;
        if (match_token(TOKEN_ASSIGN)) {
            expr = parse_expr();
        }
        optional_token(TOKEN_SEMICOLON);
       
        return new_decl_var(pos, name, type, expr);
    } else {
        fatal_error_here("Expected : or = after var, got %s", token_info());
        return NULL;
    }
}

Decl *parse_decl_const(SrcPos pos) {
    const char *name = parse_name();
    Typespec *type = NULL;
    if (match_token(TOKEN_COLON)) {
        type = parse_type();
    }
    expect_token(TOKEN_ASSIGN);
    Expr *expr = parse_expr();
    optional_token(TOKEN_SEMICOLON);
    //expect_token(TOKEN_SEMICOLON);
    return new_decl_const(pos, name, type, expr);
}

Typespec *parse_type_ion_base(void) {
    if (is_token(TOKEN_NAME)) {
        SrcPos pos = token.pos;
        const char **names = NULL;
        buf_push(names, token.name);
        next_token();
        while (match_token(TOKEN_DOT)) {
            buf_push(names, parse_name());
        }
        return new_typespec_name(pos, names, buf_len(names));
    } else if (match_keyword(func_keyword)) {
        return parse_type_func();
    } else if (match_token(TOKEN_LPAREN)) {
        Typespec *type = parse_type();
        expect_token(TOKEN_RPAREN);
        return type;
    } else if (match_token(TOKEN_LBRACE)) {
        return parse_type_tuple();
    } else {
        fatal_error_here("Unexpected token %s in type", token_info());
        return NULL;
    }
}

Typespec *parse_ion_type(void) {
    //printf("Huh?\n");
    Typespec *type = parse_type_ion_base();
    SrcPos pos = token.pos;
    while (is_token(TOKEN_LBRACKET) || is_token(TOKEN_MUL) || is_keyword(const_keyword)) {
        if (match_token(TOKEN_LBRACKET)) {
            Expr *size = NULL;
            if (!is_token(TOKEN_RBRACKET)) {
                size = parse_expr();
            }
            expect_token(TOKEN_RBRACKET);
            type = new_typespec_array(pos, type, size);
        } else if (match_keyword(const_keyword)) {
            type = new_typespec_const(pos, type);
        } else {
            assert(is_token(TOKEN_MUL));
            next_token();
            type = new_typespec_ptr(pos, type);
        }
    }
    return type;


}

Decl *parse_decl_typedef(SrcPos pos) {
    const char *name = parse_name();
    expect_token(TOKEN_ASSIGN);
    Typespec *type = parse_ion_type();
    optional_token(TOKEN_SEMICOLON);
    //expect_token(TOKEN_SEMICOLON);
    return new_decl_typedef(pos, name, type);
}

FuncParam parse_decl_func_param(void) {
    SrcPos pos = token.pos;
    const char *name = parse_name();
    expect_token(TOKEN_COLON);
    Typespec *type = parse_type();
    return (FuncParam){pos, name, type};
}

FuncParam parse_decl_func_param_no_colon(void) {
    SrcPos pos = token.pos;
    const char *name = parse_name();
   // expect_token(TOKEN_COLON);
    Typespec *type = parse_type();
    return (FuncParam){pos, name, type};
}

Decl *parse_decl_func(SrcPos pos) {
    const char *name = parse_name();
    expect_token(TOKEN_LPAREN);
    FuncParam *params = NULL;
    bool has_varargs = false;
    Typespec *varargs_type = NULL;
    if (!is_token(TOKEN_RPAREN)) {
        buf_push(params, parse_decl_func_param());
        while (match_token(TOKEN_COMMA)) {
            if (match_token(TOKEN_ELLIPSIS)) {
                if (has_varargs) {
                    error_here("Multiple ellipsis in function declaration");
                }
                if (!is_token(TOKEN_RPAREN)) {
                    varargs_type = parse_type();
                }
                has_varargs = true;
            } else {
                if (has_varargs) {
                    error_here("Ellipsis must be last parameter in function declaration");
                }
                buf_push(params, parse_decl_func_param());
            }
        }
    }
    expect_token(TOKEN_RPAREN);
    Typespec *ret_type = NULL;
    if (match_token(TOKEN_COLON)) {
        ret_type = parse_type();
    }
    StmtList block = {0};
    bool is_incomplete;
    if (match_token(TOKEN_SEMICOLON)) {
        is_incomplete = true;
    } else {
        block = parse_stmt_block();
        is_incomplete = false;
    }
    Decl *decl = new_decl_func(pos, name, params, buf_len(params), ret_type, has_varargs, varargs_type, block);
    decl->is_incomplete = is_incomplete;
    return decl;
}

NoteArg parse_note_arg(void) {
    SrcPos pos = token.pos;
    Expr *expr = parse_expr();
    const char *name = NULL;
    if (match_token(TOKEN_ASSIGN)) {
        if (expr->kind != EXPR_NAME) {
            fatal_error_here("Left operand of = in note argument must be a name");
        }
        name = expr->name;
        expr = parse_expr();
    }
    return (NoteArg){.pos = pos, .name = name, .expr = expr};
}

Note parse_note(void) {
    SrcPos pos = token.pos;
    const char *name = parse_name();
    NoteArg *args = NULL;
    if (match_token(TOKEN_LPAREN)) {
        buf_push(args, parse_note_arg());
        while (match_token(TOKEN_COMMA)) {
            buf_push(args, parse_note_arg());
        }
        expect_token(TOKEN_RPAREN);
    }
    return new_note(pos, name, args, buf_len(args));
}

Notes parse_notes(void) {
    Note *notes = NULL;
    while (match_token(TOKEN_AT)) {
        buf_push(notes, parse_note());
    }
    return new_notes(notes, buf_len(notes));
}

Decl *parse_decl_note(SrcPos pos) {
    return new_decl_note(pos, parse_note());
}

Decl *parse_decl_import(SrcPos pos) {
    const char *rename_name = NULL;
    bool is_relative;
    repeat:
    is_relative = false;
    if (match_token(TOKEN_DOT)) {
        is_relative = true;
    }
    const char *name = token.name;
    expect_token(TOKEN_NAME);
    if (!is_relative && match_token(TOKEN_ASSIGN)) {
        if (rename_name) {
            fatal_error(pos, "Only one import assignment is allowed");
        }
        rename_name = name;
        goto repeat;
    }
    const char **names = NULL;
    buf_push(names, name);
    while (match_token(TOKEN_DOT)) {
        buf_push(names, token.name);
        expect_token(TOKEN_NAME);
    }
    bool import_all = false;
    ImportItem *items = NULL;
    if (match_token(TOKEN_LBRACE)) {
        while (!is_token(TOKEN_RBRACE)) {
            if (match_token(TOKEN_ELLIPSIS)) {
                import_all = true;
            } else {
                const char *name = parse_name();
                if (match_token(TOKEN_ASSIGN)) {
                    buf_push(items, (ImportItem){.name = parse_name(), .rename = name});
                } else {
                    buf_push(items, (ImportItem){.name = name});
                }
                if (!match_token(TOKEN_COMMA)) {
                    break;
                }
            }
        }
        expect_token(TOKEN_RBRACE);
    }
    return new_decl_import(pos, rename_name, is_relative, names, buf_len(names), import_all, items, buf_len(items));
}


EnumItem parse_decl_ion_enum_item(void) {
    SrcPos pos = token.pos;
    const char *name = parse_name();
    Expr *init = NULL;
    if (match_token(TOKEN_ASSIGN)) {
        init = parse_expr();
    }
    return (EnumItem){pos, name, init};
}

Decl *parse_decl_ion_enum(SrcPos pos) {
    const char *name = NULL;
    if (is_token(TOKEN_NAME)) {
        name = parse_name();
    }
    Typespec *type = NULL;
    if (match_token(TOKEN_ASSIGN)) {
        type = parse_type();
    }
    expect_token(TOKEN_LBRACE);
    EnumItem *items = NULL;
    while (!is_token(TOKEN_RBRACE)) {
        buf_push(items, parse_decl_ion_enum_item());
        if (!match_token(TOKEN_COMMA)) {
            break;
        }
    }
    expect_token(TOKEN_RBRACE);
    return new_decl_enum(pos, name, type, items, buf_len(items));
}

PP_StmtList parse_pp_block(SrcPos pos)
{

}

Decl *parse_decl_define(SrcPos pos)
{
    
    if(match_keyword(ifndef_keyword))
    {
        const char *name = parse_name();
        printf("%s\n", name);


        PP_StmtList block;
        while(!match_keyword(pp_endif_keyword))
        {

            block = parse_pp_block(pos);
        }

       /// return new_decl_pp(); 
    } else if(match_keyword(define_keyword)){
        printf("defined");

    } else if(match_keyword(elif_defined_keyword)){


    } else if (match_keyword(pp_else_keyword)){

    } 
    else if(match_keyword(pp_error_keyword)){


    } else if(match_keyword(pp_endif_keyword)){

    } 
    return NULL;
}

Decl *do_block(SrcPos pos, const char *name, FuncParam *params, Typespec *ret_type, bool has_varargs, Typespec *varargs_type){

  is_p_func = true;
        StmtList block = {0};
        bool is_incomplete;
        if (match_token(TOKEN_SEMICOLON)) {
            is_incomplete = true;
        } else {

            if(!is_token(TOKEN_LBRACE)){

            block = parse_stmt_block_no_brace();

            } else {

                 block = parse_stmt_block();
            }
            is_incomplete = false;

        }

        Decl *decl = new_decl_func(pos, name, params, buf_len(params), ret_type, has_varargs, varargs_type, block);

        decl->is_incomplete = is_incomplete;
        return decl;
}

Decl * parse_pc_func(SrcPos pos, const char *name)
{

    expect_token(TOKEN_LPAREN);
        FuncParam *params = NULL;
        bool has_varargs = false;
        Typespec *varargs_type = NULL;
        if (!is_token(TOKEN_RPAREN)) {
            buf_push(params, parse_decl_func_param_no_colon());
            while (match_token(TOKEN_COMMA)) {
                if (match_token(TOKEN_ELLIPSIS)) {
                    if (has_varargs) {
                        error_here("Multiple ellipsis in function declaration");
                    }
                    if (!is_token(TOKEN_RPAREN)) {
                        varargs_type = parse_type();
                    }
                    has_varargs = true;
                } else {
                    if (has_varargs) {
                        error_here("Ellipsis must be last parameter in function declaration");
                    }
                    buf_push(params, parse_decl_func_param_no_colon());
                }
            }
        }

        expect_token(TOKEN_RPAREN);
        Typespec *ret_type = NULL;
      bool is_ret_type = false;

 if(match_token(TOKEN_RET) ||is_token(TOKEN_PTR) || is_token(TOKEN_LBRACKET) ) {

ret_type = parse_type();
return do_block(pos, name, params, ret_type, has_varargs, varargs_type);
}


if(is_token(TOKEN_NAME)) {

    save_state();

    expect_token(TOKEN_NAME);

if(is_token(TOKEN_PTR)) {

    expect_token(TOKEN_PTR);

    expect_token(TOKEN_NAME);
    if(is_token(TOKEN_ASSIGN)) {

        restore_state();
        return do_block(pos, name, params, ret_type, has_varargs, varargs_type);
    }

}

if(is_token(TOKEN_LBRACKET)) {

    restore_state();
    return do_block(pos, name, params, ret_type, has_varargs, varargs_type);

}

    restore_state();
    ret_type = parse_type();
    
}
      
    return do_block(pos, name, params, ret_type, has_varargs, varargs_type);
}

Decl *parse_decl_opt(void) {
    SrcPos pos = token.pos;
    is_p_func = false;
//    is_p_struct = false;
    bool do_parse_type = true;
    if (match_keyword(enum_keyword)) {
       return parse_decl_ion_enum(pos);
    } else if (match_keyword(struct_keyword)) {
        return parse_decl_ion_aggregate(pos, DECL_STRUCT);
    } else if (match_keyword(union_keyword)) {
        return parse_decl_aggregate(pos, DECL_UNION);
    } else if (match_keyword(const_keyword)) {
        return parse_decl_const(pos);
    } else if (match_keyword(typedef_keyword)) {
        return parse_decl_typedef(pos);
    } else if (match_keyword(func_keyword)) {
        return parse_decl_func(pos);
    } else if (match_keyword(var_keyword)) {
        return parse_decl_var(pos);
    } else if (match_keyword(import_keyword)) {
        return parse_decl_import(pos);
    } else if (match_token(TOKEN_POUND)) {
        return parse_decl_note(pos);
    } else if(match_token(TOKEN_DOLLAR)) {

        parse_decl_define(pos);
    } else if(is_token(TOKEN_NAME)){

    const char *name = parse_name();
        
    if(match_keyword(fn_keyword) || is_token(TOKEN_LPAREN)) {
        return parse_pc_func(pos, name);            
    }
         
    if(match_token(TOKEN_ASSIGN)) {
        Expr *expr = parse_expr();
        optional_token(TOKEN_SEMICOLON);
        return new_decl_var(pos, name, NULL, expr);
    }

    optional_token(TOKEN_SEMICOLON);

    if(match_keyword(struct_keyword)) {
        SrcPos pos = token.pos;
       // is_p_struct = true;
        return parse_decl_struct(name, pos, DECL_STRUCT);
    }

    else if(match_keyword(union_keyword)) {
        SrcPos pos = token.pos;
       // is_p_struct = true;
        return parse_decl_struct(name, pos, DECL_UNION);
    }

    else if(match_keyword(enum_keyword)) {
        SrcPos pos = token.pos;
        return parse_decl_enum(name, pos);
    }

    Typespec *type = parse_type();
    Expr *expr = NULL;
    if(match_token(TOKEN_ASSIGN)) {
        expr = parse_expr();
        return new_decl_var(pos, name, type, expr);
    }

    return new_decl_var(pos, name, type, NULL);
    }
    
    return NULL;
}

Decl *parse_decl(void) {
    Notes notes = parse_notes();
    Decl *decl = parse_decl_opt();
    if (!decl) {
        fatal_error_here("Expected declaration keyword, got %s", token_info());
    }
    decl->notes = notes;

    return decl;
}

Decls *parse_decls(void) {
    Decl **decls = NULL;
    while (!is_token(TOKEN_EOF)) {
        buf_push(decls, parse_decl());
    }
    return new_decls(decls, buf_len(decls));
  
}
