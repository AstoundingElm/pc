output_file ^FILE 
stackpos int

nl(){

fprintf(output_file, "\n")
}


emit(text ^char){

  fprintf(output_file, text)

}


emit_data_type(sym ^Sym)
{

    switch(sym.type.kind){
 case PTYPE_NONE: {}
    case PTYPE_INCOMPLETE: {}
    case PTYPE_COMPLETING: {}
    case PTYPE_VOID: {}
    case PTYPE_BOOL: {}
    case PTYPE_CHAR: {}
    case PTYPE_SCHAR: {}
    case PTYPE_UCHAR: {}
    case PTYPE_SHORT: {}
    case PTYPE_USHORT: {}
     case PTYPE_INT:{
    
    emit(".long 4")
    nl()
    }

    case PTYPE_UINT: {}
    case PTYPE_LONG: {}
    case PTYPE_ULONG: {}
    case PTYPE_LLONG: {}
    case PTYPE_ULLONG: {}
    case PTYPE_ENUM: {}
    case PTYPE_FLOAT: {}
    case PTYPE_DOUBLE: {}
    case PTYPE_PTR: {}
    case PTYPE_FUNC: {}
    case PTYPE_ARRAY: {}
    case PTYPE_STRUCT: {}
    case PTYPE_UNION: {}
    case PTYPE_TUPLE: {}
    case PTYPE_CONST: {}
        }
   

}

REGS ^[] char = {"rdi", "rsi", "rdx", "rcx", "r8", "r9"}

push(reg ^char)
{
    //SAVE;
    //emit("push %%%s", reg);
    if(reg == "rbp"){
    emit("push %rbp")
    nl()

    }

    else if(reg == "rdi"){

        emit("push %rdi")
        nl()
    }
    else if(reg == "rsi"){
    emit("push %rsi")
    nl()

    }
    else if(reg == "rdx"){
    emit("push %rdx")
    nl()

    }

    else if(reg == "rcx"){
    emit("push %rcx")
    nl()

    }

    else if(reg == "r8"){
    emit("push %r8")
    nl()

    }

    else if(reg == "r9"){
    emit("push %r9")
    nl()

    }
    
    
    
    
    stackpos += 8;
}

align(n int, m int) int
{
    rem int  = n % m;
    return (rem == 0) ? n : n - rem + m;
}

emit_func_prologue(sym^Sym)
{
    emit(".text");
    nl()
    emit(".global ")
    emit(sym.decl.name)
    nl()
    emit(sym.decl.name)
    emit(":")
    nl()

    push("rbp");
    emit("mov %rsp, %rbp");
    nl()

    off int = 0;
    ireg int = 0;
    xreg int = 0;

        for (i usize = 0; i < sym.decl.d_func.num_params; i++) {
            param := sym.decl.d_func.params[i];
                push(REGS[ireg++])
                off -= align(sym.type.align, 8);
        sym.decl.loff = off;
        }

       /*  for (Iter i = list_iter(func->localvars); !iter_end(i);) {
        Ast *v = iter_next(&i);
        off -= align(v->ctype->size, 8);
        v->loff = off;
    }*/

        for (i := 0; i < sym.decl.d_func.block.num_stmts; i++) {
        //gen_stmt(block.stmts[i]);
            stmt ^ Stmt =  sym.decl.d_func.block.stmts[i]

            off -= align(8, 8);
            stmt.loff = off;

    }

        if (off){
            emit("add $")
            str [2]char
            sprintf(str, "%d", off)
            
            emit(str)
            emit(",")
            emit("%rsp")
            nl()
    }
    stackpos += -(off - 8);

}

emit_expr(sym ^Sym){

//for (i := 0; i < block.num_stmts; i++) {
        //gen_stmt(block.stmts[i]);
  //  }
}

emit_func_decl(sym ^Sym){
/*#assert(decl.kind == DECL_FUNC);
    result ^char = NULL;
   
    buf_printf(result, "%s(", get_gen_name(decl));
    if (decl.d_func.num_params == 0) {
        buf_printf(result, "void");
    } else {
        for (i usize = 0; i < decl.d_func.num_params; i++) {
            param := decl.d_func.params[i];
            if (i != 0) {
                buf_printf(result, ", ");
            }
            buf_printf(result, "%s", type_to_cdecl(incomplete_decay(get_resolved_type(param.type)), param.name));
        }
    }
    if (decl.d_func.has_varargs) {
        buf_printf(result, ", ...");
    }
    buf_printf(result, ")");
    gen_sync_pos(decl.pos);
    if (decl.d_func.ret_type) {
        genlnf("%s", type_to_cdecl(incomplete_decay(get_resolved_type(decl.d_func.ret_type)), result));
    } else {
        genlnf("void %s", result);
    }*/

    emit_func_prologue(sym)
    emit_expr(sym)
}

emit_toplevel(sym ^Sym){

//so our var decls need to be fixed. the first vars are func locals 
decl := sym.decl
 /*stackpos = 0;
    if (v->type == AST_FUNC) {
        emit_func_prologue(v);
        emit_expr(v->body);
        emit_func_epilogue();
    } else if (v->type == AST_DECL) {
        emit_global_var(v);
    } else {
        error("internal error");
    }*/

    stackpos = 0

    if(decl.kind == DECL_FUNC){

        emit_func_decl(sym)
    }


}

emit_sorted_decls() {
    /*for (i int = 0; i < buf_len(tuple_types); i++) {
        type := tuple_types[i];
        if (!is_tuple_reachable(type)) {
            continue;
        }
        genlnf("struct tuple%d {", type.typeid);
        gen_indent++;
        for (_i usize = 0; _i < type.t_aggregate.num_fields; _i++) {
            field := type.t_aggregate.fields[_i];
            genlnf("%s;", type_to_cdecl(field.type, field.name));
        }
        gen_indent--;
        genlnf("};");
    }*/


    for (i usize = 0; i < buf_len(sorted_syms); i++) {
        if (sorted_syms[i].reachable == REACHABLE_NATURAL) {
            emit_toplevel(sorted_syms[i]);
        }
    }
}

emit_data_section(){

    emit(".data")
    nl()
     for (it := sorted_syms; it != buf_end(sorted_syms); it++) {
        sym := *it;
        decl := sym.decl;
        if (sym.state != SYM_RESOLVED || !decl || decl.is_incomplete || sym.reachable != REACHABLE_NATURAL) {
            continue;
        }

        if (decl.kind == DECL_VAR){
            //genlnf("%s", type_to_cdecl(sym.type, get_gen_name(sym)));
            
            emit(get_gen_name(sym))
            emit(":")
            nl()
           emit_data_type(sym)
        }

    }
    
}


codegen_program(){


/*
output_file =  fopen("output.s", "w")


if(!output_file){

  printf("Failed to open output_file\n")
}

emit_data_section()
emit_sorted_decls()
 */

    //pe_init()
    //gen_exe()
    printf("Hi\n")
 
//fclose(output_file)
}


