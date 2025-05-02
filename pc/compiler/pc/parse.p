optional_token(kind TokenKind) {
    if(token.kind == kind) { next_token() }
}

is_block_stmt bool = false
is_p_func bool = false
is_p_struct bool 

parse_type_func_param() ^Typespec {
    type ^Typespec = parse_type()
    if (match_token(TOKEN_COLON)) {
        if (type.kind != TYPESPEC_NAME) {
            error_here(token.pos, "Colons in parameters of func types must be preceded by names.")
        }
        type = parse_type()
    }
    return type
}

parse_type_func() ^Typespec{
    pos := token.pos
    args ^^Typespec = NULL
    has_varargs bool = false
    expect_token(TOKEN_LPAREN)
    if (!is_token(TOKEN_RPAREN)) {
        buf_push(args, parse_type_func_param())
        while (match_token(TOKEN_COMMA)) {
            if (match_token(TOKEN_ELLIPSIS)) {
                if (has_varargs) {
                    error_here(pos, "Multiple ellipsis instances in function type")
                }
                has_varargs = true
            } else {
                if (has_varargs) {
                    error_here(pos, "Ellipsis must be last parameter in function type")
                }
                buf_push(args, parse_type_func_param())
            }
        }
    }
    expect_token(TOKEN_RPAREN)
    ret ^Typespec = NULL
    if (match_token(TOKEN_COLON)) {
        ret = parse_type()
    }
    return new_typespec_func(pos, args, buf_len(args), ret, has_varargs)
}

parse_type_tuple() ^Typespec {
    pos := token.pos
    fields ^^Typespec = NULL
    while (!is_token(TOKEN_RBRACE)) {
        field := parse_type()
        buf_push(fields, field)
        if (!match_token(TOKEN_COMMA)) {
            break;
        }
    }
    expect_token(TOKEN_RBRACE)
    return new_typespec_tuple(pos, fields, buf_len(fields))
}

parse_type_base() ^Typespec {
    if (is_token(TOKEN_NAME) || match_keyword(struct_keyword)) {


        pos := token.pos
        names ^^char = NULL
        buf_push(names, token.name)
        //printf("%s\n", token.name)
        next_token()
        while (match_token(TOKEN_DOT)) {

            buf_push(names, parse_name())
        }
        return new_typespec_name(pos, names, buf_len(names))
    } else if (match_keyword(func_keyword)) {
        return parse_type_func()
    } 
    
    else if (match_token(TOKEN_LPAREN)) {
        type := parse_type()
        expect_token(TOKEN_RPAREN)
        return type
    } else if (match_token(TOKEN_LBRACE)) {
        //printf("Yeah\n")
        return parse_type_tuple()
    } else {
       
        fatal_error_here(token.pos, "Unexpected token %s in type", token_info());
        return NULL
    }
}

p_get_type(name ^char, pos SrcPos) ^Typespec {
    names ^^char = NULL
    buf_push(names, name)
    return new_typespec_name(pos, names, buf_len(names))
}

temp_token Token 
start usize

save_state() {
    pc_memcpy(&temp_token, &token, sizeof(token))
    start = pc_strlen(stream)
 }

restore_state() {
    while(start != pc_strlen(stream)) {
        --stream
    }
    token  = temp_token
}

get_type() ^Typespec {
    save_state()

    while(is_token(TOKEN_PTR))
        {
            #assert(is_token(TOKEN_PTR))
            next_token()
        }

         if(match_token(TOKEN_LBRACKET))
        {
            if (!is_token(TOKEN_RBRACKET)) {
                size ^Expr = parse_expr()
            }

            expect_token(TOKEN_RBRACKET)

        }
      
    type := parse_type_base()

    restore_state()

    return type
}


parse_type() ^Typespec{

    pos := token.pos
    p_type ^Typespec = NULL
    if(is_token(TOKEN_COLON)){
    next_token()
    }

    if(match_token(TOKEN_LBRACKET)){
            size ^Expr = NULL
            if (!is_token(TOKEN_RBRACKET)) {
                size = parse_expr()
            }

            expect_token(TOKEN_RBRACKET)

            p_type = parse_type_base()
            p_type = new_typespec_array(pos, p_type, size)
            return p_type
    }

        p_type = get_type()
           
        if(is_token(TOKEN_PTR)){
        while(is_token(TOKEN_PTR))
        {
            #assert(is_token(TOKEN_PTR))
            next_token()
            p_type = new_typespec_ptr(pos, p_type)

        }

        if(match_token(TOKEN_LBRACKET))
        {
            size ^Expr = NULL
            if (!is_token(TOKEN_RBRACKET)) {
                size = parse_expr()
            }

            expect_token(TOKEN_RBRACKET)

            p_type = new_typespec_array(pos, p_type, size)
        }

        next_token()

        return p_type
    }


    type := parse_type_base()
   while (is_token(TOKEN_LBRACKET) || is_token(TOKEN_MUL)) {
        if match_token(TOKEN_LBRACKET) {
            size ^Expr = NULL
            if !is_token(TOKEN_RBRACKET) {
                size = parse_expr()
            }
             expect_token(TOKEN_RBRACKET);
            type = new_typespec_array(pos, type, size);
        } else if (match_keyword(const_keyword)) {
            type = new_typespec_const(pos, type);
        } else {
            #assert(is_token(TOKEN_MUL));
            next_token();
            type = new_typespec_ptr(pos, type);
        }
    }
        
    return type
}

parse_expr_compound_field() CompoundField {
    pos := token.pos
    if (match_token(TOKEN_LBRACKET)) {
        index := parse_expr()
        expect_token(TOKEN_RBRACKET)
        expect_token(TOKEN_ASSIGN)
        return (:CompoundField){FIELD_INDEX, pos, parse_expr(), index = index}
    } else {
        expr := parse_expr()
        if (match_token(TOKEN_ASSIGN)) {
            if (expr.kind != EXPR_NAME) {
                fatal_error_here(token.pos, "Named initializer in compound literal must be preceded by field name")
            }
            return (:CompoundField){FIELD_NAME, pos, parse_expr(), name = expr.name}
        } else {
            return (:CompoundField){FIELD_DEFAULT, pos, expr}
        }
    }
}

parse_expr_compound(type  ^Typespec) ^Expr {
    pos := token.pos
    expect_token(TOKEN_LBRACE)
    fields ^CompoundField = NULL
    while (!is_token(TOKEN_RBRACE)) {
            buf_push(fields, parse_expr_compound_field())
             if (!match_token(TOKEN_COMMA)) {
            break;
        }
        
    }
    expect_token(TOKEN_RBRACE)
    return expr_compound(pos, type, fields, buf_len(fields))
   
}

parse_expr_new(pos SrcPos) ^Expr {
    alloc ^Expr = NULL
    if (match_token(TOKEN_LPAREN)) {
        alloc = parse_expr()
        expect_token(TOKEN_RPAREN)
    }
    len ^Expr = NULL
    if (match_token(TOKEN_LBRACKET)) {
        len = parse_expr()
        expect_token(TOKEN_RBRACKET)
    }
    arg ^Expr = NULL
    if (!match_keyword(undef_keyword)) {
        arg = parse_expr()
    }
    return new_expr_new(pos, alloc, len, arg)
}

parse_expr_operand() ^Expr {
    pos := token.pos
    if (is_token(TOKEN_INT)) {
        val ullong = token.int_val
        mod := token.mod
        suffix := token.suffix
        next_token()
        return new_expr_int(pos, val, mod, suffix)
    } else if (is_token(TOKEN_FLOAT)) {
        start := token.start
        end := token.end
        val := token.float_val
        suffix := token.suffix
        next_token()
        return new_expr_float(pos, start, end, val, suffix)
    } else if (is_token(TOKEN_STR)) {
        val := token.str_val
        mod := token.mod
        next_token()
        return new_expr_str(pos, val, mod)
    } else if (is_token(TOKEN_NAME)) {
        name := token.name
        next_token()
        if (is_token(TOKEN_LBRACE)) {
            return parse_expr_compound(new_typespec_name(pos, &name, 1))
        } else {
            
            return new_expr_name(pos, name)
        }
    } else if (match_keyword(new_keyword)) {
        return parse_expr_new(pos)
    } else if (match_keyword(sizeof_keyword)) {
        expect_token(TOKEN_LPAREN)
        if (match_token(TOKEN_COLON)) {
            type := parse_type()
            expect_token(TOKEN_RPAREN);
            return new_expr_sizeof_type(pos, type)
        } else {
            expr := parse_expr()
            expect_token(TOKEN_RPAREN)
            return new_expr_sizeof_expr(pos, expr)
        }
    } else if (match_keyword(alignof_keyword)) {
        expect_token(TOKEN_LPAREN)
        if (match_token(TOKEN_COLON)) {
            type := parse_type()
            expect_token(TOKEN_RPAREN)
            return new_expr_alignof_type(pos, type)
        } else {
            expr := parse_expr()
            expect_token(TOKEN_RPAREN)
            return new_expr_alignof_expr(pos, expr)
        }
    } else if (match_keyword(typeof_keyword)) {
        expect_token(TOKEN_LPAREN)
        if (match_token(TOKEN_COLON)) {
            type := parse_type()
            expect_token(TOKEN_RPAREN)
            return new_expr_typeof_type(pos, type)
        } else {
            expr := parse_expr()
            expect_token(TOKEN_RPAREN)
            return new_expr_typeof_expr(pos, expr)
        }
    } else if (match_keyword(offsetof_keyword)) {
        expect_token(TOKEN_LPAREN)
        type := parse_type()
        expect_token(TOKEN_COMMA)
        name := parse_name()
        expect_token(TOKEN_RPAREN)
        return new_expr_offsetof(pos, type, name)
    } else if (is_token(TOKEN_LBRACE)) {
        return parse_expr_compound(NULL)
    } else if (match_token(TOKEN_LPAREN)) {
        if (match_token(TOKEN_COLON)) {
            type := parse_type()
            expect_token(TOKEN_RPAREN)
            if (is_token(TOKEN_LBRACE)) {
                return parse_expr_compound(type)
            } else {
                expr :=  new_expr_cast(pos, type, parse_expr_unary())
                return expr
            }
        } else {
            expr := parse_expr()
            expect_token(TOKEN_RPAREN)
            return new_expr_paren(pos, expr)
        }
    } 
     
    else {
        printf("Error: %s\n", token.name)
      fatal_error_here(pos, "Unexpected token %s in expression", token_info())
        
        return NULL
    }
}

parse_expr_base() ^Expr {
    expr : ^Expr =  parse_expr_operand();

    while (is_token(TOKEN_LPAREN) || is_token(TOKEN_LBRACKET) || is_token(TOKEN_DOT) || is_token(TOKEN_INC) || is_token(TOKEN_DEC)) {
        pos := token.pos
        if (match_token(TOKEN_LPAREN)) {
            args ^^Expr = NULL
            if (!is_token(TOKEN_RPAREN)) {
                buf_push(args, parse_expr())
                while (match_token(TOKEN_COMMA)) {
                    buf_push(args, parse_expr())
                }
            }
            expect_token(TOKEN_RPAREN)
            expr = new_expr_call(pos, expr, args, buf_len(args))
            //  optional_token(TOKEN_SEMICOLON)
        } 

        else if (match_token(TOKEN_LBRACKET)) {
            
            //printf("Index\n");
           // if(is_token(TOKEN_NAME) || is_token(TOKEN_INT)){
            index := parse_expr();
        //}
            expect_token(TOKEN_RBRACKET);
            expr = new_expr_index(pos, expr, index);
        } else if (is_token(TOKEN_DOT)) {
            next_token();
            field := token.name;
            expect_token(TOKEN_NAME);
            expr = new_expr_field(pos, expr, field);
        } else {
            #assert(is_token(TOKEN_INC) || is_token(TOKEN_DEC));
            op := token.kind;
            next_token();
            expr = new_expr_modify(pos, op, true, expr);
        }
    }
    return expr;
}

is_unary_op() bool {
  return 
  is_token(TOKEN_ADD) ||
    is_token(TOKEN_SUB) ||
    is_token(TOKEN_MUL) ||
    is_token(TOKEN_AND) ||
    is_token(TOKEN_NEG) ||
    is_token(TOKEN_NOT) ||
    is_token(TOKEN_INC) ||
    is_token(TOKEN_DEC)
}

parse_expr_unary() ^Expr {
    if (is_unary_op()) {

       // printf("Hi\n")
        pos := token.pos;
        op := token.kind;
        next_token();
        if (op == TOKEN_INC || op == TOKEN_DEC) {
            return new_expr_modify(pos, op, false, parse_expr_unary());
        } else {
            expr := parse_expr_unary();
            return new_expr_unary(pos, op, expr);
        }
    } else {
       return parse_expr_base();
    }
}

 is_mul_op() bool {
    return TOKEN_FIRST_MUL <= token.kind && token.kind <= TOKEN_LAST_MUL
}

parse_expr_mul() ^Expr {
    expr := parse_expr_unary()
    while is_mul_op() {
        pos := token.pos
        op := token.kind
        next_token()
        expr = new_expr_binary(pos, op, expr, parse_expr_unary())
    }
    return expr
}

is_add_op() bool {
    return TOKEN_FIRST_ADD <= token.kind && token.kind <= TOKEN_LAST_ADD
}

parse_expr_add() ^Expr {
    expr := parse_expr_mul()
    if(is_block_stmt && is_token(TOKEN_PTR)){
return expr;
}
    while is_add_op() {
        pos := token.pos
        op := token.kind
        next_token()
        expr = new_expr_binary(pos, op, expr, parse_expr_mul())
    }
    return expr
}

is_cmp_op() bool {
    return TOKEN_FIRST_CMP <= token.kind && token.kind <= TOKEN_LAST_CMP
}

parse_expr_cmp() ^Expr {
    expr := parse_expr_add()
    while (is_cmp_op()) {
        pos := token.pos
        op := token.kind
        next_token()
        expr = new_expr_binary(pos, op, expr, parse_expr_add())
    }
    return expr
}

parse_expr_and() ^Expr {
    expr := parse_expr_cmp()
    while match_token(TOKEN_AND_AND) {
        pos := token.pos
        expr = new_expr_binary(pos, TOKEN_AND_AND, expr, parse_expr_cmp())
    }
    return expr
}

parse_expr_or() ^Expr {
    expr := parse_expr_and()
    while match_token(TOKEN_OR_OR) {
        pos := token.pos
        expr = new_expr_binary(pos, TOKEN_OR_OR, expr, parse_expr_and())
    }
    return expr
}

parse_expr_ternary() ^Expr {
    pos := token.pos
    expr := parse_expr_or()
    if (match_token(TOKEN_QUESTION)) {
        then_expr := parse_expr_ternary()
        expect_token(TOKEN_COLON)
        else_expr := parse_expr_ternary()
        expr = expr_ternary(pos, expr, then_expr, else_expr)
    }
    return expr
}

parse_expr() ^Expr {
    return parse_expr_ternary()
}

parse_paren_expr() ^Expr {
    expect_token(TOKEN_LPAREN)
    expr := parse_expr()
    expect_token(TOKEN_RPAREN)
    return expr
}

parse_stmt_block_no_brace() StmtList { 
    pos := token.pos
    stmts ^^Stmt = NULL

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


        buf_push(stmts, parse_stmt())
    
    }

    return new_stmt_list(pos, stmts, buf_len(stmts))

   }

parse_stmt_block() StmtList {
    pos := token.pos
    expect_token(TOKEN_LBRACE)
    stmts :^^Stmt = NULL
    while (!is_token_eof() && !is_token(TOKEN_RBRACE)) {
        buf_push(stmts, parse_stmt())
    }
    expect_token(TOKEN_RBRACE)
    return new_stmt_list(pos, stmts, buf_len(stmts))
}

parse_stmt_if(pos SrcPos) ^Stmt  {
  optional_token(TOKEN_LPAREN)
    cond := parse_expr()
    init := parse_init_stmt(cond)

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
    then_block := parse_stmt_block();
    else_block StmtList;
    elseifs ^ElseIf = NULL;
    while (match_keyword(else_keyword)) {
        if (!match_keyword(if_keyword)) {
            else_block = parse_stmt_block();
            break;
        }
        elseif_cond := parse_expr();//parse_paren_expr();
        elseif_block := parse_stmt_block();
        buf_push(elseifs, (:ElseIf){elseif_cond, elseif_block});
    }
    return new_stmt_if(pos, init, cond, then_block, elseifs, buf_len(elseifs), else_block);
}

parse_stmt_while(pos SrcPos) ^Stmt {
    cond := parse_expr()
    return new_stmt_while(pos, cond, parse_stmt_block())
}

parse_stmt_do_while(pos SrcPos) ^Stmt {
    block := parse_stmt_block()
    if !match_keyword(while_keyword) {
        fatal_error_here(token.pos, "Expected 'while' after 'do' block")
        return NULL
    }
    stmt := stmt_do_while(pos, parse_paren_expr(), block)
    optional_token(TOKEN_SEMICOLON)
    return stmt
}

 is_assign_op() bool {
    return TOKEN_FIRST_ASSIGN <= token.kind && token.kind <= TOKEN_LAST_ASSIGN
}


parse_init_stmt(left ^Expr) ^Stmt {
     if (match_token(TOKEN_COLON_ASSIGN)) {
        if (left.kind != EXPR_NAME) {
            fatal_error_here(token.pos, ":= must be preceded by a name")
            return NULL
        }
        return new_stmt_init(left.pos, left.name, NULL, parse_expr(), false)
    } else if (match_token(TOKEN_COLON)) {

        
        if (left.kind != EXPR_NAME) {
            fatal_error_here(token.pos, ": must be preceded by a name")
            return NULL
        }
        name := left.name
        type := parse_type()
        expr ^Expr = NULL
        is_undef := false
        if (match_token(TOKEN_ASSIGN)) {
            is_undef = match_keyword(undef_keyword)
            if (!is_undef) {
                expr = parse_expr()
            }
        }
        return new_stmt_init(left.pos, name, type, expr, is_undef)

    }
   return NULL
}

parse_init_stmt_no_colon(left ^Expr) ^Stmt 
{
     if (match_token(TOKEN_COLON_ASSIGN)) {
        if (left.kind != EXPR_NAME) {
            fatal_error_here(token.pos, ":= must be preceded by a name")
            return NULL
        }
        return new_stmt_init(left.pos, left.name, NULL, parse_expr(), false)
    } 

    else  {

 if (left.kind != EXPR_NAME) {
            fatal_error_here(token.pos, ": must be preceded by a name")
            return NULL
        }
        name := left.name
        type := parse_type()
        expr ^Expr = NULL
        is_undef := false
        if (match_token(TOKEN_ASSIGN)) {
            is_undef = match_keyword(undef_keyword)
            if (!is_undef) {
                expr = parse_expr()
            }
        }
        //optional_token(TOKEN_SEMICOLON);
        return new_stmt_init(left.pos, name, type, expr, is_undef)
    }
    return NULL
}
   
parse_simple_stmt() ^Stmt {
    pos := token.pos
    expr ^Expr = NULL
    if(is_token(TOKEN_NAME)) {
        //handle dererefernces
        save_state()
        name := parse_name()
        if(match_token(TOKEN_PTR)) {
            if(is_token(TOKEN_ASSIGN) || is_token(TOKEN_SEMICOLON)){
                op := TOKEN_PTR;
                expr = new_expr_unary(pos, op, new_expr_name(pos, name));
                goto pfunc
            } 
        }
            //Handle arrays/indexes
            if(is_token(TOKEN_LBRACKET)) {
                expect_token(TOKEN_LBRACKET)
                if(is_token(TOKEN_NAME) || is_token(TOKEN_INT)) {
                    index_expr := parse_expr()
                }
                expect_token(TOKEN_RBRACKET)
                if(is_token(TOKEN_NAME)) {
                    restore_state();
                    is_p_func = true;
                    expr = new_expr_name(pos, name);
                    expect_token(TOKEN_NAME);
                    goto pfunc
                }
            }
        restore_state();
    }
    expr = parse_expr();
    //if its not an array and not a dereference its p stmt (no semicolon)
    //can we have a p_parse_simple_stmt and a ion_parse_simple_stmt?
    :pfunc
    if(expr.kind == EXPR_NAME && is_p_func) {
        if (is_assign_op()) {
        op := token.kind
        next_token()
        assign_stmt := new_stmt_assign(pos, op, expr, parse_expr())
        return assign_stmt
    }
        
    no_colon_stmt := parse_init_stmt_no_colon(expr);
        if (!no_colon_stmt) {
            no_colon_stmt = new_stmt_expr(pos, expr) 
        }       
        return no_colon_stmt
    }

    stmt := parse_init_stmt(expr)
    if (!stmt) {
        if (is_assign_op()) {
            op := token.kind
            next_token()
            stmt = new_stmt_assign(pos, op, expr, parse_expr())
        } else {
            stmt = new_stmt_expr(pos, expr)
        }
    }
    return stmt
}

parse_simple_stmt_ion() ^Stmt {
    pos := token.pos
    expr := parse_expr()
    stmt := parse_init_stmt(expr)
    if (!stmt) {
        if (is_assign_op()) {
            op := token.kind
            next_token()
            stmt = new_stmt_assign(pos, op, expr, parse_expr())
        } else {
            stmt = new_stmt_expr(pos, expr)
        }
    }
    return stmt
}

parse_stmt_for(pos SrcPos) ^Stmt {
    init ^Stmt = NULL;
    cond ^Expr = NULL;
    next ^Stmt = NULL;
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
                    name := parse_name();
                    if(match_token(TOKEN_PTR)){
                        op := TOKEN_PTR;
                        cond = new_expr_unary(pos, op, new_expr_name(pos, name));
                        goto next;
                    } 
                    restore_state();
                } 
                cond = parse_expr();    
            }
            :next
            if (match_token(TOKEN_COMMA) || match_token(TOKEN_SEMICOLON)) {
                if (!is_token(TOKEN_LBRACE)) {
                    next = parse_simple_stmt();
                    if (next.kind == STMT_INIT) {
                        error_here(pos, "Init statements not allowed in for-statement's next clause");
                    }
                }
            }
        }

        optional_token(TOKEN_RPAREN)
    }
    return new_stmt_for(pos, init, cond, next, parse_stmt_block());
}

parse_switch_case_pattern() SwitchCasePattern {
    start := parse_expr();
    end ^Expr = NULL;
    if (match_token(TOKEN_ELLIPSIS)) {
        end = parse_expr();
    }
    return (:SwitchCasePattern){start, end};
}

parse_stmt_switch_case() SwitchCase{
patterns ^SwitchCasePattern = NULL;
    is_default := false;
    is_first_case := true;
    while (is_keyword(case_keyword) || is_keyword(default_keyword)) {
        if (match_keyword(case_keyword)) {
            if (!is_first_case) {
                warning_here(token.pos, "Use comma-separated expressions to match multiple values with one case label");
                is_first_case = false;
            }
            buf_push(patterns, parse_switch_case_pattern());
            while (match_token(TOKEN_COMMA)) {
                buf_push(patterns, parse_switch_case_pattern());
            }
        } else {
            #assert(is_keyword(default_keyword));
            next_token();
            if (is_default) {
                error_here(token.pos, "Duplicate default labels in same switch clause");
            }
            is_default = true;
        }
        expect_token(TOKEN_COLON);
    }
    pos := token.pos;
    stmts ^^Stmt = NULL;
    while (!is_token_eof() && !is_token(TOKEN_RBRACE) && !is_keyword(case_keyword) && !is_keyword(default_keyword)) {
        buf_push(stmts, parse_stmt());
    }
    return (:SwitchCase){patterns, buf_len(patterns), is_default, new_stmt_list(pos, stmts, buf_len(stmts))};
}

parse_stmt_switch(pos SrcPos) ^Stmt {
    expr := parse_paren_expr(); 
    cases ^SwitchCase = NULL;
    expect_token(TOKEN_LBRACE);
    while (!is_token_eof() && !is_token(TOKEN_RBRACE)) {
        buf_push(cases, parse_stmt_switch_case());
    }
    expect_token(TOKEN_RBRACE);
    return new_stmt_switch(pos, expr, cases, buf_len(cases));

}

parse_stmt() ^Stmt {
    notes := parse_notes()
    pos := token.pos
    stmt ^Stmt  = NULL
    if (match_keyword(if_keyword)) {
        stmt = parse_stmt_if(pos)
    } else if (match_keyword(while_keyword)) {
        stmt = parse_stmt_while(pos)
    } else if (match_keyword(do_keyword)) {
        stmt = parse_stmt_do_while(pos)
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
        expr ^Expr = NULL;
        if (!is_token(TOKEN_SEMICOLON)) {
            expr = parse_expr();
        stmt = new_stmt_return(pos, expr);
        optional_token(TOKEN_SEMICOLON);
    } else {
        
        expect_token(TOKEN_SEMICOLON);
        stmt = new_stmt_null_return(pos, NULL);
    }

    } else if (match_token(TOKEN_POUND)) {
        note := parse_note();
        optional_token(TOKEN_SEMICOLON);
        stmt = new_stmt_note(pos, note);
    } else if (match_token(TOKEN_COLON)) {
    
        stmt = new_stmt_label(pos, parse_name());
    } else if (match_keyword(goto_keyword)) {
        stmt = new_stmt_goto(pos, parse_name());
        optional_token(TOKEN_SEMICOLON);
    } else {
      if(is_p_func){
        stmt = parse_simple_stmt()
    } else {
        stmt = parse_simple_stmt_ion()
    }
     optional_token(TOKEN_SEMICOLON);
    
    
    }
    stmt.notes = notes;
    return stmt;
}

parse_name() ^char {
    
    name := token.name
    expect_token(TOKEN_NAME)
    return name
}

parse_decl_enum_item() EnumItem {
    pos := token.pos
    name := parse_name()
    init ^Expr = NULL
    if (match_token(TOKEN_ASSIGN)) {
        init = parse_expr()
    }
    return (:EnumItem){pos, name, init}
}

parse_decl_enum(Name ^char, pos SrcPos) ^Decl {
    name ^char = NULL
    if (is_token(TOKEN_NAME)) {
        
        name = parse_name()
    }

    name = Name
    type ^Typespec = NULL
    if (match_token(TOKEN_ASSIGN)) {
        type = parse_type()
    }
    expect_token(TOKEN_LBRACE)
    items ^EnumItem = NULL
    while (!is_token(TOKEN_RBRACE)) {
        buf_push(items, parse_decl_enum_item())
        if (!match_token(TOKEN_COMMA)) {
            break;
        }
    }
    expect_token(TOKEN_RBRACE)
    return new_decl_enum(pos, name, type, items, buf_len(items))
}

parse_decl_aggregate_item() AggregateItem {
    pos := token.pos

    names ^^char = NULL
    name := token.name
  
    if (match_keyword(union_keyword) || match_keyword(struct_keyword)) {


        return (:AggregateItem){
            pos = pos,
            kind = AGGREGATE_ITEM_SUBAGGREGATE,
            subaggregate = parse_aggregate(AGGREGATE_UNION),
        }
    
    
}

 if(match_keyword(anonymousstruct_keyword)){

         return (:AggregateItem){
            pos = pos,
            kind = AGGREGATE_ITEM_SUBAGGREGATE,
            subaggregate = parse_aggregate(AGGREGATE_STRUCT),
        };
    }
    buf_push(names, parse_name())

    while (match_token(TOKEN_COMMA)) {

        buf_push(names, parse_name())

        }

        if(is_token(TOKEN_COLON)) {
            next_token()
        }

    if(match_keyword(struct_keyword)) {

    type := p_get_type(name, pos)

    item AggregateItem
    item.pos = pos
    item.kind = AGGREGATE_ITEM_FIELD 
    item.names = names
    item.num_names = buf_len(names)
    item.internal_struct = parse_decl_struct(name,  pos, DECL_STRUCT)
    item.type = type
    item.is_internal_struct = true
    return item

    } else {

    type := parse_type()
    optional_token(TOKEN_SEMICOLON)
    
        item2 AggregateItem 
        item2.pos = pos
        item2.kind = AGGREGATE_ITEM_FIELD
        item2.names = names
        item2.num_names = buf_len(names)
        item2.type = type
        return item2

    }
}

parse_aggregate(kind AggregateKind) ^Aggregate {
    pos := token.pos

    if(!is_token(TOKEN_LBRACE)){

         items ^AggregateItem = NULL

          while (!is_token_eof()) {


         buf_push(items, parse_decl_aggregate_item())
            

        }

        return new_aggregate(pos, kind, items, buf_len(items))

    } else {

        expect_token(TOKEN_LBRACE)

    items ^AggregateItem = NULL
    while (!is_token_eof() && !is_token(TOKEN_RBRACE)) {

        buf_push(items, parse_decl_aggregate_item())

    }

    expect_token(TOKEN_RBRACE)
    
    return new_aggregate(pos, kind, items, buf_len(items))
    }

    fatal_error_here(pos, "Parse struct fail\n")
}

parse_decl_ion_aggregate_item() AggregateItem {
    pos := token.pos;
    if (match_keyword(struct_keyword)) {
        return (:AggregateItem){
            pos = pos,
            kind = AGGREGATE_ITEM_SUBAGGREGATE,
            subaggregate = parse_ion_aggregate(AGGREGATE_STRUCT),
        };
    } else if (match_keyword(union_keyword)) {
        return (:AggregateItem){
            pos = pos,
            kind = AGGREGATE_ITEM_SUBAGGREGATE,
            subaggregate = parse_ion_aggregate(AGGREGATE_UNION),
        };
    } else {
        names ^^char = NULL;
        buf_push(names, parse_name());
        while (match_token(TOKEN_COMMA)) {
            buf_push(names, parse_name());
        }
        expect_token(TOKEN_COLON);
        type := parse_ion_type();
        expect_token(TOKEN_SEMICOLON);
        item3 AggregateItem
            item3.pos = pos
            item3.kind = AGGREGATE_ITEM_FIELD
            item3.names = names
            item3.num_names = buf_len(names)
            item3.type = type

            return item3
        }

}

parse_ion_aggregate(kind AggregateKind) ^Aggregate {
    pos := token.pos;
    expect_token(TOKEN_LBRACE);
    items ^AggregateItem = NULL;
    while (!is_token_eof() && !is_token(TOKEN_RBRACE)) {
        buf_push(items, parse_decl_ion_aggregate_item());
    }
    expect_token(TOKEN_RBRACE);
    return new_aggregate(pos, kind, items, buf_len(items));
}

parse_decl_ion_aggregate(pos SrcPos, kind DeclKind) ^Decl {
  #assert(kind == DECL_STRUCT || kind == DECL_UNION);
   name := parse_name();
    aggregate_kind := (kind == DECL_STRUCT) ? AGGREGATE_STRUCT : AGGREGATE_UNION;
    if (match_token(TOKEN_SEMICOLON)) {
        decl := new_decl_aggregate(pos, kind, name, new_aggregate(pos, aggregate_kind, NULL, 0));
        decl.is_incomplete = true;
        return decl;
    } else {
        return new_decl_aggregate(pos, kind, name, parse_ion_aggregate(aggregate_kind));
    }
}

parse_decl_aggregate(pos SrcPos, kind DeclKind) ^Decl {
    #assert(kind == DECL_STRUCT || kind == DECL_UNION);
    name: ^char=  parse_name();
    aggregate_kind: AggregateKind = (kind == DECL_STRUCT) ? AGGREGATE_STRUCT : AGGREGATE_UNION;
    if (match_token(TOKEN_SEMICOLON)) {
        decl: ^Decl = new_decl_aggregate(pos, kind, name, new_aggregate(pos, aggregate_kind, NULL, 0));
        decl.is_incomplete = true;
        return decl;
    } else {
        return new_decl_aggregate(pos, kind, name, parse_aggregate(aggregate_kind));
    }
}

parse_decl_struct(name ^char, pos SrcPos, kind DeclKind) ^Decl {
    #assert(kind == DECL_STRUCT || kind == DECL_UNION);

    //const char *name = parse_name();
    aggregate_kind: AggregateKind = (kind == DECL_STRUCT) ? AGGREGATE_STRUCT : AGGREGATE_UNION;
    if (match_token(TOKEN_SEMICOLON)) {
        decl: ^Decl = new_decl_aggregate(pos, kind, name, new_aggregate(pos, aggregate_kind, NULL, 0));
        decl.is_incomplete = true;
        return decl;
    } else {
        return new_decl_aggregate(pos, kind, name, parse_aggregate(aggregate_kind));
    }
}

parse_decl_var(pos SrcPos) ^Decl {
    name := parse_name()
    if (match_token(TOKEN_ASSIGN)) {
        return new_decl_var(pos, name, NULL, parse_expr())
    } else if (match_token(TOKEN_COLON)) {
        type := parse_type()
        expr : ^Expr = NULL
        if (match_token(TOKEN_ASSIGN)) {
            expr = parse_expr()
        }
        return new_decl_var(pos, name, type, expr)
    } else {
        fatal_error_here(token.pos, "Expected : or = after var, got %s", token_info())
        return NULL
    }
}

parse_decl_const(pos SrcPos) ^Decl {
    name := parse_name()
    type ^Typespec = NULL
    if (match_token(TOKEN_COLON)) {
        type = parse_type()
    }
    expect_token(TOKEN_ASSIGN)
    expr ^Expr = parse_expr()
    optional_token(TOKEN_SEMICOLON)
    return new_decl_const(pos, name, type, expr)
}

parse_decl_typedef(pos SrcPos) ^Decl {
    name := parse_name()
    expect_token(TOKEN_ASSIGN)
    type := parse_ion_type()
    optional_token(TOKEN_SEMICOLON);
    //expect_token(TOKEN_SEMICOLON);
    return new_decl_typedef(pos, name, type)
}

parse_type_ion_base() ^Typespec {
    if (is_token(TOKEN_NAME)) {
        pos := token.pos;
        names ^^char = NULL;
        buf_push(names, token.name);
        next_token();
        while (match_token(TOKEN_DOT)) {
            buf_push(names, parse_name());
        }
        return new_typespec_name(pos, names, buf_len(names));
    } else if (match_keyword(func_keyword)) {
        return parse_type_func();
    } else if (match_token(TOKEN_LPAREN)) {
        type := parse_type();
        expect_token(TOKEN_RPAREN);
        return type;
    } else if (match_token(TOKEN_LBRACE)) {
        return parse_type_tuple();
    } else {
        fatal_error_here(token.pos, "Unexpected token %s in type", token_info());
        return NULL;
    }
}

parse_ion_type() ^Typespec {
    //printf("Huh?\n");
    type := parse_type_ion_base();
    pos := token.pos;
    while (is_token(TOKEN_LBRACKET) || is_token(TOKEN_MUL) || is_keyword(const_keyword)) {
        if (match_token(TOKEN_LBRACKET)) {
            size ^Expr = NULL;
            if (!is_token(TOKEN_RBRACKET)) {
                size = parse_expr();
            }
            expect_token(TOKEN_RBRACKET);
            type = new_typespec_array(pos, type, size);
        } else if (match_keyword(const_keyword)) {
            type = new_typespec_const(pos, type);
        } else {
            #assert(is_token(TOKEN_MUL));
            next_token();
            type = new_typespec_ptr(pos, type);
        }
    }
    return type;

}

parse_decl_func_param() FuncParam {
    pos := token.pos
    name := parse_name()
    expect_token(TOKEN_COLON)
    type := parse_type()
    return (:FuncParam){pos, name, type}
}

parse_decl_func(pos SrcPos) ^Decl {
    name := parse_name()
    expect_token(TOKEN_LPAREN)
    params ^FuncParam = NULL
    has_varargs := false
    varargs_type ^Typespec = NULL
    if (!is_token(TOKEN_RPAREN)) {
        buf_push(params, parse_decl_func_param())
        while (match_token(TOKEN_COMMA)) {
            if (match_token(TOKEN_ELLIPSIS)) {
                if (has_varargs) {
                    error_here(pos, "Multiple ellipsis in function declaration")
                }
                if (!is_token(TOKEN_RPAREN)) {
                    varargs_type = parse_type()
                }
                has_varargs = true
            } else {
                if (has_varargs) {
                    error_here(pos, "Ellipsis must be last parameter in function declaration")
                }
                buf_push(params, parse_decl_func_param())
            }
        }
    }
    expect_token(TOKEN_RPAREN)
    ret_type ^Typespec = NULL
    if (match_token(TOKEN_COLON)) {
        ret_type = parse_type()
    }
    block StmtList
    is_incomplete bool
    if (match_token(TOKEN_SEMICOLON)) {
        is_incomplete = true
    } else {
        block = parse_stmt_block()
        is_incomplete = false
    }
    decl ^Decl = new_decl_func(pos, name, params, buf_len(params), ret_type, has_varargs, varargs_type, block)
    decl.is_incomplete = is_incomplete
    return decl
}

parse_decl_func_param_no_colon() FuncParam {
    pos := token.pos
    name := parse_name()
    //printf("%s\n", token.name)
    //printf()
//    expect_token(TOKEN_NAME)
     param FuncParam 
     param.pos = pos  
     param.name=  name  
     param.type =  parse_type()
     return param
    
}



/*
parse_pp_block(pos SrcPos) PP_StmtList
{
    dummy PP_StmtList
    return dummy

}

parse_decl_define(pos SrcPos) ^Decl 
{
    
    if(match_keyword(ifndef_keyword))
    {
        name := parse_name()
        printf("Here: %s\n", name);


        block PP_StmtList 
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
}*/


do_block(pos SrcPos, name ^char, params ^FuncParam, ret_type ^Typespec, has_varargs bool, varargs_type ^Typespec) ^Decl {

  is_p_func = true;
        block StmtList ;
        is_incomplete bool 
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

        decl := new_decl_func(pos, name, params, buf_len(params), ret_type, has_varargs, varargs_type, block);

        decl.is_incomplete = is_incomplete;
        return decl;
}

parse_pc_func(pos SrcPos, name  ^char) ^Decl {

    expect_token(TOKEN_LPAREN);
        params ^FuncParam = NULL;
        has_varargs := false;
        varargs_type ^Typespec = NULL;
        if (!is_token(TOKEN_RPAREN)) {
            buf_push(params, parse_decl_func_param_no_colon())
            while (match_token(TOKEN_COMMA)) {
                if (match_token(TOKEN_ELLIPSIS)) {
                    if (has_varargs) {
                        error_here(pos, "Multiple ellipsis in function declaration");
                    }
                    if (!is_token(TOKEN_RPAREN)) {
                        varargs_type = parse_type();
                    }
                    has_varargs = true;
                } else {
                    if (has_varargs) {
                        error_here(pos, "Ellipsis must be last parameter in function declaration");
                    }
                    buf_push(params, parse_decl_func_param_no_colon());
                }
            }
        }

        expect_token(TOKEN_RPAREN);
        ret_type ^Typespec  = NULL;
      is_ret_type := false;

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

parse_note_arg() NoteArg { 
    pos := token.pos
    expr := parse_expr()
    name ^char = NULL
    if (match_token(TOKEN_ASSIGN)) {
        if (expr.kind != EXPR_NAME) {
            fatal_error_here(pos, "Left operand of = in note argument must be a name")
        }
        name = expr.name
        expr = parse_expr()
    }
    return (:NoteArg){pos = pos, name = name, expr = expr}
}

parse_note() Note {
    pos := token.pos
    name := parse_name()
    args ^NoteArg = NULL
    if (match_token(TOKEN_LPAREN)) {
        buf_push(args, parse_note_arg())
        while (match_token(TOKEN_COMMA)) {
            buf_push(args, parse_note_arg())
        }
        expect_token(TOKEN_RPAREN)
    }
    return new_note(pos, name, args, buf_len(args))
}

parse_notes() Notes {
    notes ^Note = NULL
    while (match_token(TOKEN_AT)) {
        buf_push(notes, parse_note())
    }
    return new_notes(notes, buf_len(notes))
}

parse_decl_note(pos SrcPos) ^Decl {
    return new_decl_note(pos, parse_note())
}

parse_decl_import(pos SrcPos) ^Decl {
    rename_name ^char = NULL
    is_relative bool 
    :repeat
    is_relative = false;
    if (match_token(TOKEN_DOT)) {
        is_relative = true;
    }
    name: ^char = token.name
    expect_token(TOKEN_NAME);
    if (!is_relative && match_token(TOKEN_ASSIGN)) {
        if (rename_name) {
            fatal_error(pos, "Only one import assignment is allowed");
        }
        rename_name = name;
        goto repeat;
    }
    names ^^char = NULL;
    buf_push(names, name);
    while (match_token(TOKEN_DOT)) {
        buf_push(names, token.name);
        expect_token(TOKEN_NAME);
    }
    import_all: bool = false;
    items ^ImportItem = NULL;
    if (match_token(TOKEN_LBRACE)) {
        while (!is_token(TOKEN_RBRACE)) {
            if (match_token(TOKEN_ELLIPSIS)) {
                import_all = true;
            } else {
                internal_name ^char = parse_name()
                if (match_token(TOKEN_ASSIGN)) {
                    buf_push(items, (:ImportItem){name = parse_name(), rename = internal_name});
                } else {
                    buf_push(items, (:ImportItem){name = internal_name});
                }
                if (!match_token(TOKEN_COMMA)) {
                    break;
                }
            }
        }
        expect_token(TOKEN_RBRACE);
    }
    return new_decl_import(pos, rename_name, is_relative, names, buf_len(names), import_all, items, buf_len(items))
}

parse_decl_ion_enum_item() EnumItem {
    pos := token.pos;
    name := parse_name()
    init ^Expr = NULL
    if (match_token(TOKEN_ASSIGN)) {
        init = parse_expr()
    }
    return (:EnumItem){pos, name, init}
}

parse_decl_ion_enum(pos SrcPos) ^Decl {
    name ^char = NULL
    if (is_token(TOKEN_NAME)) {
        name = parse_name()
    }
    type ^Typespec = NULL
    if (match_token(TOKEN_ASSIGN)) {
        type = parse_type()
    }
    expect_token(TOKEN_LBRACE);
    items ^EnumItem = NULL
    while (!is_token(TOKEN_RBRACE)) {
        buf_push(items, parse_decl_ion_enum_item());
        if (!match_token(TOKEN_COMMA)) {
            break;
        }
    }
    expect_token(TOKEN_RBRACE);
    return new_decl_enum(pos, name, type, items, buf_len(items));
}

parse_file() ^DeclSet {
    decls ^^Decl = NULL
    while (!is_token(TOKEN_EOF)) {
        buf_push(decls, parse_decl())
    }
    printf("Parsing Complete\n")
    return decl_set(decls, buf_len(decls))
}

parse_decl_opt() ^Decl {
    gpos := token.pos;
    is_p_func = false;
   is_p_struct = false;
    if (match_keyword(enum_keyword)) {
        return parse_decl_ion_enum(gpos)
    } else if (match_keyword(struct_keyword)) {
        return parse_decl_ion_aggregate(gpos, DECL_STRUCT)
    } else if (match_keyword(union_keyword)) {
        return parse_decl_aggregate(gpos, DECL_UNION);
    } else if (match_keyword(const_keyword)) {
        return parse_decl_const(gpos);
    } else if (match_keyword(typedef_keyword)) {
        return parse_decl_typedef(gpos);
    } else if (match_keyword(func_keyword)) {
        return parse_decl_func(gpos)
    } else if (match_keyword(var_keyword)) {
        return parse_decl_var(gpos);
    } else if (match_keyword(import_keyword)) {
        return parse_decl_import(gpos);
    } else if (match_token(TOKEN_POUND)) {
        return parse_decl_note(gpos);
    } /*else if(match_token(TOKEN_DOLLAR)) {
        return parse_decl_define(gpos);
    } */else if(is_token(TOKEN_NAME)) {

    name := parse_name()
        
    if(match_keyword(fn_keyword) || is_token(TOKEN_LPAREN)) {

        return parse_pc_func(gpos, name)            
    }
         
    if(match_token(TOKEN_ASSIGN)) {
        expr := parse_expr()
        optional_token(TOKEN_SEMICOLON)
        return new_decl_var(gpos, name, NULL, expr)
    }

    optional_token(TOKEN_SEMICOLON)

    if(match_keyword(struct_keyword)) {
        pos := token.pos
        is_p_struct = true
        return parse_decl_struct(name, pos, DECL_STRUCT)

    }

    else if(match_keyword(union_keyword)) {
        pos := token.pos
        is_p_struct = true
        return parse_decl_struct(name, pos, DECL_UNION)
    }

    else if(match_keyword(enum_keyword)) {
        pos := token.pos
        return parse_decl_enum(name, pos)
    }

    type := parse_type();
    expr ^Expr = NULL
    if(match_token(TOKEN_ASSIGN)) {
        expr = parse_expr()
        return new_decl_var(gpos, name, type, expr)
    }

    return new_decl_var(gpos, name, type, NULL)
    }
    printf("Error\n")
    return NULL
}

parse_decl() ^Decl {
   
    notes := parse_notes()
    decl := parse_decl_opt()
    if (!decl) {
        fatal_error_here(token.pos, "Expected declaration keyword, got %s", token_info())
        
    }
    decl.notes = notes
    return decl
}

parse_decls() ^Decls {
    decls ^^Decl = NULL
    while (!is_token(TOKEN_EOF)) {
        buf_push(decls, parse_decl())
    }
    return new_decls(decls, buf_len(decls))
}