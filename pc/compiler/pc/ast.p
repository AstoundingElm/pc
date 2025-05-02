


NoteArg struct {
    pos SrcPos 
    name ^char
    expr ^Expr 
} 

Note struct {
    pos SrcPos
    name ^char
    args ^NoteArg
    num_args usize
} 

Notes struct {
    notes ^Note
    num_notes usize
} 

StmtList struct{
    pos SrcPos
    stmts ^^Stmt
    num_stmts usize
} 

TypespecKind enum {
    TYPESPEC_NONE,
    TYPESPEC_NAME,
    TYPESPEC_FUNC,
    TYPESPEC_ARRAY,
    TYPESPEC_PTR,
    TYPESPEC_CONST,
    TYPESPEC_TUPLE,
} 

Typespec struct {
    kind TypespecKind
    pos SrcPos 
    base ^Typespec
    union {
        anonymousstruct {
            names ^^char
            num_names usize
        }
        ts_func struct {
            args ^^Typespec 
            num_args usize
            has_varargs bool
            ret ^Typespec 
        } 
        tuple struct {
            fields ^^Typespec 
            num_fields usize
        } 
        num_elems ^Expr
    }
}

FuncParam struct{
    pos SrcPos
    name ^char 
    type ^Typespec 
    align int
} 

AggregateItemKind enum {
    AGGREGATE_ITEM_NONE,
    AGGREGATE_ITEM_FIELD,
    AGGREGATE_ITEM_SUBAGGREGATE,
    AGGREGATE_ITEM_FIELD_UNION,
    AGGREGATE_ITEM_ANONYMOUS_STRUCT,
}

 AggregateItem struct{
    pos SrcPos
    name ^char
    kind AggregateItemKind
    union {
         anonymousstruct {
            names ^^char
            num_names usize 
            type ^Typespec
            internal_struct ^Decl
            is_union bool
            is_internal_struct bool
        }
        subaggregate ^Aggregate

    }
} 

EnumItem struct{
    pos SrcPos
    name ^char
    init ^Expr
} 

ImportItem struct {
    name ^char
    rename ^char
} 

 DeclKind enum{
    DECL_NONE,
    DECL_ENUM,
    DECL_STRUCT,
    DECL_ANONYMOUS_STRUCT,
    DECL_UNION,

    DECL_VAR,
    DECL_CONST,
    DECL_TYPEDEF,
    DECL_FUNC,
    DECL_NOTE,
    DECL_IMPORT,
} 

AggregateKind enum {
    AGGREGATE_NONE,
    AGGREGATE_STRUCT,
    AGGREGATE_UNION,
    AGGREGATE_ANONYMOUS_STRUCT,
}

Aggregate struct {
    pos SrcPos 
    kind AggregateKind 
    items ^AggregateItem
    num_items usize
} 

PP_StmtList struct {

pos SrcPos 
defines ^^PP_Define
num_defines usize

}

DefineKind enum {
PP_IFNFDEF,
PP_IF_DEFINED,
PP_DEFINE,
PP_ELIF,
PP_ELSE,
PP_ERROR,
PP_ENDIF

}

PP_Define struct {
    pos SrcPos 
    name ^char
    expr ^Expr
    block SrcPos 
    kind DefineKind
}

 Decl struct{
    kind DeclKind
    pos SrcPos
    name ^char
    notes Notes
    is_incomplete bool
    d_define PP_Define
    union {
        note Note 
        enum_decl struct {
            type ^Typespec 
            items ^EnumItem
            num_items usize
        }
        aggregate ^Aggregate 
        d_func struct {
            params ^FuncParam 
            num_params usize
            ret_type ^Typespec
            has_varargs bool
            varargs_type ^Typespec
            block StmtList 
        }
        typedef_decl struct {
            type ^Typespec 
        } 
        d_var struct  {
            type ^Typespec 
            expr ^Expr 
        } 
        const_decl struct {
            type ^Typespec 
            expr ^Expr
        } 
        d_import struct {
            is_relative bool 
            names ^^char
            num_names usize
            import_all bool 
            items ^ImportItem 
            num_items usize
        } 
    }

    loff int
}

DeclSet struct {
    decls ^^Decl
    num_decls usize
} 

Decls struct {
    decls ^^Decl
    num_decls usize
}


ExprKind enum {
    EXPR_NONE,
    EXPR_PAREN,
    EXPR_INT,
    EXPR_FLOAT,
    EXPR_STR,
    EXPR_NAME,
    EXPR_CAST,
    EXPR_CALL,
    EXPR_INDEX,
    EXPR_FIELD,
    EXPR_COMPOUND,
    EXPR_UNARY,
    EXPR_BINARY,
    EXPR_TERNARY,
    EXPR_MODIFY,
    EXPR_SIZEOF_EXPR,
    EXPR_SIZEOF_TYPE,
    EXPR_TYPEOF_EXPR,
    EXPR_TYPEOF_TYPE,
    EXPR_ALIGNOF_EXPR,
    EXPR_ALIGNOF_TYPE,
    EXPR_OFFSETOF,
    EXPR_NEW,
} 

CompoundFieldKind enum {
    FIELD_DEFAULT,
    FIELD_NAME,
    FIELD_INDEX,
}

CompoundField struct {
    kind CompoundFieldKind
    pos SrcPos
    init ^Expr
    union {
        name ^char
        index ^Expr 
    }
}

Expr struct {
     kind ExprKind
     pos SrcPos
   union {
        paren struct {
            expr ^Expr 
        }
        int_lit struct {
            val ullong
            mod TokenMod
            suffix TokenSuffix
        } 
        float_lit struct {
            start ^char
            end ^char
            val double
            suffix TokenSuffix
        } 
        str_lit struct {
            val ^char
            mod TokenMod 
        } 
        name ^char
        sizeof_expr ^Expr 
        sizeof_type ^Typespec
        typeof_expr ^Expr 
        typeof_type ^Typespec
        alignof_expr ^Expr
        alignof_type ^Typespec

        offsetof_field struct {
            type ^Typespec 
            name ^char
        } 
        compound struct {
            type ^Typespec
            fields ^CompoundField
            num_fields usize
        } 
        cast struct {
            type ^Typespec
            expr ^Expr
        } 
        modify struct {
            op TokenKind
            post bool
            expr ^Expr
        } 
        unary struct {
            op TokenKind
            expr ^Expr
        } 
        binary struct {
            op TokenKind
            left ^Expr
            right ^Expr
        } 
        ternary struct {
            cond ^Expr
            then_expr ^Expr
            else_expr ^Expr
        } 
        call struct {
            expr ^Expr
            args ^^Expr
            num_args usize
        } 
        index struct {
            expr ^Expr
            index ^Expr
        } 
        field struct {
            expr ^Expr
            name ^char
        }
        e_new_expr struct {
            alloc ^Expr
            len ^Expr
            arg ^Expr
        } 
    }
}

 ElseIf struct {
    cond :^Expr
     block StmtList
} 

SwitchCasePattern struct {
    start ^Expr;
    end ^Expr;
} 

 SwitchCase struct{
    patterns ^SwitchCasePattern ;
    num_patterns usize;
    is_default bool;
    block StmtList;
}

StmtKind enum {
    STMT_NONE,
    STMT_DECL,
    STMT_CF_RETURN,
    STMT_RETURN,
    STMT_BREAK,
    STMT_CONTINUE,
    STMT_BLOCK,
    STMT_IF,
    STMT_WHILE,
    STMT_DO_WHILE,
    STMT_FOR,
    STMT_SWITCH,
    STMT_ASSIGN,
    STMT_INIT,
    STMT_EXPR,
    STMT_NOTE,
    STMT_LABEL,
    STMT_GOTO,
} 

 Stmt struct {
    kind StmtKind
    notes Notes
    pos SrcPos
    union {
        note Note
        expr ^Expr 
        decl ^Decl 
        if_stmt struct {
            init ^Stmt 
            cond ^Expr
            then_block StmtList
            elseifs ^ElseIf
            num_elseifs usize
            else_block StmtList
        } 
        while_stmt struct {
            cond ^Expr
            block StmtList
        } 
        for_stmt struct {
            init ^Stmt
            cond ^Expr
            next ^Stmt
            block StmtList
        }
        switch_stmt struct {
            expr ^Expr
            cases ^SwitchCase
            num_cases usize            
        } 
        block StmtList 
        assign struct {
            op TokenKind 
            left ^Expr
            right ^Expr
        } 
        init struct {
            name ^char
            type ^Typespec
            expr ^Expr
            is_undef bool
        } 
        label ^char
    }
    loff int
    align int
}

ast_arena Arena 

ast_memory_usage usize

ast_alloc(size usize) ^void {
    #assert(size != 0)
    ptr ^void  = pc_arena_alloc(&ast_arena, size)
    pc_memset(ptr, 0, size)
    ast_memory_usage += size
    return ptr
}

ast_dup(src ^void, size usize) ^void  {
    if (size == 0) {
        return NULL
    }
    ptr ^void = pc_arena_alloc(&ast_arena, size)
    pc_memcpy(ptr, src, size)
    return ptr
}

new_note(pos SrcPos, name ^char, args ^NoteArg, num_args usize) Note {
    return (:Note){pos = pos, name = name, args = ast_dup(args, num_args *sizeof(*args)), num_args = num_args}
}

new_notes(notes ^Note , num_notes usize) Notes {
    return (:Notes){ast_dup(notes, num_notes *sizeof(*notes)), num_notes}
}

new_stmt_list(pos SrcPos, stmts ^^Stmt,  num_stmts usize)  StmtList{
    return (:StmtList){pos, ast_dup(stmts, num_stmts * sizeof(*stmts)), num_stmts}
}

new_typespec(kind TypespecKind, pos SrcPos) ^Typespec {
    t ^Typespec = ast_alloc(sizeof(Typespec))
    t.kind = kind
    t.pos = pos
    return t
}

new_typespec_name(pos SrcPos, names ^^char, num_names usize) ^Typespec {
    t ^Typespec = new_typespec(TYPESPEC_NAME, pos)
    t.names = ast_dup(names, num_names * sizeof(*names))
    t.num_names = num_names
    return t

}

new_typespec_ptr(pos SrcPos, base ^Typespec) ^Typespec {
    t := new_typespec(TYPESPEC_PTR, pos)
    t.base = base
    return t
}

new_typespec_const(pos SrcPos , base ^Typespec) ^Typespec {
    t ^Typespec = new_typespec(TYPESPEC_CONST, pos)
    t.base = base
    return t
}

new_typespec_array(pos SrcPos, base ^Typespec, num_elems ^Expr) ^Typespec {
    t := new_typespec(TYPESPEC_ARRAY, pos)
    t.base = base
    t.num_elems = num_elems
    return t
}

new_typespec_func(pos SrcPos, args ^^Typespec, num_args usize, ret ^Typespec, has_varargs bool) ^Typespec {
    t := new_typespec(TYPESPEC_FUNC, pos)
    t.ts_func.args = ast_dup(args, num_args * sizeof(*args))
    t.ts_func.num_args = num_args
    t.ts_func.ret = ret
    t.ts_func.has_varargs = has_varargs
    return t
}

new_typespec_tuple(pos SrcPos, fields ^^Typespec, num_fields usize) ^Typespec {
    t ^Typespec = new_typespec(TYPESPEC_TUPLE, pos)
    t.tuple.fields = ast_dup(fields, num_fields * sizeof(*fields))
    t.tuple.num_fields = num_fields
    return t
}

new_decls(decls ^^Decl, num_decls usize) ^Decls {
    d ^Decls = ast_alloc(sizeof(Decls))
    d.decls = ast_dup(decls, num_decls * sizeof(*decls))
    d.num_decls = num_decls
    return d
}

new_decl(kind DeclKind, pos SrcPos, name ^char ) ^Decl {
    d ^Decl  = ast_alloc(sizeof(Decl))
    d.kind = kind
    d.pos = pos
    d.name = name
    return d
}

get_decl_note(decl ^Decl, name ^char) ^Note {
    if (!decl) {
        return NULL;
    }
    for (i := 0; i < decl.notes.num_notes; i++) {
        note := decl.notes.notes + i;
        if (note.name == name) {
            return note;
        }
    }
    return NULL;
}

is_decl_threadlocal(decl ^Decl) bool {
    return decl && get_decl_note(decl, str_intern("threadlocal")) != NULL;
}

is_decl_foreign(decl ^Decl) bool {
    return decl && get_decl_note(decl, foreign_name) != NULL;
}

new_decl_enum(pos SrcPos, name ^char, type ^Typespec, items ^EnumItem, num_items usize) ^Decl {
    d ^Decl = new_decl(DECL_ENUM, pos, name)
    d.enum_decl.type = type
    d.enum_decl.items = ast_dup(items, num_items * sizeof(*items))
    d.enum_decl.num_items = num_items
    return d
}

new_aggregate(pos SrcPos, kind AggregateKind, items ^AggregateItem, num_items usize) ^Aggregate {
    aggregate ^Aggregate = ast_alloc(sizeof(Aggregate))
    aggregate.pos = pos
    aggregate.kind = kind
    aggregate.items = ast_dup(items, num_items *sizeof(*items))
    aggregate.num_items = num_items
    return aggregate
}

new_stmt_label(pos SrcPos, label ^char) ^Stmt {
    s ^Stmt = new_stmt(STMT_LABEL, pos)
    s.label = label
    return s
}

new_stmt_goto(pos SrcPos, label ^char) ^Stmt {
    s ^Stmt = new_stmt(STMT_GOTO, pos)
    s.label = label
    return s
}

new_stmt_cf_return(pos SrcPos) ^Stmt {
    s := new_stmt(STMT_CF_RETURN, pos)
    return s
}

decl_set(decls ^^Decl, num_decls usize) ^DeclSet {
    declset : ^DeclSet = ast_alloc(sizeof(DeclSet))
    declset.decls = ast_dup(decls, num_decls * sizeof(*decls))
    declset.num_decls = num_decls
    return declset
}

decl_aggregate(pos SrcPos, kind DeclKind, name ^char, items ^AggregateItem, num_items usize) ^Decl{
    #assert(kind == DECL_STRUCT || kind == DECL_UNION)
    d := new_decl(kind, pos, name)
    d.aggregate.items = ast_dup(items, num_items * sizeof(*items))
    d.aggregate.num_items = num_items
    return d
}

new_decl_aggregate(pos SrcPos, kind DeclKind, name ^char, aggregate ^Aggregate) ^Decl {
    #assert(kind == DECL_STRUCT || kind == DECL_UNION)
    d ^Decl = new_decl(kind, pos, name)
    d.aggregate = aggregate
    return d
}

decl_union(pos SrcPos, name ^char, items ^AggregateItem, num_items usize) ^Decl {
    d := new_decl(DECL_UNION, pos, name)
    d.aggregate.items = ast_dup(items, num_items * sizeof(*items))
    d.aggregate.num_items = num_items
    return d
}

new_decl_var(pos SrcPos, name ^char, type ^Typespec , expr ^Expr ) ^Decl {
    d := new_decl(DECL_VAR, pos, name)
    d.d_var.type = type
    d.d_var.expr = expr
    return d
}


new_decl_func(pos SrcPos, name ^char, params ^FuncParam, num_params usize, ret_type ^Typespec, has_varargs bool, varargs_type ^Typespec, block StmtList) ^ Decl {
    d ^Decl = new_decl(DECL_FUNC, pos, name)
    d.d_func.params = ast_dup(params, num_params * sizeof(*params))
    d.d_func.num_params = num_params
    d.d_func.ret_type = ret_type
    d.d_func.has_varargs = has_varargs
    d.d_func.varargs_type = varargs_type
    d.d_func.block = block
    return d
}

new_decl_const(pos SrcPos, name ^char, type ^Typespec, expr ^Expr ) ^Decl {
    d := new_decl(DECL_CONST, pos, name)
    d.const_decl.type = type
    d.const_decl.expr = expr
    return d
}

new_decl_typedef(pos SrcPos, name ^char, type ^Typespec) ^Decl {
    d := new_decl(DECL_TYPEDEF, pos, name)
    d.typedef_decl.type = type
    return d
}

new_decl_note(pos SrcPos, note Note) ^Decl {
    d ^Decl = new_decl(DECL_NOTE, pos, NULL)
    d.note = note
    return d
}

new_decl_import(pos SrcPos, rename_name ^char, is_relative bool, names ^^char, num_names usize, import_all bool, items ^ImportItem, num_items usize) ^Decl {
    d ^Decl = new_decl(DECL_IMPORT, pos, NULL)
    d.name = rename_name
    d.d_import.is_relative = is_relative
    d.d_import.names = ast_dup(names, num_names *sizeof(*names))
    d.d_import.num_names = num_names
    d.d_import.import_all = import_all
    d.d_import.items = ast_dup(items, num_items *sizeof(*items))
    d.d_import.num_items = num_items
    return d;
}

new_expr(kind ExprKind, pos SrcPos) ^Expr  {
    e ^Expr = ast_alloc(sizeof(Expr))
    e.kind = kind
    e.pos = pos
    return e
}

expr_sizeof_expr(pos SrcPos, expr ^Expr) ^Expr{
    e ^Expr = new_expr(EXPR_SIZEOF_EXPR, pos)
    e.sizeof_expr = expr
    return e
}

expr_sizeof_type(pos SrcPos, type ^Typespec) ^Expr {
    e := new_expr(EXPR_SIZEOF_TYPE, pos)
    e.sizeof_type = type
    return e
}

new_expr_modify(pos SrcPos, op TokenKind, post bool, expr ^Expr) ^Expr {
    e: ^Expr = new_expr(EXPR_MODIFY, pos)
    e.modify.op = op
    e.modify.post = post
    e.modify.expr = expr
    return e
}

new_expr_int(pos SrcPos, val ullong, mod TokenMod, suffix TokenSuffix) ^Expr {
    e ^Expr = new_expr(EXPR_INT, pos)
    e.int_lit.val = val
    e.int_lit.mod = mod
    e.int_lit.suffix = suffix
    return e
}

new_expr_float(pos SrcPos, start ^char, end ^char, val double, suffix TokenSuffix) ^Expr {
    e ^Expr = new_expr(EXPR_FLOAT, pos)
    e.float_lit.start = start
    e.float_lit.end = end
    e.float_lit.val = val
    e.float_lit.suffix = suffix
    return e
}

new_expr_str(pos SrcPos, val ^char, mod TokenMod) ^Expr {
    e := new_expr(EXPR_STR, pos)
    e.str_lit.val = val
    e.str_lit.mod = mod
    return e
}

new_expr_name(pos SrcPos, name ^char) ^Expr {
    e := new_expr(EXPR_NAME, pos)
    e.name = name
    return e
}

new_expr_paren(pos SrcPos, expr ^Expr) ^Expr {
    e ^Expr = new_expr(EXPR_PAREN, pos)
    e.paren.expr = expr
    return e
}

new_expr_sizeof_expr(pos SrcPos, expr ^Expr) ^Expr {
    e ^Expr = new_expr(EXPR_SIZEOF_EXPR, pos)
    e.sizeof_expr = expr
    return e
}

new_expr_sizeof_type(pos SrcPos, type ^Typespec) ^Expr {
    e ^Expr = new_expr(EXPR_SIZEOF_TYPE, pos)
    e.sizeof_type = type
    return e
}

new_expr_typeof_expr(pos SrcPos, expr ^Expr) ^Expr {
    e ^Expr = new_expr(EXPR_TYPEOF_EXPR, pos)
    e.typeof_expr  = expr
    return e
}

new_expr_typeof_type(pos SrcPos, type ^Typespec) ^Expr {
    e: ^Expr = new_expr(EXPR_TYPEOF_TYPE, pos)
    e.typeof_type = type
    return e
}

new_expr_alignof_expr(pos SrcPos, expr ^Expr) ^Expr {
    e ^Expr = new_expr(EXPR_ALIGNOF_EXPR, pos)
    e.alignof_expr = expr
    return e
}

new_expr_alignof_type(pos SrcPos, type ^Typespec) ^Expr {
    e ^Expr = new_expr(EXPR_ALIGNOF_TYPE, pos)
    e.alignof_type = type
    return e
}

new_expr_offsetof(pos SrcPos, type ^Typespec, name ^char) ^Expr{
    e ^Expr = new_expr(EXPR_OFFSETOF, pos)
    e.offsetof_field.type = type
    e.offsetof_field.name = name
    return e
}

expr_compound(pos SrcPos, type ^Typespec, fields ^CompoundField, num_fields usize) ^Expr {
    e := new_expr(EXPR_COMPOUND, pos)
    e.compound.type = type
    e.compound.fields = ast_dup(fields, num_fields * sizeof(*fields))
    e.compound.num_fields = num_fields
    return e
}

new_expr_cast(pos SrcPos, type ^Typespec, expr ^Expr) ^Expr {
    e := new_expr(EXPR_CAST, pos)
    e.cast.type = type
    e.cast.expr = expr
    return e
}

new_expr_call(pos SrcPos, expr ^Expr, args ^^Expr, num_args usize) ^Expr {
    e := new_expr(EXPR_CALL, pos)
    e.call.expr = expr
    e.call.args = ast_dup(args, num_args * sizeof(*args))
    e.call.num_args = num_args
    return e
}

new_expr_index(pos SrcPos, expr ^Expr, index ^Expr) ^Expr {
    e := new_expr(EXPR_INDEX, pos)
    e.index.expr = expr
    e.index.index = index
    return e
}

new_expr_field(pos SrcPos, expr ^Expr, name ^char) ^Expr {
    e := new_expr(EXPR_FIELD, pos)
    e.field.expr = expr
    e.field.name = name
    return e
}

new_expr_unary(pos SrcPos, op TokenKind, expr ^Expr) ^Expr {
    e := new_expr(EXPR_UNARY, pos)
    e.unary.op = op
    e.unary.expr = expr
    return e
}

new_expr_binary(pos SrcPos, op TokenKind, left ^Expr, right ^Expr) ^Expr {
    e := new_expr(EXPR_BINARY, pos)
    e.binary.op = op
    e.binary.left = left
    e.binary.right = right
    return e
}

expr_ternary(pos SrcPos, cond ^Expr, then_expr ^Expr, else_expr ^Expr) ^Expr {
    e := new_expr(EXPR_TERNARY, pos)
    e.ternary.cond = cond
    e.ternary.then_expr = then_expr
    e.ternary.else_expr = else_expr
    return e
}

new_expr_new(pos SrcPos, alloc ^Expr, len ^Expr, arg ^Expr) ^Expr {
    e := new_expr(EXPR_NEW, pos)
    e.e_new_expr.alloc = alloc
    e.e_new_expr.len = len
    e.e_new_expr.arg = arg
    return e
}


get_stmt_note(stmt ^Stmt, name ^char) ^Note {
    for (i usize = 0; i < stmt.notes.num_notes; i++) {
        note := stmt.notes.notes + i
        if (note.name == name) {
            return note
        }
    }
    return NULL
}

new_stmt(kind StmtKind, pos SrcPos) ^Stmt {
    s ^Stmt  = ast_alloc(sizeof(Stmt))
    s.kind = kind
    s.pos = pos
    return s
}

new_stmt_note(pos SrcPos, note Note) ^Stmt {
    s ^Stmt = new_stmt(STMT_NOTE, pos)
    s.note = note
    return s
}

stmt_decl(pos SrcPos, decl ^Decl) ^Stmt {
    s := new_stmt(STMT_DECL, pos)
    s.decl = decl
    return s
}

new_stmt_return(pos SrcPos, expr ^Expr) ^Stmt {
    s := new_stmt(STMT_RETURN, pos)
    s.expr = expr
    return s
}
new_stmt_null_return(pos SrcPos, expr ^Expr) ^Stmt {
    s: ^Stmt = new_stmt(STMT_CF_RETURN, pos)
    return s
}

new_stmt_break(pos SrcPos) ^Stmt {
    return new_stmt(STMT_BREAK, pos)
}


new_stmt_continue(pos SrcPos) ^Stmt {
    return new_stmt(STMT_CONTINUE, pos)
}

new_stmt_block(pos SrcPos, block StmtList) ^Stmt {
    s: ^Stmt = new_stmt(STMT_BLOCK, pos)
    s.block = block
    return s
}

new_stmt_if(pos SrcPos, init ^Stmt, cond ^Expr, then_block StmtList, elseifs ^ElseIf, num_elseifs usize, else_block StmtList) ^Stmt {
    s: ^Stmt = new_stmt(STMT_IF, pos)
    s.if_stmt.init = init;
    s.if_stmt.cond = cond;
    s.if_stmt.then_block = then_block;
    s.if_stmt.elseifs = ast_dup(elseifs, num_elseifs * sizeof(*elseifs));
    s.if_stmt.num_elseifs = num_elseifs;
    s.if_stmt.else_block = else_block
    return s;
}

new_stmt_while(pos SrcPos, cond ^Expr, block StmtList) ^Stmt {
    s := new_stmt(STMT_WHILE, pos)
    s.while_stmt.cond = cond
    s.while_stmt.block = block
    return s
}

stmt_do_while(pos SrcPos, cond ^Expr,  block StmtList) ^Stmt {
    s := new_stmt(STMT_DO_WHILE, pos)
    s.while_stmt.cond = cond
    s.while_stmt.block = block
    return s
}
   
new_stmt_for(pos SrcPos, init ^Stmt, cond ^Expr, next ^Stmt, block StmtList) ^Stmt {
    s := new_stmt(STMT_FOR, pos)
    s.for_stmt.init = init
    s.for_stmt.cond = cond
    s.for_stmt.next = next
    s.for_stmt.block = block
    return s
}

new_stmt_switch(pos SrcPos, expr ^Expr, cases ^SwitchCase, num_cases usize) ^Stmt {
    s := new_stmt(STMT_SWITCH, pos)
    s.switch_stmt.expr = expr
    s.switch_stmt.cases = ast_dup(cases, num_cases * sizeof(*cases))
    s.switch_stmt.num_cases = num_cases
    return s
}

new_stmt_assign(pos SrcPos, op TokenKind, left ^Expr, right ^Expr) ^Stmt {
    s := new_stmt(STMT_ASSIGN, pos)
    s.assign.op = op
    s.assign.left = left
    s.assign.right = right
    return s
}

new_stmt_init(pos SrcPos, name ^char, type ^Typespec, expr ^Expr, is_undef bool) ^Stmt {
    s := new_stmt(STMT_INIT, pos)
    s.init.name = name
    s.init.type = type
    s.init.expr = expr
    s.init.is_undef = is_undef
    return s
}

new_stmt_expr(pos SrcPos, expr ^Expr) ^Stmt {
    s := new_stmt(STMT_EXPR, pos)
    s.expr = expr
    return s
}
