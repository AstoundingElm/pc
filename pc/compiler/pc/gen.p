@foreign
gen_buf ^char 

@foreign("genf")
genf(nil char *, ...) -> void;

@foreign("genlnf")
genlnf(n char *, ...) -> void;

@foreign("genln")
genln() -> void;

@foreign
gen_indent int
gen_pos SrcPos

gen_preamble_buf ^char
gen_postamble_buf ^char

gen_headers_buf ^^char

is_incomplete_array_typespec(typespec ^Typespec) bool {
    return typespec.kind == TYPESPEC_ARRAY && !typespec.num_elems
}

char_to_escape[256] char = {
    ['\0'] = '0',
    ['\n'] = 'n',
    ['\r'] = 'r',
    ['\t'] = 't',
    ['\v'] = 'v',
    ['\b'] = 'b',
    ['\a'] = 'a',
    ['\\'] = '\\',
    ['"'] = '"',
    ['\''] = '\'',
}

gen_char(c char) {
    if (char_to_escape[(:uchar)c]) {
        genf("'\\%c'", char_to_escape[(:uchar)c])
    } else if (pc_isprint(c)) {
        genf("'%c'", c)
    } else {
        genf("'\\x%x'", (:uchar)c)
    }
}

gen_str(str ^char, multiline bool) {
      if (multiline) {
        gen_indent++;
        genln();
    }
    genf("\"");
    while (*str) {
        start ^char = str;
        while (*str && pc_isprint(*str) && !char_to_escape[(:uchar)*str]) {
            str++;
        }
        if (start != str) {
            genf("%.*s", str - start, start);
        }
        if (*str) {
            if (char_to_escape[(:uchar)*str]) {
                genf("\\%c", char_to_escape[(:uchar)*str]);
                if (str[0] == ' ' && str[1]) {
                    genf("\"");
                    genlnf("\"");
                }
            } else {
                #assert(!pc_isprint(*str));
                genf("\\x%X", (:uchar)*str);
            }
            str++;
        }
    }

    genf("\"");
    if (multiline) {

        gen_indent--;
    }
}

gen_buf_pos(pbuf ^^char, pos SrcPos) {
    if (flag_nolinesync) {
        return;
    }
    buf ^char = *pbuf;
    buf_printf(buf, "\n#line %d ", pos.line);
    old_gen_buf := gen_buf;
    gen_buf = buf;
    gen_str(pos.name, false);
    buf = gen_buf;
    gen_buf = old_gen_buf;
    buf_printf(buf, "\n");
    *pbuf = buf;
}

gen_sync_pos(pos SrcPos) {
   if (gen_pos.line != pos.line || gen_pos.name != pos.name) {
        genlnf("#line %d", pos.line);
        if (gen_pos.name != pos.name) {
            genf("%s", " ");
            gen_str(pos.name, false);
        }
        gen_pos = pos
    }
}

cdecl_paren(str ^char, c char) ^char {
    return c && c != '[' ? strf("(%s)", str) : str;
}


cdecl_name(type ^Type) ^char{
   type_name ^char = type_names[type.kind];
    if (type_name) {
        return type_name;
    } else if (type.kind == PTYPE_TUPLE) {
        return strf("tuple%d", type.typeid);
    } else {
        #assert(type.sym);
        return get_gen_name(type.sym);
    }
}

type_to_cdecl(type ^Type, str ^char) ^char {
    switch (type.kind) {
    case PTYPE_PTR:
        return type_to_cdecl(type.base, cdecl_paren(strf("*%s", str), *str))
    case PTYPE_CONST:
        return type_to_cdecl(type.base, strf("const %s", cdecl_paren(str, *str)))
    case PTYPE_ARRAY:
        if (type.num_elems == 0) {
            return type_to_cdecl(type.base, cdecl_paren(strf("%s[]", str), *str))
        } else {
            return type_to_cdecl(type.base, cdecl_paren(strf("%s[%llu]", str, type.num_elems), *str))
        }
    case PTYPE_FUNC: {
        result ^char = NULL
        buf_printf(result, "%s(", cdecl_paren(strf("*%s", str), *str))
        if (type.t_func.num_params == 0) {
            buf_printf(result, "void")
        } else {
            for (i usize = 0; i < type.t_func.num_params; i++) {
                buf_printf(result, "%s%s", i == 0 ? "" : ", ", type_to_cdecl(type.t_func.params[i], ""))
            }
        }
        if (type.t_func.has_varargs) {
            buf_printf(result, ", ...")
        }
        buf_printf(result, ")")
        return type_to_cdecl(type.t_func.ret, result)
    }
    default:
        return strf("%s%s%s", cdecl_name(type), *str ? " " : "", str)
    }
}

gen_expr_str fn(expr ^Expr) ^char {
    temp ^char = gen_buf
    gen_buf = NULL
    gen_expr(expr)
    result ^char = gen_buf
    gen_buf = temp
    return result
}

gen_name_map PMap 

get_gen_name_or_default(ptr: ^void, default_name ^char) ^char {
    name := map_get(&gen_name_map, ptr);
    if (!name) {
        sym := get_resolved_sym(ptr);
        if (sym) {
            if (sym.external_name) {
                name = sym.external_name;
            } else if (sym.home_package.external_name) {
                external_name := sym.home_package.external_name;
                buf[256]char
                if (sym.kind == SYM_CONST) {
                    iptr : ^char = buf;
                    for (str := external_name; *str && iptr < buf + sizeof(buf) - 1; str++) {
                        iptr++;
                        *iptr = pc_toupper(*str);
                    }
                    *iptr = 0;
                    if (iptr < buf + sizeof(buf)) {
                        external_name = buf;
                    }
                }
                name = strf("%s%s", external_name, sym.name);
            } else {
                name = sym.name;
            }
        } else {
            #assert(default_name);
            name = default_name;
        }
        map_put(&gen_name_map, ptr, (: ^void)name);
    }
    return name;
}

get_gen_name(ptr ^void) ^char {
  error := "ERROR";
    name := get_gen_name_or_default(ptr, "error");
    #assert(name != error);
    return name;
}

typespec_to_cdecl(typespec ^Typespec, str ^char) ^char{
   if (!typespec) {
        return strf("void%s%s", *str ? " " : "", str);
    }
    switch (typespec.kind) {
    case TYPESPEC_NAME:
        return strf("%s%s%s", get_gen_name(typespec), *str ? " " : "", str);
    case TYPESPEC_PTR:
        return typespec_to_cdecl(typespec.base, cdecl_paren(strf("*%s", str), *str));
    case TYPESPEC_CONST:
        return typespec_to_cdecl(typespec.base, strf("const %s", cdecl_paren(str, *str)));
    case TYPESPEC_ARRAY:
        if (typespec.num_elems == 0) {
            return typespec_to_cdecl(typespec.base, cdecl_paren(strf("%s[]", str), *str));
        } else {
            return typespec_to_cdecl(typespec.base, cdecl_paren(strf("%s[%s]", str, gen_expr_str(typespec.num_elems)), *str));
        }
    case TYPESPEC_FUNC: {
        result ^char = NULL;
        buf_printf(result, "(*%s)(", str);
        if (typespec.ts_func.num_args == 0) {
            buf_printf(result, "void");
        } else {
            for (i usize = 0; i < typespec.ts_func.num_args; i++) {
                buf_printf(result, "%s%s", i == 0 ? "" : ", ", typespec_to_cdecl(typespec.ts_func.args[i], ""));
            }
        }
        if (typespec.ts_func.has_varargs) {
            buf_printf(result, ", ...");
        }
        buf_printf(result, ")");
        return typespec_to_cdecl(typespec.ts_func.ret, result);
    }
    default:
        #assert(0);
        return NULL;
    }
}

gen_func_decl(decl ^Decl) {
  #assert(decl.kind == DECL_FUNC);
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
    }
}

is_reachable(reachable int) bool {
    return flag_fullgen || reachable == REACHABLE_NATURAL
}

is_sym_reachable(sym ^Sym) bool {
    return is_reachable(sym.reachable);
}

is_tuple_reachable(type ^Type) bool {
    return is_reachable(get_reachable(type))
}

gen_forward_decls() {
   for (i := 0; i < buf_len(tuple_types); i++) {
        type := tuple_types[i];
        if (is_tuple_reachable(type)) {
            genlnf("typedef struct tuple%d tuple%d;", type.typeid, type.typeid);
        }
    }
    for (it := sorted_syms; it != buf_end(sorted_syms); it++) {
        sym := *it;
        decl := sym.decl;
        if (!decl || !is_sym_reachable(sym)) {
            continue;
        }
        if (is_decl_foreign(decl)) {
            continue;
        }
        switch (decl.kind) {
        case DECL_STRUCT:
        case DECL_UNION: {
            name := get_gen_name(sym);
            genlnf("typedef %s %s %s;", decl.kind == DECL_STRUCT ? "struct" : "union", name, name);
            break;
        }
        default:
            // Do nothing.
        }
    }
}

gen_aggregate_items(aggregate ^Aggregate) {
    gen_indent++;
    for (i usize = 0; i < aggregate.num_items; i++) {
        item := aggregate.items[i];
        if (item.kind == AGGREGATE_ITEM_FIELD) {
            for (j usize = 0; j < item.num_names; j++) {
                gen_sync_pos(item.pos);
                if (item.type.kind == TYPESPEC_ARRAY && !item.type.num_elems) {
                    genlnf("%s;", typespec_to_cdecl(new_typespec_ptr(item.pos, item.type.base), item.names[j]));
                } else {
                    genlnf("%s;", typespec_to_cdecl(item.type, item.names[j]));
                }
            }
        } else if (item.kind == AGGREGATE_ITEM_SUBAGGREGATE) {
            genlnf("%s {", item.subaggregate.kind == AGGREGATE_STRUCT ? "struct" : "union");
            gen_aggregate_items(item.subaggregate);
            if(item.name)
            {
                genlnf("}%s;", item.name );
            }
            else{
            genlnf("};");
        }
        } else {
            #assert(0);
        }
    }
    gen_indent--;
}

gen_aggregate(decl ^Decl) {
    #assert(decl.kind == DECL_STRUCT || decl.kind == DECL_UNION )
    if (decl.is_incomplete) {
        return;
    }
    genlnf("%s %s {", decl.kind == DECL_STRUCT ? "struct" : "union", get_gen_name(decl))
    gen_aggregate_items(decl.aggregate)
    genlnf("};")
}

gen_paren_expr(expr ^Expr) {
    genf("(")
    gen_expr(expr)
    genf(")")
}

gen_expr_compound(expr ^Expr) {
     expected_type := get_resolved_expected_type(expr);
    if (expected_type && !is_ptr_type(expected_type)) {
        genf("{");
    } else if (expr.compound.type) {
        genf("(%s){", typespec_to_cdecl(expr.compound.type, ""))
    } else {
        genf("(%s){", type_to_cdecl(get_resolved_type(expr), ""))
    }
    for (i usize = 0; i < expr.compound.num_fields; i++) {
        if (i != 0) {
            genf(", ")
        }
        field := expr.compound.fields[i]
        if (field.kind == FIELD_NAME) {
            genf(".%s = ", field.name)
        } else if (field.kind == FIELD_INDEX) {
            genf("[")
            gen_expr(field.index)
            genf("] = ")
        }
        gen_expr(field.init)
    }
    if (expr.compound.num_fields == 0) {
        genf("0")
    }
    genf("}")
}

typeid_kind_names ^[PNUM_TYPE_KINDS]char = {
    [PTYPE_NONE] = "TYPE_NONE",
    [PTYPE_VOID] = "TYPE_VOID",
    [PTYPE_BOOL] = "TYPE_BOOL",
    [PTYPE_CHAR] = "TYPE_CHAR",
    [PTYPE_UCHAR] = "TYPE_UCHAR",
    [PTYPE_SCHAR] = "TYPE_SCHAR",
    [PTYPE_SHORT] = "TYPE_SHORT",
    [PTYPE_USHORT] = "TYPE_USHORT",
    [PTYPE_INT] =  "TYPE_INT",
    [PTYPE_UINT] = "TYPE_UINT",
    [PTYPE_LONG] = "TYPE_LONG",
    [PTYPE_ULONG] = "TYPE_ULONG",
    [PTYPE_LLONG] = "TYPE_LLONG",
    [PTYPE_ULLONG] = "TYPE_ULLONG",
    [PTYPE_FLOAT] = "TYPE_FLOAT",
    [PTYPE_DOUBLE] = "TYPE_DOUBLE",
    [PTYPE_CONST] = "TYPE_CONST",
    [PTYPE_PTR] = "TYPE_PTR",
    [PTYPE_ARRAY] = "TYPE_ARRAY",
    [PTYPE_STRUCT] = "TYPE_STRUCT",
    [PTYPE_UNION] = "TYPE_UNION",
    [PTYPE_FUNC] = "TYPE_FUNC",
}

typeid_kind_name(type ^Type) ^char {
    if (type.kind < PNUM_TYPE_KINDS) {
        name := typeid_kind_names[type.kind];
        if (name) {
            return name;
        }
    }
    return "TYPE_NONE";
}

is_excluded_typeinfo(type ^Type) bool {
       while (type.kind == PTYPE_ARRAY || type.kind == PTYPE_CONST || type.kind == PTYPE_PTR) {
        type = type.base;
    }
    if (type.sym) {
        if (get_decl_note(type.sym.decl, str_intern("notypeinfo"))) {
            return true;
        } else {
            return !is_sym_reachable(type.sym);
        }
    } else if (type.kind == PTYPE_TUPLE) {
        return !is_tuple_reachable(type);
    } else {
        return !type.sym && (type.kind == PTYPE_STRUCT || type.kind == PTYPE_UNION);
    }
}

gen_typeid(type ^Type) {
    if (type.size == 0 || is_excluded_typeinfo(type)) {
        genf("TYPEID0(%d, %s)", type.typeid, typeid_kind_name(type));
    } else {
        genf("TYPEID(%d, %s, %s)", type.typeid, typeid_kind_name(type), type_to_cdecl(type, ""));
    }
}

gen_intrinsic(sym ^Sym, expr ^Expr) {
    type := get_resolved_type(expr.call.args[0])
    base := is_ptr_type(type) ? unqualify_type(type.base) : 0;
    key := base && is_aggregate_type(base) && base.t_aggregate.num_fields == 2 ? base.t_aggregate.fields[0].type : 0;
    val := base && is_aggregate_type(base) && base.t_aggregate.num_fields == 2 ? base.t_aggregate.fields[1].type : 0;
    if (sym.name == str_intern("va_copy") || sym.name == str_intern("va_start") || sym.name == str_intern("va_end")) {
        genf("%s(", sym.name);
        for (i int = 0; i < expr.call.num_args; i++) {
            if (i != 0) {
                genf(", ");
            }
            gen_expr(expr.call.args[i]);
        }
        genf(")");
    } else if (sym.name == str_intern("va_arg")) {
        #assert(expr.call.num_args == 2);
        gen_expr(expr.call.args[1]);
        genf(" = va_arg(");
        gen_expr(expr.call.args[0]);
        va_arg_type := get_resolved_type(expr.call.args[1]);
        genf(", %s)", type_to_cdecl(va_arg_type, ""));
    } else if (sym.name == str_intern("apush") || sym.name == str_intern("aputv") || sym.name == str_intern("adelv") ||
        sym.name == str_intern("agetvi") || sym.name == str_intern("agetvp") || sym.name == str_intern("agetv") ||
        sym.name == str_intern("asetcap") || sym.name == str_intern("afit") || sym.name == str_intern("acat") ||
        sym.name == str_intern("adeli") || sym.name == str_intern("aindexv") || sym.name == str_intern("asetlen")) {
        // (t, a, v)
        genf("%s(%s, (", sym.name, type_to_cdecl(base, ""));
        gen_expr(expr.call.args[0]);
        genf("), (");
        gen_expr(expr.call.args[1]);
        genf("))");
    } else if (sym.name == str_intern("adefault")) {
        // (t, tv, a, v)
        genf("%s(%s, %s, (", sym.name, type_to_cdecl(base, ""), type_to_cdecl(val, ""));
        gen_expr(expr.call.args[0]);
        genf("), (");
        gen_expr(expr.call.args[1]);
        genf("))");
    } else if (sym.name == str_intern("afill")) {
        // (t, a, v, n)
        genf("%s(%s, (", sym.name, type_to_cdecl(base, ""));
        gen_expr(expr.call.args[0]);
        genf("), (");
        gen_expr(expr.call.args[1]);
        genf("), (");
        gen_expr(expr.call.args[2]);
        genf("))");
    } else if (sym.name == str_intern("acatn") || sym.name == str_intern("adeln")) {
        genf("%s(%s, (", sym.name, type_to_cdecl(base, ""));
        gen_expr(expr.call.args[0]);
        genf("), (");
        gen_expr(expr.call.args[1]);
        genf("), (");
        gen_expr(expr.call.args[2]);
        genf("))");
    } else if (sym.name == str_intern("aindex") || sym.name == str_intern("ageti") || sym.name == str_intern("adel")) {
        genf("%s(%s, %s, (", sym.name, type_to_cdecl(base, ""), type_to_cdecl(key, ""));
        gen_expr(expr.call.args[0]);
        genf("), (");
        gen_expr(expr.call.args[1]);
        genf("))");
    } else if (sym.name == str_intern("agetp") || sym.name == str_intern("aget")) {
        genf("%s(%s, %s, %s, (", sym.name, type_to_cdecl(base, ""), type_to_cdecl(key, ""), type_to_cdecl(val, ""));
        gen_expr(expr.call.args[0]);
        genf("), (");
        gen_expr(expr.call.args[1]);
        genf("))");
    } else if (sym.name == str_intern("aput")) {
        genf("%s(%s, %s, (", sym.name, type_to_cdecl(base, ""), type_to_cdecl(key, ""));
        gen_expr(expr.call.args[0]);
        genf("), (");
        gen_expr(expr.call.args[1]);
        genf("), (");
        gen_expr(expr.call.args[2]);
        genf("))");
    } else if (sym.name == str_intern("ahdrsize") || sym.name == str_intern("ahdralign") || sym.name == str_intern("ahdr") ||
        sym.name == str_intern("alen") || sym.name == str_intern("acap") || sym.name == str_intern("afree") ||
        sym.name == str_intern("aclear") || sym.name == str_intern("apop")) {
        genf("%s(%s, (", sym.name, type_to_cdecl(base, ""));
        gen_expr(expr.call.args[0]);
        genf("))");
    } else if (sym.name == str_intern("anew")) {
        result_type := get_resolved_type(expr);
        #assert(is_ptr_type(result_type));
        genf("%s(%s, ", sym.name, type_to_cdecl(result_type.base, ""));
        gen_expr(expr.call.args[0]);
        genf(")");
    } else {
        fatal_error(expr.pos, "Call to unimplemented intrinsic %s", sym.name);
    }
}

gen_expr_new(expr ^Expr) {
    #assert(expr.kind == EXPR_NEW);
    type := get_resolved_type(expr);
    #assert(is_ptr_type(type));
    type_cdecl := type_to_cdecl(type, "");
    base_cdecl := type_to_cdecl(type.base, "");
    if (expr.e_new_expr.alloc) {
        if (expr.e_new_expr.len) {
            if (!expr.e_new_expr.arg) {
                genf("((%s)generic_alloc((Allocator *)(", type_cdecl);
                gen_expr(expr.e_new_expr.alloc);
                genf("), ");
                gen_expr(expr.e_new_expr.len);
                genf("* sizeof(%s), alignof(%s)))", base_cdecl, base_cdecl);
            } else {
                genf("((%s)generic_alloc_copy((Allocator *)(", type_cdecl);
                gen_expr(expr.e_new_expr.alloc);
                genf("), ");
                gen_expr(expr.e_new_expr.len);
                genf(" * sizeof(%s), alignof(%s), &(", base_cdecl, base_cdecl);
                gen_expr(expr.e_new_expr.arg);
                genf(")))");
            }
        } else {
            if (!expr.e_new_expr.arg) {
                genf("((%s)generic_alloc((Allocator *)(", type_cdecl);
                gen_expr(expr.e_new_expr.alloc);
                genf("), ");
                genf("sizeof(%s), alignof(%s)))", base_cdecl, base_cdecl);
            } else {
                genf("((%s)generic_alloc_copy((Allocator *)(", type_cdecl);
                gen_expr(expr.e_new_expr.alloc);
                genf("), ");
                genf("sizeof(%s), alignof(%s), &(", base_cdecl, base_cdecl, base_cdecl);
                gen_expr(expr.e_new_expr.arg);
                genf(")))");
            }
        }
    } else {
        if (expr.e_new_expr.len) {
            if (!expr.e_new_expr.arg) {
                genf("((%s)tls_alloc(", type_cdecl);
                gen_expr(expr.e_new_expr.len);
                genf(" * sizeof(%s), alignof(%s)))", base_cdecl, base_cdecl);
            } else {
                genf("((%s)alloc_copy(", type_cdecl);
                gen_expr(expr.e_new_expr.len);
                genf(" * sizeof(%s), alignof(%s), &(", base_cdecl, base_cdecl);
                gen_expr(expr.e_new_expr.arg);
                genf(")))");
            }
        } else {
            if (!expr.e_new_expr.arg) {
                genf("((%s)tls_alloc(sizeof(%s), alignof(%s)))", type_cdecl, base_cdecl, base_cdecl);
            } else {
                genf("((%s)alloc_copy(sizeof(%s), alignof(%s), &(", type_cdecl, base_cdecl, base_cdecl);
                gen_expr(expr.e_new_expr.arg);
                genf(")))");
            }
        }
    }
}


gen_expr(expr ^Expr) {
    type ^Type = NULL;
    conv := type_conv(expr);
    if (conv) {
        genf("(%s)(", type_to_cdecl(conv, ""));
    }
    gen_any := is_implicit_any(expr);
    if (gen_any) {
        type = get_resolved_type(expr);
        genf("(any){(%s[]){", type_to_cdecl(type, ""));
    }
    switch (expr.kind) {
    case EXPR_PAREN:
        genf("(");
        gen_expr(expr.paren.expr);
        genf(")")
    case EXPR_INT: {
        suffix_name := token_suffix_names[expr.int_lit.suffix];
        switch (expr.int_lit.mod) {
        case MOD_BIN:
        case MOD_HEX:
            genf("0x%llx%s", expr.int_lit.val, suffix_name)
        case MOD_OCT:
            genf("0%llo%s", expr.int_lit.val, suffix_name)
        case MOD_CHAR:
            gen_char((:char)expr.int_lit.val)
        default:
            genf("%llu%s", expr.int_lit.val, suffix_name)
        }
    }
    case EXPR_FLOAT: {
        is_double := expr.float_lit.suffix == SUFFIX_D;
        len := expr.float_lit.end - expr.float_lit.start;
        genf("%.*s%s", is_double ? len-1 : len, expr.float_lit.start, is_double ? "" : "f")
    }
    case EXPR_STR:
        gen_str(expr.str_lit.val, expr.str_lit.mod == MOD_MULTILINE)
    case EXPR_NAME:
        genf("%s", get_gen_name_or_default(expr, expr.name))
    case EXPR_CAST:
        genf("(%s)(", typespec_to_cdecl(expr.cast.type, ""));
        gen_expr(expr.cast.expr);
        genf(")")
    case EXPR_CALL: {
        sym := get_resolved_sym(expr.call.expr);
        if (is_intrinsic(sym)) {
            gen_intrinsic(sym, expr);
        } else {
            if (sym && sym.kind == SYM_TYPE) {
                genf("(%s)", get_gen_name(sym));
            } else {
                gen_expr(expr.call.expr);
            }
            genf("(");
            for (i := 0; i < expr.call.num_args; i++) {
                if (i != 0) {
                    genf(", ");
                }
                gen_expr(expr.call.args[i]);
            }
            genf(")");
        }
    }
    case EXPR_INDEX: {
        index_type := unqualify_type(get_resolved_type(expr.index.expr));
        if (is_aggregate_type(index_type)) {
            gen_expr(expr.index.expr);
            genf(".");
            i := get_resolved_val(expr.index.index).ll;
            genf("%s", index_type.t_aggregate.fields[i].name);
        } else {
            gen_expr(expr.index.expr);
            genf("[");
            gen_expr(expr.index.index);
            genf("]");
        }
    }
    case EXPR_FIELD: {
        sym := get_resolved_sym(expr);
        if (sym) {
            genf("(%s)", get_gen_name(sym));
        } else {
            gen_expr(expr.field.expr);
            field_type := unqualify_type(get_resolved_type(expr.field.expr));
            name := expr.field.name;
            genf("%s%s", field_type.kind == PTYPE_PTR ? "->" : ".", name);
        }
    }
    case EXPR_COMPOUND:
        gen_expr_compound(expr)
    case EXPR_UNARY:
        if(pc_strcmp(token_kind_name(expr.unary.op),  "^") == 0) {
            genf("%s(", "*");
        } else {
        genf("%s(", token_kind_name(expr.unary.op))
        }
        gen_expr(expr.unary.expr)
        genf(")")
    case EXPR_BINARY: {
        genf("(");
        left_promo := pointer_promo_type(expr.binary.left)
        if (left_promo) {
            genf("(%s)", type_to_cdecl(left_promo, ""))
        }
        gen_expr(expr.binary.left)
        genf(") %s (", token_kind_name(expr.binary.op))
        right_promo := pointer_promo_type(expr.binary.right)
        if (right_promo) {
            genf("(%s)", type_to_cdecl(right_promo, ""))
        }
        gen_expr(expr.binary.right)
        genf(")")
    }
    case EXPR_TERNARY:
        genf("(");
        gen_expr(expr.ternary.cond);
        genf(" ? ");
        gen_expr(expr.ternary.then_expr);
        genf(" : ");
        gen_expr(expr.ternary.else_expr);
        genf(")");
    case EXPR_SIZEOF_EXPR:
        genf("sizeof(");
        gen_expr(expr.sizeof_expr);
        genf(")")
    case EXPR_SIZEOF_TYPE:
        genf("sizeof(%s)", typespec_to_cdecl(expr.sizeof_type, ""))
    case EXPR_ALIGNOF_EXPR:
        genf("alignof(%s)", type_to_cdecl(get_resolved_type(expr.alignof_expr), ""))
    case EXPR_ALIGNOF_TYPE:
        genf("alignof(%s)", typespec_to_cdecl(expr.alignof_type, ""))
    case EXPR_TYPEOF_EXPR: {
        typeof_expr_type := get_resolved_type(expr.typeof_expr);
        #assert(typeof_expr_type.typeid);
        gen_typeid(typeof_expr_type)
    }
    case EXPR_TYPEOF_TYPE: {
        typeof_type := get_resolved_type(expr.typeof_type);
        #assert(typeof_type.typeid);
        gen_typeid(typeof_type)
    }
    case EXPR_OFFSETOF:
        genf("offsetof(%s, %s)", typespec_to_cdecl(expr.offsetof_field.type, ""), expr.offsetof_field.name)
    case EXPR_MODIFY:
        if (!expr.modify.post) {
            genf("%s", token_kind_name(expr.modify.op));
        }
        gen_paren_expr(expr.modify.expr);
        if (expr.modify.post) {
            genf("%s", token_kind_name(expr.modify.op));
        }
    case EXPR_NEW:
        gen_expr_new(expr);
    default:
        #assert(0);
    }
    if (gen_any) {
        genf("}, ");
        gen_typeid(type);
        genf("}");
    }
    if (conv) {
        genf(")");
    }
}

 gen_stmt_block(block StmtList) {
    genf("{");
    gen_indent++;
    for (i := 0; i < block.num_stmts; i++) {
        gen_stmt(block.stmts[i]);
    }
    gen_indent--;
    genlnf("}");
}

gen_simple_stmt(stmt ^Stmt) {
  switch (stmt.kind) {
    case STMT_CF_RETURN:
        genf("return")
    case STMT_EXPR:
        gen_expr(stmt.expr)
    case STMT_INIT:
        if (stmt.init.type) {
            init_typespec := stmt.init.type;
            incomplete := is_incomplete_array_typespec(stmt.init.type);
            if (incomplete && !stmt.init.expr) {
                init_type := get_resolved_type(stmt.init.type);
                genf("%s = 0", type_to_cdecl(type_decay(init_type), stmt.init.name));
            } else {
                if (incomplete && is_ptr_type(get_resolved_type(stmt.init.expr))) {
                    genf("%s", type_to_cdecl(get_resolved_type(stmt.init.expr), stmt.init.name));
                    if (stmt.init.expr) {
                        if (!stmt.init.is_undef) {
                            genf(" = ");
                            gen_expr(stmt.init.expr);
                        }
                    } else {
                        genf(" = {0}");
                    }
                } else {
                    if (incomplete) {
                        size := new_expr_int(init_typespec.pos, get_resolved_type(stmt.init.expr).num_elems, 0, 0);
                        init_typespec = new_typespec_array(init_typespec.pos, init_typespec.base, size);
                    }
                    genf("%s", typespec_to_cdecl(stmt.init.type, stmt.init.name));
                    if (stmt.init.expr) {
                        if (!stmt.init.is_undef) {
                            genf(" = ");
                            gen_expr(stmt.init.expr);
                        }
                    } else if (!stmt.init.is_undef) {
                        genf(" = {0}");
                    }
                }
            }
        } else {
            genf("%s = ", type_to_cdecl(unqualify_type(get_resolved_type(stmt.init.expr)), stmt.init.name));
            gen_expr(stmt.init.expr);
        }
    case STMT_ASSIGN: {
        promo_type := pointer_promo_type(stmt.assign.left);
        if (promo_type) {
            #assert(stmt.assign.op == TOKEN_ADD_ASSIGN);
            left_type := get_resolved_type(stmt.assign.left);
            if (stmt.assign.left.kind == EXPR_NAME) {
                name := get_gen_name_or_default(stmt.assign.left, stmt.assign.left.name);
                genf("%s = (char *)(%s) + ", name, name);
                gen_expr(stmt.assign.right);
            } else {
                // TODO: this is an ugly codegen template that needs to avoid both illegal aliasing and multiple evaluation.
                // However, 99.9% of use cases will use a name on the left-hand side, and we handle that cleanly.
                genf("do { %s = (%s)&(", type_to_cdecl(type_ptr(left_type), "__pp"), type_to_cdecl(type_ptr(left_type), ""));
                gen_expr(stmt.assign.left);
                genf("); *__pp = (%s)(*(char **)__pp + ", type_to_cdecl(left_type, ""));
                gen_expr(stmt.assign.right);
                genf("); } while(0)");
            }
        } else {
            gen_expr(stmt.assign.left);
            genf(" %s ", token_kind_name(stmt.assign.op));
            gen_expr(stmt.assign.right);
        }
    }
    default:
        #assert(0);
    }
}

is_char_lit(expr ^Expr) bool {
    return expr.kind == EXPR_INT && expr.int_lit.mod == MOD_CHAR
}

gen_stmt(stmt ^Stmt) {
    gen_sync_pos(stmt.pos);
    switch (stmt.kind) {
    case STMT_RETURN:
        genlnf("return");
        if (stmt.expr) {
            genf(" ");
            gen_expr(stmt.expr);
        }
        genf(";")
    case STMT_BREAK:
        genlnf("break;")
    case STMT_CONTINUE:
        genlnf("continue;");
    case STMT_BLOCK:
        genln();
        gen_stmt_block(stmt.block)
    case STMT_NOTE: {
        note := stmt.note;
        if (note.name == assert_name) {
            genlnf("assert(");
            #assert(note.num_args == 1);
            gen_expr(note.args[0].expr);
            genf(");");
        } else if (note.name == foreign_name) {
            preamble_name := str_intern("preamble");
            postamble_name := str_intern("postamble");
            for (i := 0; i < note.num_args; i++) {
                name := note.args[i].name;
                expr := note.args[i].expr;
                if (expr.kind != EXPR_STR) {
                    fatal_error(expr.pos, "#foreign argument must be a string");
                }
                str := expr.str_lit.val;
                if (name == preamble_name) {
                    gen_buf_pos(&gen_preamble_buf, note.args[i].pos);
                    buf_printf(gen_preamble_buf, "%s\n", str);
                } else if (name == postamble_name) {
                    gen_buf_pos(&gen_postamble_buf, note.args[i].pos);
                    buf_printf(gen_postamble_buf, "%s\n", str);
                }
            }
        }
    }
    case STMT_IF:
        if (stmt.if_stmt.init) {
            genlnf("{");
            gen_indent++;
            gen_stmt(stmt.if_stmt.init);
        }
        gen_sync_pos(stmt.pos);
        genlnf("if (");
        if (stmt.if_stmt.cond) {
            gen_expr(stmt.if_stmt.cond);
        } else {
            genf("%s", stmt.if_stmt.init.init.name);
        }
        genf(") ");
        gen_stmt_block(stmt.if_stmt.then_block);
        for (i := 0; i < stmt.if_stmt.num_elseifs; i++) {
            elseif := stmt.if_stmt.elseifs[i];
            genf(" else if (");
            gen_expr(elseif.cond);
            genf(") ");
            gen_stmt_block(elseif.block);
        }
        if (stmt.if_stmt.else_block.stmts) {
            genf(" else ");
            gen_stmt_block(stmt.if_stmt.else_block);
        } else {
            complete_note := get_stmt_note(stmt, complete_name);
            if (complete_note) {
                genf(" else {");
                gen_indent++;
                gen_sync_pos(complete_note.pos);
                genlnf("assert(\"@complete if/elseif chain failed to handle case\" && 0);");
                gen_indent--;
                genlnf("}");
            }
        }
        if (stmt.if_stmt.init) {
            gen_indent--;
            genlnf("}");
        }
    case STMT_WHILE:
        genlnf("while (");
        gen_expr(stmt.while_stmt.cond);
        genf(") ");
        gen_stmt_block(stmt.while_stmt.block)
    case STMT_DO_WHILE:
        genlnf("do ");
        gen_stmt_block(stmt.while_stmt.block);
        genf(" while (");
        gen_expr(stmt.while_stmt.cond);
        genf(");")
    case STMT_FOR:
        genlnf("for (");
        if (stmt.for_stmt.init) {
            gen_simple_stmt(stmt.for_stmt.init);
        }
        genf(";");
        if (stmt.for_stmt.cond) {
            genf(" ");
            gen_expr(stmt.for_stmt.cond);
        }
        genf(";");
        if (stmt.for_stmt.next) {
            genf(" ");
            gen_simple_stmt(stmt.for_stmt.next);
        }
        genf(") ");
        gen_stmt_block(stmt.for_stmt.block)
    case STMT_SWITCH: {
        genlnf("switch (");
        gen_expr(stmt.switch_stmt.expr);
        genf(") {");
        has_default := false;
        for (i := 0; i < stmt.switch_stmt.num_cases; i++) {
            switch_case := stmt.switch_stmt.cases[i];
            for (j := 0; j < switch_case.num_patterns; j++) {
                pattern := switch_case.patterns[j];
                if (pattern.end) {
                    start_val := get_resolved_val(pattern.start);
                    end_val := get_resolved_val(pattern.end);
                    if (is_char_lit(pattern.start) && is_char_lit(pattern.end)) {
                        genln();
                        for (c := (:int)start_val.ll; c <= (:int)end_val.ll; c++) {
                            genf("case ");
                            gen_char(c);
                            genf(": ");
                        } 
                    } else {
                        genlnf("// ");
                        gen_expr(pattern.start);
                        genf("...");
                        gen_expr(pattern.end);
                        genln();
                        for (ll := start_val.ll; ll <= end_val.ll; ll++) {
                            genf("case %lld: ", ll);
                        }
                    }
                } else {
                    genlnf("case ");
                    gen_expr(pattern.start);
                    genf(":");
                }
            }
            if (switch_case.is_default) {
                has_default = true;
                genlnf("default:");
            }
            genf(" ");
            genf("{");
            gen_indent++;
            block := switch_case.block;
            for (j := 0; j < block.num_stmts; j++) {
                gen_stmt(block.stmts[j]);
            }
            genlnf("break;");
            gen_indent--;
            genlnf("}");
        }
        if (!has_default) {
            note := get_stmt_note(stmt, complete_name);
            if (note) {
                genlnf("default:");
                gen_indent++;
                genlnf("assert(\"@complete switch failed to handle case\" && 0);");
                genlnf("break;");
                gen_indent--;
            }
        }
        genlnf("}")
    }
    case STMT_LABEL:
        genlnf("%s: ;", stmt.label)
    case STMT_GOTO:
        genlnf("goto %s;", stmt.label)
    default:
        genln();
        gen_simple_stmt(stmt);
        genf(";");
    }
}

gen_decl(sym ^Sym) {
      decl := sym.decl;
    if (!decl || is_decl_foreign(decl)) {
        return;
    }
    gen_sync_pos(decl.pos);
    switch (decl.kind) {
    case DECL_CONST:
        genlnf("#define %s (", get_gen_name(sym));
        if (decl.const_decl.type) {
            genf("(%s)(", typespec_to_cdecl(decl.const_decl.type, ""));
        }
        gen_expr(decl.const_decl.expr);
        if (decl.const_decl.type) {
            genf(")");
        }
        genf(")")
    case DECL_VAR:
        if (is_decl_threadlocal(decl)) {
            genlnf("THREADLOCAL");
        }
        genlnf("extern ");
        if (decl.d_var.type && !is_incomplete_array_typespec(decl.d_var.type)) {
            genf("%s", typespec_to_cdecl(decl.d_var.type, get_gen_name(sym)));
        } else {
            genf("%s", type_to_cdecl(sym.type, get_gen_name(sym)));
        }
        genf(";")
    case DECL_FUNC:
        gen_func_decl(decl);
        genf(";")
    case DECL_STRUCT:
    case DECL_UNION:
        gen_aggregate(decl)
    case DECL_TYPEDEF:
        genlnf("typedef %s;", typespec_to_cdecl(decl.typedef_decl.type, get_gen_name(sym)))
    case DECL_ENUM:
        if (decl.enum_decl.type) {
            genlnf("typedef %s;", typespec_to_cdecl(decl.enum_decl.type, get_gen_name(decl)));
        } else {
            genlnf("typedef int %s;", get_gen_name(decl));
        }
    case DECL_IMPORT:
        // Do nothing
    default:
        #assert(0)
    }
    genln()
}

gen_sorted_decls() {
    for (i int = 0; i < buf_len(tuple_types); i++) {
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
    }
    for (i usize = 0; i < buf_len(sorted_syms); i++) {
        if (sorted_syms[i].reachable == REACHABLE_NATURAL) {
            gen_decl(sorted_syms[i]);
        }
    }
}

gen_defs() {
    for (it := sorted_syms; it != buf_end(sorted_syms); it++) {
        sym := *it;
        decl := sym.decl;
        if (sym.state != SYM_RESOLVED || !decl || decl.is_incomplete || sym.reachable != REACHABLE_NATURAL) {
            continue;
        }
        if (decl.kind == DECL_FUNC) {
            foreign := is_decl_foreign(decl);
            buf := gen_buf;
            if (foreign) {
                gen_buf = NULL;
            }
            if (get_decl_note(decl, inline_name)) {
                genlnf("INLINE");
            }
            if (get_decl_note(decl, str_intern("noinline"))) {
                genlnf("NOINLINE");
            }
            gen_func_decl(decl);
            genf(" ");
      
            gen_stmt_block(decl.d_func.block);
            genln();
            if (foreign) {
                gen_buf = buf;
            }
        } else if (decl.kind == DECL_VAR) {
            if (is_decl_threadlocal(decl)) {
                genlnf("THREADLOCAL");
            }
            if (decl.d_var.type && !is_incomplete_array_typespec(decl.d_var.type)) {
                genlnf("%s", typespec_to_cdecl(decl.d_var.type, get_gen_name(sym)));
            } else {
                genlnf("%s", type_to_cdecl(sym.type, get_gen_name(sym)));
            }
            if (decl.d_var.expr) {
                genf(" = ");
                gen_expr(decl.d_var.expr);
            }
            genf(";");
        }
    }
}

gen_foreign_headers_map PMap
gen_foreign_headers_buf ^^char

add_foreign_header(name ^char) {
    name = str_intern(name);
    if (!map_get(&gen_foreign_headers_map, name)) {
        map_put(&gen_foreign_headers_map, name, (: ^void )1);
        buf_push(gen_foreign_headers_buf, name);
    }
}

gen_foreign_sources_buf  ^^char

add_foreign_source(name ^char) {
    buf_push(gen_foreign_sources_buf, str_intern(name));
}

gen_include(path ^char) {
    genlnf("#include ");
    if (*path == '<') {
        genf("%s", path);
    } else {
        gen_str(path, false);
    }
}

gen_foreign_headers() {
    if (gen_foreign_headers_buf) {
        genlnf("// Foreign header files");
        for (i usize = 0; i < buf_len(gen_foreign_headers_buf); i++) {
            gen_include(gen_foreign_headers_buf[i]);
        }
    }
}

gen_foreign_sources() {
    for (i usize = 0; i < buf_len(gen_foreign_sources_buf); i++) {
        gen_include(gen_foreign_sources_buf[i]);
    }
}

gen_sources_buf ^^char

put_include_path(path[PMAX_PATH]char, package ^Package, filename ^char) {
    if (*filename == '<') {
        path_copy(path, filename);
    } else {
        path_copy(path, package.full_path);
        path_join(path, filename);
        path_absolute(path);
    }
}

preprocess_package(package ^Package) {
   if (!package.external_name) {
        external_name ^char = NULL;
        for (ptr := package.path; *ptr; ptr++) {
            buf_printf(external_name, "%c", *ptr == '/' ? '_' : *ptr);
        }
        buf_printf(external_name, "_");
        package.external_name = str_intern(external_name);
    }
    header_name := str_intern("header");
    source_name := str_intern("source");
    preamble_name := str_intern("preamble");
    postamble_name := str_intern("postamble");
    for (i usize = 0; i < package.num_decls; i++) {
        decl := package.decls[i];
        if (decl.kind != DECL_NOTE) {
            continue;
        }
        note := decl.note;
        if (note.name == foreign_name) {
            for (k usize = 0; k < note.num_args; k++) {
                arg := note.args[k];
                expr := note.args[k].expr;
                if (expr.kind != EXPR_STR) {
                    fatal_error(decl.pos, "#foreign argument must be a string");
                }
                str := expr.str_lit.val;
                if (arg.name == header_name) {
                    path[PMAX_PATH]char
                    put_include_path(path, package, str);
                    add_foreign_header(path);
                } else if (arg.name == source_name) {
                    path[PMAX_PATH]char
                    put_include_path(path, package, str);
                    add_foreign_source(path);
                } else if (arg.name == preamble_name) {
                    gen_buf_pos(&gen_preamble_buf, arg.pos);
                    buf_printf(gen_preamble_buf, "%s\n", str);
                } else if (arg.name == postamble_name) {
                    gen_buf_pos(&gen_postamble_buf, arg.pos);
                    buf_printf(gen_postamble_buf, "%s\n", str);
                } else {
                    fatal_error(decl.pos, "Unknown #foreign named argument '%s'", arg.name);
                }
            }
        }
    }
}

preprocess_packages() {
    for (i usize = 0; i < buf_len(package_list); i++) {
        preprocess_package(package_list[i]);
    }
}

gen_typeinfo_header(kind ^char, type ^Type) {  
    if (type_sizeof(type) == 0) {
        genf("&(GENTypeInfo){%s, .size = 0, .align = 0", kind);
    } else {
        ctype := type_to_cdecl(type, "");
        genf("&(GENTypeInfo){%s, .size = sizeof(%s), .align = alignof(%s)", kind, ctype, ctype);
    }
}

gen_typeinfo_fields(type ^Type) {
    gen_indent++;
    for (i usize = 0; i < type.t_aggregate.num_fields; i++) {
        field := type.t_aggregate.fields[i];
        genlnf("{");
        gen_str(field.name, false);
        genf(", .type = ");
        gen_typeid(field.type);
        genf(", .offset = offsetof(%s, %s)},", get_gen_name(type.sym), field.name);
    }
    gen_indent--;
}

/*#define CASE(kind, name) \
    case kind: \
        genf("&(TypeInfo){" #kind ", .size = sizeof(" #name "), .align = sizeof(" #name "), .name = "); \
        gen_str(#name, false); \
        genf("},"); \
        break;*/

gen_typeinfo(type ^Type) {
    switch (type.kind) {
    /*CASE(TYPE_BOOL, bool)
    CASE(TYPE_CHAR, char)
    CASE(TYPE_UCHAR, uchar)
    CASE(TYPE_SCHAR, schar)
    CASE(TYPE_SHORT, short)
    CASE(TYPE_USHORT, ushort)
    CASE(TYPE_INT, int)
    CASE(TYPE_UINT, uint)
    CASE(TYPE_LONG, long)
    CASE(TYPE_ULONG, ulong)
    CASE(TYPE_LLONG, llong)
    CASE(TYPE_ULLONG, ullong)
    CASE(TYPE_FLOAT, float)
    CASE(TYPE_DOUBLE, double)*/
   /* case PTYPE_BOOL:
        genf("&(GENTypeInfo){\" TYPE_BOOL \", .size = sizeof(\" bool \"), .align = sizeof(\" bool \"), .name = "); 
        gen_str("bool", false); 
        genf("},"); 
         case PTYPE_CHAR:
        genf("&(GENTypeInfo){\" TYPE_CHAR \", .size = sizeof(\" char \"), .align = sizeof(\" char \"), .name = "); 
        gen_str("char", false); 
        genf("},"); 
         case PTYPE_UCHAR:
        genf("&(GENTypeInfo){\" TYPE_UCHAR \", .size = sizeof(\" uchar \"), .align = sizeof(\" uchar \"), .name = "); 
        gen_str("uchar", false); 
        genf("},"); 
         case PTYPE_SCHAR:
        genf("&(TypeInfo){\" TYPE_SCHAR \", .size = sizeof(\" schar \"), .align = sizeof(\" schar \"), .name = "); 
        gen_str("schar", false); 
        genf("},"); 
         case PTYPE_SHORT:
        genf("&(TypeInfo){\" TYPE_SHORT \", .size = sizeof(\" short \"), .align = sizeof(\" short \"), .name = "); 
        gen_str("short", false); 
        genf("},"); 
         case PTYPE_USHORT:
        genf("&(TypeInfo){\" TYPE_USHORT \", .size = sizeof(\" ushort \"), .align = sizeof(\" ushort \"), .name = "); 
        gen_str("ushort", false); 
        genf("},"); 
         case PTYPE_INT:
        genf("&(TypeInfo){\" TYPE_INT \", .size = sizeof(\" int \"), .align = sizeof(\" int \"), .name = "); 
        gen_str("int", false); 
        genf("},"); 
         case PTYPE_UINT:
        genf("&(TypeInfo){\" TYPE_UINT \", .size = sizeof(\" uint \"), .align = sizeof(\" uint \"), .name = "); 
        gen_str("uint", false); 
        genf("},");  
        case PTYPE_LONG:
        genf("&(TypeInfo){\" TYPE_LONG \", .size = sizeof(\" long \"), .align = sizeof(\" long \"), .name = "); 
        gen_str("long", false); 
        genf("},"); 
         case PTYPE_ULONG:
        genf("&(TypeInfo){\" TYPE_ULONG \", .size = sizeof(\" ulong \"), .align = sizeof(\" ulong \"), .name = "); 
        gen_str("ulong", false); 
        genf("},"); 
         case PTYPE_LLONG:
        genf("&(TypeInfo){\" TYPE_LLONG \", .size = sizeof(\" llong \"), .align = sizeof(\" llong \"), .name = "); 
        gen_str("llong", false); 
        genf("},"); 
         case PTYPE_ULLONG:
        genf("&(TypeInfo){\" TYPE_ULLONG \", .size = sizeof(\" ullong \"), .align = sizeof(\" ullong \"), .name = "); 
        gen_str("ullong", false); 
        genf("},"); 
         case PTYPE_FLOAT:
        genf("&(TypeInfo){\" TYPE_FLOAT \", .size = sizeof(\" float \"), .align = sizeof(\" float \"), .name = "); 
        gen_str("float", false); 
        genf("},"); 
         case PTYPE_DOUBLE:
        genf("&(TypeInfo){\" TYPE_DOUBLE \", .size = sizeof(\" double \"), .align = sizeof(\" double \"), .name = "); 
        gen_str("double", false); 
        genf("},"); 
    case PTYPE_VOID:
        genf("&(TypeInfo){TYPE_VOID, .name = \"void\", .size = 0, .align = 0},")
    case PTYPE_PTR:
        genf("&(TypeInfo){TYPE_PTR, .size = sizeof(void *), .align = alignof(void *), .base = ");
        gen_typeid(type.base);
        genf("},")
    case PTYPE_CONST:
        gen_typeinfo_header("TYPE_CONST", type);
        genf(", .base = ");
        gen_typeid(type.base);
        genf("},")
    case PTYPE_ARRAY:
        if (is_incomplete_array_type(type)) {
            genf("NULL, // Incomplete array type");
        } else {
            gen_typeinfo_header("TYPE_ARRAY", type);
            genf(", .base = ");
            gen_typeid(type.base);
            genf(", .count = %d},", type.num_elems);
        }
    case PTYPE_STRUCT:
    case PTYPE_UNION:
       gen_typeinfo_header(type.kind == PTYPE_STRUCT ? "TYPE_STRUCT" : "TYPE_UNION", type);
        genf(", .name = ");
        gen_str(get_gen_name(type.sym), false);
        genf(", .num_fields = %d, .fields = (TypeFieldInfo[]) {", type.t_aggregate.num_fields);
        gen_typeinfo_fields(type);
        genlnf("}},");
        genlnf("NULL,")
    case PTYPE_FUNC:
        genf("NULL, // Func")
    case PTYPE_ENUM:
        genf("NULL, // Enum")
    case PTYPE_INCOMPLETE:
        genf("NULL, // Incomplete: %s", get_gen_name(type.sym))*/
    default:
        genf("NULL, // Unhandled")
    }
}

gen_typeinfos() {
   /* genlnf("#define TYPEID0(index, kind) ((ullong)(index) | ((ullong)(kind) << 24))");
    genlnf("#define TYPEID(index, kind, ...) ((ullong)(index) | ((ullong)sizeof(__VA_ARGS__) << 32) | ((ullong)(kind) << 24))");
    genln();
    if (flag_notypeinfo) {
        genlnf("int num_typeinfos;");
        genlnf("const TypeInfo **typeinfos;");
    } else {
        num_typeinfos int = next_typeid;
        genlnf("const TypeInfo *typeinfo_table[%d] = {", num_typeinfos);
        gen_indent++;
        for (typeid int = 0; typeid < num_typeinfos; typeid++) {
            genlnf("[%d] = ", typeid);
            type ^Type = get_type_from_typeid(typeid);
            if (type && !is_excluded_typeinfo(type)) {
                gen_typeinfo(type);
            } else {
                genf("NULL, // No associated type");
            }
        }
        gen_indent--;
        genlnf("};");
        genln();
        genlnf("int num_typeinfos = %d;", num_typeinfos);
        genlnf("const TypeInfo **typeinfos = (const TypeInfo **)typeinfo_table;");
    }*/
}

gen_package_external_names() {
    for (i usize = 0; i < buf_len(package_list); i++) {
    }
}

gen_preamble() {
    if (gen_preamble_buf) {
        genlnf("%s", gen_preamble_buf);
    }
}

gen_postamble() {
    if (gen_postamble_buf) {
        genlnf("%s", gen_postamble_buf);
    }
}

common_buf ^char = 
"""#include <io.h>
#include <errno.h>
#include <memoryapi.h>
#include <stdio.h>

#include <windows.h>

#ifndef MAX_PATH
#if defined _MAX_PATH
#define MAX_PATH _MAX_PATH
#elif defined PATH_MAX
#define MAX_PATH PATH_MAX
#else
#error "No suitable MAX_PATH surrogate"
#endif
#endif

typedef struct DirListIter {
    bool valid;
    bool error;

    char base[MAX_PATH];
    char name[MAX_PATH];
    size_t size;
    bool is_dir;

    void *handle;
} DirListIter;

void path_normalize(char *path) {
    char *ptr;
    for (ptr = path; *ptr; ptr++) {
        if (*ptr == '\\') {
            *ptr = '/';
        }
    }
    if (ptr != path && ptr[-1] == '/') {
        ptr[-1] = 0;
   }
}

void path_copy(char path[MAX_PATH], const char *src ) {
    strncpy(path, src, MAX_PATH);
    path[MAX_PATH - 1] = 0;
    path_normalize(path);
}

void path_absolute(char path[MAX_PATH]) {
    char rel_path[MAX_PATH];
    path_copy(rel_path, path);
    _fullpath(path, rel_path, MAX_PATH);
}

bool dir_excluded(DirListIter *iter) {
    return iter->valid && (strcmp(iter->name, ".") == 0 || strcmp(iter->name, "..") == 0);
}

void path_join(char path[MAX_PATH], const char *src) {
    char *ptr = path + strlen(path);
    if (ptr != path && ptr[-1] == '/') {
        ptr--;
    }
    if (*src == '/') {
        src++;
    }
    snprintf(ptr, path + MAX_PATH - ptr, "/%%s", src);
}

void dir_list_free(DirListIter *iter) {
    if (iter->valid) {
        _findclose((intptr_t)iter->handle);
        iter->valid = false;
        iter->error = false;
    }
}

void dir__update(DirListIter *iter, bool done, struct _finddata_t *fileinfo) {
    iter->valid = !done;
    iter->error = done && errno != ENOENT;
    if (!done) {
        iter->size = fileinfo->size;
        memcpy(iter->name, fileinfo->name, sizeof(iter->name) - 1);
        iter->name[MAX_PATH - 1] = 0;
        iter->is_dir = fileinfo->attrib & _A_SUBDIR;
    }
}

void dir_list_next(DirListIter *iter) {
    if (!iter->valid) {
        return;
    }
    do {
        struct _finddata_t fileinfo;
        int result = _findnext((intptr_t)iter->handle, &fileinfo);
        dir__update(iter, result != 0, &fileinfo);
        if (result != 0) {
            dir_list_free(iter);
          return;
        }
    } while (dir_excluded(iter));
}

void dir_list(DirListIter *iter, const char *path) {
    memset(iter, 0, sizeof(*iter));
    path_copy(iter->base, path);
    char filespec[MAX_PATH];
    path_copy(filespec, path);
    path_join(filespec, "*");
    struct _finddata_t fileinfo;
    intptr_t handle = _findfirst(filespec, &fileinfo);
    iter->handle = (void *)handle;
    dir__update(iter, handle == -1, &fileinfo);
    if (dir_excluded(iter)) {
        dir_list_next(iter);
    }
}
#define MAX(x, y) ((x) >= (y) ? (x) : (y))

#define CLAMP_MIN(x, min) MAX(x, min)

#define IS_POW2(x) (((x) != 0) && ((x) & ((x)-1)) == 0)\n
void *xcalloc(size_t num_elems, size_t elem_size) {
    void *ptr = calloc(num_elems, elem_size);
    
   if (!ptr) {
        
        exit(1);
    }
    return ptr; }

void *xrealloc(void *ptr, size_t num_bytes) {
    ptr = realloc(ptr, num_bytes);
    if (!ptr) {
        
       exit(1);
    }
    return ptr;
}

void *xmalloc(size_t num_bytes) {
    void *ptr = malloc(num_bytes);
    if (!ptr) {
       
        exit(1);
    }
    return ptr;
}

 typedef struct BufHdr {
    size_t len;
    size_t cap;
    char buf[];
} BufHdr;

#define buf__hdr(b) ((BufHdr *)((char *)(b) - offsetof(BufHdr, buf)))

#define buf_len(b) ((b) ? buf__hdr(b)->len : 0)
#define buf_cap(b) ((b) ? buf__hdr(b)->cap : 0)
#define buf_end(b) ((b) + buf_len(b))
#define buf_sizeof(b) ((b) ? buf_len(b)*sizeof(*b) : 0)

#define buf_free(b) ((b) ? (free(buf__hdr(b)), (b) = NULL) : 0)
#define buf_fit(b, n) ((n) <= buf_cap(b) ? 0 : ((b) = buf__grow((b), (n), sizeof(*(b)))))
#define buf_clear(b) ((b) ? buf__hdr(b)->len = 0 : 0)


#define buf_push(b, ...) (buf_fit((b), 1 + buf_len(b)), (b)[buf__hdr(b)->len++] = (__VA_ARGS__))
#define buf_printf(b, ...) ((b) = buf__printf((b), __VA_ARGS__))

void *buf__grow(const void *buf, size_t new_len, size_t elem_size) {
    assert(buf_cap(buf) <= (SIZE_MAX - 1)/2);
    size_t new_cap = CLAMP_MIN(2*buf_cap(buf), MAX(new_len, 16));
    assert(new_len <= new_cap);
    assert(new_cap <= (SIZE_MAX - offsetof(BufHdr, buf))/elem_size);
    size_t new_size = offsetof(BufHdr, buf) + new_cap*elem_size;
    BufHdr *new_hdr;
    if (buf) {
        new_hdr = xrealloc(buf__hdr(buf), new_size);
    } else {
        new_hdr = xmalloc(new_size);
        new_hdr->len = 0;
    }   
    new_hdr->cap = new_cap;
    return new_hdr->buf;
}

char *buf__printf(char *buf, const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    size_t cap = buf_cap(buf) - buf_len(buf);
    size_t n = 1 + vsnprintf(buf_end(buf), cap, fmt, args);
    va_end(args);
    if (n > cap) {
        buf_fit(buf, n + buf_len(buf));
        va_start(args, fmt);
        size_t new_cap = buf_cap(buf) - buf_len(buf);
        n = 1 + vsnprintf(buf_end(buf), new_cap, fmt, args);
        assert(n <= new_cap);
        va_end(args);
    }
    buf__hdr(buf)->len += n - 1;
    return buf;
}
int gen_indent;
char *gen_buf = NULL; 
#define genf(...) buf_printf(gen_buf, __VA_ARGS__)

#define genlnf(...) (genln(), genf(__VA_ARGS__))

void genln(void) { genf("\n%%.*s", gen_indent * 4,"                                                               "); }"""

gen_common_ds() {
    genlnf(common_buf);

}

gen_all() {
    preprocess_packages()
    gen_buf = NULL
    //genlnf("#include <windows.h>")
    gen_foreign_headers()
    genln()
    gen_common_ds()
    genln()
    gen_forward_decls()
    genln()
    gen_sorted_decls()
    gen_typeinfos()
    gen_defs()
    gen_foreign_sources()
    genln()
    gen_postamble()
    buf := gen_buf
    gen_buf = NULL
    gen_preamble()
    genf("%s", buf)
}


