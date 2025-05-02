SymKind enum {
    SYM_NONE,
    SYM_VAR,
    SYM_CONST,
    SYM_FUNC,
    SYM_TYPE,
    SYM_PACKAGE,
}

SymState enum {
    SYM_UNRESOLVED,
    SYM_RESOLVING,
    SYM_RESOLVED,
} 

Sym struct {
    name ^char 
    home_package ^Package
    kind SymKind 
    state SymState 
    reachable uint8
    decl ^Decl 
    external_name ^char
    result_register int 
    union {
         anonymousstruct {
            type ^Type 
            val Val 
        }
        package ^Package
    }
}

Package struct {
    path ^char
    full_path[PMAX_PATH]char
    decls ^^Decl 
    num_decls usize
    syms_map PMap

    syms ^^Sym 
    external_name ^char
    always_reachable  bool
}

enum {
    MAX_LOCAL_SYMS = 1024
}

current_package ^Package 
builtin_package ^Package 
package_map PMap 
package_list ^^Package 

enum {
    REACHABLE_NONE,
    REACHABLE_NATURAL,
    REACHABLE_FORCED,
}

reachable_phase uint8 = REACHABLE_NATURAL

get_package_sym(package ^Package, name ^char) ^Sym {
    return map_get(&package.syms_map, name)
}

add_package(package ^Package) {
    old_package: ^Package = map_get(&package_map, package.path)
    if (old_package != package) {
        #assert(!old_package)
        map_put(&package_map, package.path, package)
        buf_push(package_list, package)
    }
}

enter_package(new_package ^Package) ^Package {
    old_package: ^Package =  current_package
    current_package = new_package
    return old_package
}

leave_package(old_package ^Package) {
    current_package = old_package
}

reachable_syms ^^Sym 
sorted_syms ^^Sym 
local_syms[MAX_LOCAL_SYMS]Sym 
local_syms_end ^Sym = local_syms

is_local_sym(sym ^Sym) bool {
    return local_syms <= sym && sym < local_syms_end
}

sym_new(kind SymKind , name ^char, decl ^Decl) ^Sym {
    sym ^Sym = xcalloc(1, sizeof(Sym))
    sym.kind = kind
    sym.name = name
    sym.decl = decl
    sym.home_package = current_package
    set_resolved_sym(sym, sym)
    return sym
}

process_decl_notes(decl ^Decl, sym ^Sym) {
    foreign_note := get_decl_note(decl, foreign_name)
    if (foreign_note) {
        if (foreign_note.num_args > 1) {
            fatal_error(decl.pos, "@foreign takes 0 or 1 argument");
        }
        external_name ^char
        if (foreign_note.num_args == 0) {
            external_name = sym.name;
        } else {
            arg := foreign_note.args[0].expr
            if (arg.kind != EXPR_STR) {
                fatal_error(decl.pos, "@foreign argument 1 must be a string literal")
            }
            external_name = arg.str_lit.val
        }
        sym.external_name = external_name
    }
}

sym_decl(decl ^Decl) ^Sym {
    kind SymKind = SYM_NONE
    switch (decl.kind) {
    case DECL_STRUCT:
    case DECL_UNION:
    case DECL_TYPEDEF:
    case DECL_ENUM:
        kind = SYM_TYPE
    case DECL_VAR:
        kind = SYM_VAR
    case DECL_CONST:
        kind = SYM_CONST
    case DECL_FUNC:
        kind = SYM_FUNC
    default:
        #assert(0)
    }
    sym: ^Sym = sym_new(kind, decl.name, decl)
    set_resolved_sym(decl, sym)
    process_decl_notes(decl, sym)
    return sym
}

sym_get_local(name ^char) ^Sym {
    for (it := local_syms_end; it != local_syms; it--) {
        sym ^Sym = it-1
        if (sym.name == name) {
            return sym
        }
    }
    return NULL
}

sym_get(name ^char) ^Sym {
    sym: ^Sym = sym_get_local(name)
    return sym ? sym : get_package_sym(current_package, name)
}

sym_push_var(name ^char, type ^Type) bool {
    if (sym_get_local(name)) {
        return false
    }
    if (local_syms_end == local_syms + MAX_LOCAL_SYMS) {
        fatal("Too many local symbols")
    }
    /*local_syms_end++ = Sym{
        name = name,
        kind = SYM_VAR,
        state = SYM_RESOLVED,
        type = type,
    }
*/
    sym Sym 
    sym.name = name
    sym.kind = SYM_VAR
    sym.state = SYM_RESOLVED
    sym.type = type;
    *local_syms_end++ = sym

    return true
}

sym_enter() ^Sym {
    return local_syms_end
}

sym_leave(sym ^Sym ) {
    local_syms_end = sym
}

sym_global_put(name ^char, sym ^Sym) {
       old_sym ^Sym = map_get(&current_package.syms_map, name);
    // Allow overrides of external defined symbols but not of internally defined symbols
    if(pc_strcmp(name, "union") != 0){
    if (old_sym && !(sym.home_package == current_package && old_sym.home_package != current_package)) {
        if (sym == old_sym) {
            return;
        }
        if (sym.kind == SYM_PACKAGE && old_sym.kind == SYM_PACKAGE && sym.package == old_sym.package) {
            return;
        }
        pos SrcPos = sym.decl ? sym.decl.pos : pos_builtin;
        if (old_sym.decl) {
            warning(old_sym.decl.pos, "Previous definition of '%s'", name);
        }
        if (sym.home_package == current_package ) {
            fatal_error(pos, "Duplicate definition of symbol '%s'.", name);
        } else {
            fatal_error(pos, "Conflicting import of symbol %s into %s from %s and %s.", name, current_package.path, sym.home_package.path, old_sym.home_package.path);

        }
    }
}
    map_put(&current_package.syms_map, name, sym);
    buf_push(current_package.syms, sym);
}

sym_global_type(name ^char, type ^Type) ^Sym {

    name = str_intern(name)
    sym: ^Sym  = sym_new(SYM_TYPE, name, NULL)
    sym.state = SYM_RESOLVED
    sym.type = type
    sym.external_name = name
    sym_global_put(name, sym)
    return sym
}

sym_global_tuple(name ^char, type ^Type) ^Sym {
    sym: ^Sym  = sym_new(SYM_TYPE, name, NULL)
    sym.state = SYM_RESOLVED;
    sym.type = type;
    sym.external_name = name;
    old_package := enter_package(builtin_package)
    sym_global_put(name, sym)
    leave_package(old_package)
    buf_push(sorted_syms, sym)
    buf_push(reachable_syms, sym)
    sym.reachable = REACHABLE_NATURAL
    return sym
}

sym_global_decl(decl ^Decl) ^Sym {
    sym ^Sym = NULL;
    if (decl.name) {
        sym = sym_decl(decl);
        sym_global_put(sym.name, sym);
    }
    if (decl.kind == DECL_ENUM) {
        name :^char = sym ? sym.name : str_intern("int");
        enum_typespec := new_typespec_name(decl.pos, &name, 1);
        prev_item_name ^char = NULL;
        for (i usize = 0; i < decl.enum_decl.num_items; i++) {
            item : EnumItem = decl.enum_decl.items[i];
            init ^Expr;
            if (item.init) {
                init = item.init;
            } else if (prev_item_name) {
                init = new_expr_binary(item.pos, TOKEN_ADD, new_expr_name(item.pos, prev_item_name), new_expr_int(item.pos, 1, 0, 0));
            } else {
                init = new_expr_int(item.pos, 0, 0, 0);
            }
            item_decl : ^Decl = new_decl_const(item.pos, item.name, enum_typespec, init);
            item_decl.notes = decl.notes;
            sym_global_decl(item_decl);
            prev_item_name = item.name;
        }
    }
    return sym;
}

put_type_name(buf ^^char, type ^Type) {
    type_name := type_names[type.kind];
    if (type_name) {
        buf_printf(*buf, "%s", type_name);
    } else {
        switch (type.kind) {
        case PTYPE_STRUCT:
        case PTYPE_UNION:
        case PTYPE_ENUM:
        case PTYPE_INCOMPLETE:
            #assert(type.sym);
            buf_printf(*buf, "%s", type.sym.name)
        case PTYPE_CONST:
            put_type_name(buf, type.base);
            buf_printf(*buf, " const")
        case PTYPE_PTR:
            put_type_name(buf, type.base);
            buf_printf(*buf, "*")
        case PTYPE_ARRAY:
            put_type_name(buf, type.base);
            buf_printf(*buf, "[%zu]", type.num_elems)
        case PTYPE_FUNC:
            buf_printf(*buf, "func(");
            for (i usize = 0; i < type.t_func.num_params; i++) {
                if (i != 0) {
                    buf_printf(*buf, ", ");
                }
                put_type_name(buf, type.t_func.params[i]);
            }
            if (type.t_func.has_varargs) {
                buf_printf(*buf, "...");
            }
            buf_printf(*buf, ")");
            if (type.t_func.ret != type_void) {
                buf_printf(*buf, ": ");
                put_type_name(buf, type.t_func.ret);
            }
        case PTYPE_TUPLE:
            buf_printf(*buf, "{");
            for (i usize = 0; i < type.t_aggregate.num_fields; i++) {
                if (i != 0) {
                    buf_printf(*buf, ", ");
                }
                put_type_name(buf, type.t_aggregate.fields[i].type);
            }
            buf_printf(*buf, "}");
        default:
            #assert(0)
        }
    }
}

get_type_name(type ^Type) ^char {
    buf ^char = NULL
    put_type_name(&buf, type)
    return buf
}

Operand struct {
    type ^Type
    is_lvalue bool
    is_const bool
    val Val
}

operand_null Operand

operand_rvalue(type ^Type) Operand {
    return (:Operand){
        type = unqualify_type(type),
    }

}

operand_lvalue(type ^Type) Operand {
    return (:Operand){
        type = type,
        is_lvalue = true,
    }
}

operand_const(type ^Type, val Val) Operand {

 return (:Operand){
        type = unqualify_type(type),
        is_const = true,
        val = val,
    }
}

type_decay(type ^Type) ^Type {
    type = unqualify_type(type)
    if (type.kind == PTYPE_ARRAY) {
        type = type_ptr(type.base)
    }
    return type
}

operand_decay(operand Operand) Operand {
    operand.type = type_decay(operand.type)
    operand.is_lvalue = false
    return operand
}

is_convertible(operand ^Operand, dest ^Type) bool {
    dest = unqualify_type(dest);
    src := unqualify_type(operand.type);
    if (dest == src) {
        return true;
    } else if (is_func_type(src) && src.t_func.intrinsic) {
        return false;
    } else if (dest == type_any || dest == type_void) {
        return true;
    } else if (is_arithmetic_type(dest) && is_arithmetic_type(src)) {
        return true;
    } else if (is_ptr_like_type(dest) && is_null_ptr(*operand)) {
        return true;
    } else if (is_ptr_type(dest) && is_ptr_type(src)) {
        if (is_const_type(dest.base) && is_const_type(src.base)) {
            return dest.base.base == src.base.base || dest.base.base == type_void || src.base.base == type_void;
        } else if (is_aggregate_type(dest.base) && is_aggregate_type(src.base) && dest.base == src.base.t_aggregate.fields[0].type) {
            return true;
        } else {
            unqual_dest_base := unqualify_type(dest.base);
            if (unqual_dest_base == src.base) {
                return true;
            } else if (unqual_dest_base == type_void) {
                return is_const_type(dest.base) || !is_const_type(src.base);
            } else {
                return src.base == type_void;
            }
        }
    } else {
        return false;
    }
}

is_castable(operand ^Operand, dest ^Type) bool {
    src := operand.type
    if (is_convertible(operand, dest)) {
        return true
    } else if (is_integer_type(dest)) {
        return is_ptr_like_type(src)
    } else if (is_integer_type(src)) {
        return is_ptr_like_type(dest)
    } else if (is_ptr_like_type(dest) && is_ptr_like_type(src)) {
        return true
    } else {
        return false
    }
}

convert_operand(operand ^Operand, type ^Type) bool {
    if (is_convertible(operand, type)) {
        cast_operand(operand, type)
        operand.type = unqualify_type(operand.type);
        operand.is_lvalue = false
        return true
    }
    return false
}

type_allocator ^Type 
type_allocator_ptr ^Type 

is_null_ptr(operand Operand) bool {
    if (operand.is_const && (is_ptr_type(operand.type) || is_integer_type(operand.type))) {
        cast_operand(&operand, type_ullong)
        return operand.val.ull == 0
    } else {
        return false
    }
}

promote_operand(operand ^Operand) {
    switch (operand.type.kind) {
    case PTYPE_BOOL:
    case PTYPE_CHAR:
    case PTYPE_SCHAR:
    case PTYPE_UCHAR:
    case PTYPE_SHORT:
    case PTYPE_USHORT:
    case PTYPE_ENUM:
        cast_operand(operand, type_int);
    default:
        // Do nothing
    }
}

unify_arithmetic_operands(left ^Operand, right ^Operand) {
     if (left.type == type_double) {
        cast_operand(right, type_double);
    } else if (right.type == type_double) {
        cast_operand(left, type_double);
    } else if (left.type == type_float) {
        cast_operand(right, type_float);
    } else if (right.type == type_float) {
        cast_operand(left, type_float);
    } else {
        #assert(is_integer_type(left.type));
        #assert(is_integer_type(right.type));
        promote_operand(left);
        promote_operand(right);
        if (left.type != right.type) {
            if (is_signed_type(left.type) == is_signed_type(right.type)) {
                if (type_rank(left.type) <= type_rank(right.type)) {
                    cast_operand(left, right.type);
                } else {
                    cast_operand(right, left.type);
                }
            } else if (is_signed_type(left.type) && type_rank(right.type) >= type_rank(left.type)) {
                cast_operand(left, right.type);
            } else if (is_signed_type(right.type) && type_rank(left.type) >= type_rank(right.type)) {
                cast_operand(right, left.type);
            } else if (is_signed_type(left.type) && type_sizeof(left.type) > type_sizeof(right.type)) {
                cast_operand(right, left.type);            
            } else if (is_signed_type(right.type) && type_sizeof(right.type) > type_sizeof(left.type)) {
                cast_operand(left, right.type);
            } else { 
                type := unsigned_type(is_signed_type(left.type) ? left.type : right.type);
                cast_operand(left, type);
                cast_operand(right, type);
            }
        }
    }
    #assert(left.type == right.type);
}

resolved_val_map PMap 

get_resolved_val(ptr ^void) Val {
    u64 uint64 = map_get_uint64(&resolved_val_map, ptr);
    val Val 
    #assert(sizeof(val) == sizeof(u64));
    pc_memcpy(&val, &u64, sizeof(u64));
    return val;
}

set_resolved_val(ptr ^void, val Val) {
    u64 uint64 
    #assert(sizeof(val) == sizeof(u64))
    pc_memcpy(&u64, &val, sizeof(val))
    map_put_uint64(&resolved_val_map, ptr, u64)
}

reachable_map PMap 

set_reachable(ptr ^void) {
    map_put(&reachable_map, ptr, (:^void)reachable_phase)
}

get_reachable(ptr ^void) uint8 {
    return (: int)(: intptr)map_get(&reachable_map, ptr)
}

resolved_type_map PMap 

get_resolved_type(ptr ^void) ^Type {
    return map_get(&resolved_type_map, ptr)
}

resolved_sym_map PMap  

set_resolved_type(ptr ^void, type ^Type) {
    map_put(&resolved_type_map, ptr, type)
}

get_resolved_sym(ptr ^void) ^Sym {
    return map_get(&resolved_sym_map, ptr)
}

set_resolved_sym(ptr ^void, sym ^Sym) {
    if (!is_local_sym(sym)) {
        map_put(&resolved_sym_map, ptr, sym)
    }
}

resolved_expected_type_map PMap 

get_resolved_expected_type(expr ^Expr) ^Type{
    return map_get(&resolved_expected_type_map, expr)
}

set_resolved_expected_type(expr ^Expr, type ^Type) {
    if (expr && type) {
        map_put(&resolved_expected_type_map, expr, type)
    }
}

implicit_any_map PMap 

is_implicit_any(expr ^Expr) bool {
    return map_get(&implicit_any_map, expr) != NULL
}

set_implicit_any(expr ^Expr) {
    map_put(&implicit_any_map, expr, (: ^void)1)
}

type_conv_map PMap 

type_conv(expr ^Expr) ^Type {
    type: ^Type = map_get(&type_conv_map, expr)
    if (!type) {
        return NULL
    }
    return type
}

set_type_conv(expr ^Expr, type ^Type) {
    map_put(&type_conv_map, expr, type)
}

pointer_promo_map PMap 

pointer_promo_type(expr ^Expr) ^Type {
    type: ^Type = map_get(&pointer_promo_map, expr)
    if (!type) {
        return NULL
    }
    return type
}

set_pointer_promo_type(expr ^Expr, type ^Type) {
    map_put(&pointer_promo_map, expr, type)
}


resolve_expr_rvalue(expr ^Expr) Operand {
    return operand_decay(resolve_expr(expr))
}

resolve_expr(expr ^Expr) Operand {
    return resolve_expected_expr(expr, NULL)
}

resolve_expected_expr_rvalue(expr ^Expr, expected_type ^Type) Operand {
    return operand_decay(resolve_expected_expr(expr, expected_type))
}

incomplete_decay(type ^Type) ^Type {
    if (is_incomplete_array_type(type) || is_ptr_type(type)) {
        return type_ptr(incomplete_decay(type.base));
    } else {
        return type;
    }
}

resolve_typespec_strict(typespec ^Typespec, with_const bool) ^Type {
      if (!typespec) {
        return type_void;
    }
    result ^Type = NULL;
    switch (typespec.kind) {
    case TYPESPEC_NAME: {
        package := current_package;
        for (i := 0; i < typespec.num_names - 1; i++) {
            name := typespec.names[i];
            sym ^Sym = get_package_sym(package, name);
            if (!sym) {
                fatal_error(typespec.pos, "Unresolved package '%s'", name);
            }
            if (sym.kind != SYM_PACKAGE) {
                fatal_error(typespec.pos, "%s must denote a package", name);
                return NULL;
            }
            package = sym.package;
        }
        name := typespec.names[typespec.num_names - 1];
        sym := get_package_sym(package, name);
        if (!sym) {
            fatal_error(typespec.pos, "Unresolved type name '%s'", name);
        }
        if (sym.kind != SYM_TYPE) {
            fatal_error(typespec.pos, "%s must denote a type", name);
            return NULL;
        }
        resolve_sym(sym);
        set_resolved_sym(typespec, sym);
        result = sym.type
    }
    case TYPESPEC_CONST:
        result = resolve_typespec_strict(typespec.base, with_const);
        if (with_const) {
            result = type_const(result);
        }
    case TYPESPEC_PTR:
        result = type_ptr(resolve_typespec_strict(typespec.base, with_const));
    case TYPESPEC_ARRAY: {
        size := 0;
        base := resolve_typespec_strict(typespec.base, with_const);
        if (typespec.num_elems) {
            operand := resolve_const_expr(typespec.num_elems);
            if (!is_integer_type(operand.type)) {
                fatal_error(typespec.pos, "Array size constant expression must have integer type");
            }
            cast_operand(&operand, type_int);
            size = operand.val.i;
            if (size < 0) {
                fatal_error(typespec.num_elems.pos, "Non-positive array size");
            }
        }
        result = type_array(base, size, typespec.num_elems == NULL)
    }
    case TYPESPEC_FUNC: {
        args ^^Type = NULL;
        for (i := 0; i < typespec.ts_func.num_args; i++) {
            arg := resolve_typespec_strict(typespec.ts_func.args[i], with_const);
            if (arg == type_void) {
                fatal_error(typespec.pos, "Function parameter type cannot be void");
            }
            arg = incomplete_decay(arg);
            buf_push(args, arg);
        }
        ret := type_void;
        if (typespec.ts_func.ret) {
            ret = incomplete_decay(resolve_typespec_strict(typespec.ts_func.ret, with_const));
        }
        if (is_array_type(ret)) {
            fatal_error(typespec.pos, "Function return type cannot be array");
        }
        // TODO: func pointers should be able to support varargs (including typed)
        result = type_func(args, buf_len(args), ret, false, false, type_void);
    }
    case TYPESPEC_TUPLE: {
        fields ^^Type = NULL;
        for (i usize = 0; i < typespec.tuple.num_fields; i++) {
            field := resolve_typespec_strict(typespec.tuple.fields[i], with_const);
            if (field == type_void) {
                fatal_error(typespec.pos, "Tuple element types cannot be void");
            }
            buf_push(fields, field);
        }
        result = type_tuple(fields, buf_len(fields));
        if (!get_reachable(result)) {
            set_reachable(result);
        }
        break;
    }
    default:
        #assert(0);
        return NULL;
    }
    set_resolved_type(typespec, result);
    return result;
}

resolve_typespec(typespec ^Typespec) ^Type { 
    return resolve_typespec_strict(typespec, false)
}

complete_aggregate_strict(type ^Type, aggregate ^Aggregate, with_const bool) ^Type {
    fields ^TypeField = NULL;
    for (i usize = 0; i < aggregate.num_items; i++) {
        item := aggregate.items[i];
  
        if (item.kind == AGGREGATE_ITEM_FIELD) {
            item_type := resolve_typespec_strict(item.type, with_const);
            item_type = incomplete_decay(item_type);
            complete_type(item_type);

            if (type_sizeof(item_type) == 0){

               

               if (!is_array_type(item_type) || type_sizeof(item_type.base) == 0) {
                    fatal_error(item.pos, "Field type of size 0 is not allowed");
                }

            }

            
            for (j usize = 0; j < item.num_names; j++) {
                //printf("Yessir: %s\n", item.names[j]);
                buf_push(fields, (:TypeField){item.names[j], item_type});
            }
        
        
            

        }else {

            #assert(item.kind == AGGREGATE_ITEM_SUBAGGREGATE);
            item_type := complete_aggregate_strict(NULL, item.subaggregate, with_const);
            buf_push(fields, (:TypeField){NULL, item_type});
        }
    }
    if (!type) {
        type = type_incomplete(NULL);
        type.kind = PTYPE_COMPLETING;
    }
    if (aggregate.kind == AGGREGATE_STRUCT) {
        type_complete_struct(type, fields, buf_len(fields));
    } else {
        #assert(aggregate.kind == AGGREGATE_UNION);
        type_complete_union(type, fields, buf_len(fields));
    }
    if (type.t_aggregate.num_fields == 0) {
        fatal_error(aggregate.pos, "No fields");
    }
    if (has_duplicate_fields(type)) {
        fatal_error(aggregate.pos, "Duplicate fields");
    }
    return type;
}

complete_aggregate(type ^Type, aggregate ^Aggregate) ^Type {
    return complete_aggregate_strict(type, aggregate, type.sym && is_decl_foreign(type.sym.decl))
}

complete_type(type ^Type) {
if (type.kind == PTYPE_COMPLETING) {
        fatal_error(type.sym.decl.pos, "Type completion cycle");
        return;
    } else if (type.kind != PTYPE_INCOMPLETE) {
        return;
    }
    sym := type.sym;
    old_package := enter_package(sym.home_package);
    decl := sym.decl;
    if (decl.is_incomplete) {
        fatal_error(decl.pos, "Trying to use incomplete type as complete type");
    }
    type.kind = PTYPE_COMPLETING;
    #assert(decl.kind == DECL_STRUCT || decl.kind == DECL_UNION);
    complete_aggregate(type, decl.aggregate);
    buf_push(sorted_syms, type.sym);
    leave_package(old_package);
}

resolve_decl_type(decl ^Decl ) ^Type {
    #assert(decl.kind == DECL_TYPEDEF)
    return resolve_typespec(decl.typedef_decl.type)
}

resolve_typed_init(pos SrcPos, type ^Type, expr ^Expr) ^Type {
    expected_type := unqualify_type(type)
    operand := resolve_expected_expr(expr, expected_type);
    if (is_incomplete_array_type(type)) {
        if (is_array_type(operand.type) && type.base == operand.type.base) {
            // Incomplete array size, so infer the size from the initializer expression's type.
            type.num_elems = operand.type.num_elems;
            type.size = operand.type.size;
            type.incomplete_elems = false
            set_resolved_expected_type(expr, type)
            return type
        } else if (is_ptr_type(operand.type) && type.base == operand.type.base) {
            set_resolved_expected_type(expr, operand.type)
            return operand.type
        }
    }
    if (type && is_ptr_type(type)) {
        operand = operand_decay(operand)
    }
    if (!convert_operand(&operand, expected_type)) {
        return NULL
    }
    set_resolved_expected_type(expr, operand.type)
    return operand.type
}

resolve_init(pos SrcPos, typespec ^Typespec, expr ^Expr, was_const bool, is_undef bool) ^Type {
  type ^Type = NULL;
    inferred_type ^Type = NULL;
    declared_type ^Type = NULL;
    if (is_undef) {
        if (typespec) {
            type = resolve_typespec_strict(typespec, was_const);
            declared_type = type
        }
        if (!type) {
            fatal_error(pos, "Cannot use undef initializer without declared type");
        }
    } else if (typespec) {
        type = resolve_typespec_strict(typespec, was_const);
        declared_type = type
        if (expr) {
            type = resolve_typed_init(pos, declared_type, expr);
            inferred_type = type
            if (!inferred_type) {
                fatal_error(pos, "Invalid type in initialization. Expected %s", get_type_name(declared_type));
            }
        }
    } else {
        #assert(expr);
        type = unqualify_type(resolve_expr(expr).type);
        inferred_type = type
        if (is_array_type(type) && expr.kind != EXPR_COMPOUND) {
            type = type_decay(type);
            set_resolved_type(expr, type);
        }
        set_resolved_expected_type(expr, type);
    }
    complete_type(type);
    if (!expr || is_ptr_type(inferred_type)) {
        type = incomplete_decay(type);
    }
    if (type.size == 0) {
        fatal_error(pos, "Cannot declare variable of size 0");
    }
    return type;

}

resolve_decl_var(decl ^Decl) ^Type {
  #assert(decl.kind == DECL_VAR);
   return resolve_init(decl.pos, decl.d_var.type, decl.d_var.expr, is_decl_foreign(decl), false);
}

resolve_decl_const(decl ^Decl, val ^Val) ^Type{
  #assert(decl.kind == DECL_CONST);
    result := resolve_const_expr(decl.const_decl.expr);
    if (!is_scalar_type(result.type)) {
        fatal_error(decl.pos, "Const declarations must have scalar type");
    }
    if (decl.const_decl.type) {
        type := resolve_typespec(decl.const_decl.type);
        if (!convert_operand(&result, type)) {
            fatal_error(decl.pos, "Invalid type in constant declaration. Expected %s, got %s", get_type_name(type), get_type_name(result.type));
        }
    }
    val^ = result.val;
    return result.type;
}

resolve_decl_func(decl ^Decl) ^Type{
    #assert(decl.kind == DECL_FUNC);
    foreign := get_decl_note(decl, foreign_name) != NULL;
    intrinsic := get_decl_note(decl, intrinsic_name) != NULL;
    with_const := foreign;
    params ^^Type = NULL;
    for (i usize = 0; i < decl.d_func.num_params; i++) {
        param : ^Type = resolve_typespec_strict(decl.d_func.params[i].type, with_const);
        param = incomplete_decay(param);
        complete_type(param);
        if (param == type_void && !foreign) {
            fatal_error(decl.pos, "Function parameter type cannot be void");
        }
        buf_push(params, param);
    }
    ret_type := type_void;
    if (decl.d_func.ret_type) {
        ret_type = incomplete_decay(resolve_typespec_strict(decl.d_func.ret_type, with_const));
        complete_type(ret_type);
    }
    if (is_array_type(ret_type)) {
        fatal_error(decl.pos, "Function return type cannot be array");
    }
    varargs_type := type_void;
    if (decl.d_func.varargs_type) {
        varargs_type = incomplete_decay(resolve_typespec_strict(decl.d_func.varargs_type, with_const));
        complete_type(varargs_type);
        if (is_integer_type(varargs_type) && type_rank(varargs_type) < type_rank(type_int)) {
            fatal_error(decl.pos, "Integer varargs type must have same or higher rank than int");
        } else if (varargs_type == type_float) {
            fatal_error(decl.pos, "Floating varargs type must be double, not float");
        }
    }
    return type_func(params, buf_len(params), ret_type, intrinsic, decl.d_func.has_varargs, varargs_type);
}

StmtCtx struct {
    is_break_legal bool
    is_continue_legal bool
} 

Label struct {
    name ^char
    pos SrcPos 
    referenced bool 
    defined bool 
} 

enum { MAX_LABELS = 256 }

labels[MAX_LABELS]Label 
labels_end ^Label = labels

get_label(pos SrcPos, name ^char) ^Label {
    label ^Label 
    for (label = labels; label != labels_end; label++) {
        if (label.name == name) {
            return label
        }
    }
    if (label == labels + MAX_LABELS) {
        fatal_error(pos, "Too many labels")
    }
    label^ = (:Label){name = name, pos = pos}
    labels_end++
    return label
}

reference_label(pos SrcPos, name ^char) {
    label := get_label(pos, name)
    label.referenced = true
}

define_label(pos SrcPos, name ^char) {
    label := get_label(pos, name)
    if (label.defined) {
        fatal_error(pos, "Multiple definitions of label '%s'", name)
    }
    label.defined = true
}

resolve_labels() {
    for (label := labels; label != labels_end; label++) {
        if (label.referenced && !label.defined) {
            fatal_error(label.pos, "Label '%s' referenced but not defined", label.name)
        }
        if (label.defined && !label.referenced) {
            warning(label.pos, "Label '%s' defined but not referenced", label.name)
        }
    }
    labels_end = labels
}

is_cond_operand(operand Operand) bool{
    operand = operand_decay(operand)
    return is_scalar_type(operand.type)
}

resolve_cond_expr(expr ^Expr) {
    cond := resolve_expr_rvalue(expr)
    if (!is_cond_operand(cond)) {
        fatal_error(expr.pos, "Conditional expression must have scalar type")
    }
}

resolve_stmt_block(block StmtList, ret_type ^Type, ctx StmtCtx ) bool {
    scope := sym_enter()
    returns bool = false
    for (i usize = 0; i < block.num_stmts; i++) {
        returns = resolve_stmt(block.stmts[i], ret_type, ctx) || returns
    }
    sym_leave(scope)
    return returns
}

resolve_stmt_assign(stmt ^Stmt) {
    #assert(stmt.kind == STMT_ASSIGN);
    left_expr := stmt.assign.left;
    left := resolve_expr(left_expr);
    if (!left.is_lvalue) {
        fatal_error(stmt.pos, "Cannot assign to non-lvalue");
    }
    if (is_array_type(left.type)) {
        fatal_error(stmt.pos, "Cannot assign to array");
    }
    if (left.type.nonmodifiable) {
        fatal_error(stmt.pos, "Left-hand side of assignment has non-modifiable type");
    }
    assign_op_name := token_kind_name(stmt.assign.op);
    binary_op := assign_token_to_binary_token[stmt.assign.op];
    right_expr := stmt.assign.right;
    right := resolve_expected_expr_rvalue(right_expr, left.type);
    result Operand 
    if (stmt.assign.op == TOKEN_ASSIGN) {
        result = right;
    } else if (stmt.assign.op == TOKEN_ADD_ASSIGN || stmt.assign.op == TOKEN_SUB_ASSIGN) {
        if (left.type.kind == PTYPE_PTR && is_integer_type(right.type)) {
            if (unqualify_type(left.type.base) == type_void) {
                set_pointer_promo_type(left_expr, type_ptr(qualify_type(type_char, left.type.base)));
            }
            result = operand_rvalue(left.type);
        } else if (is_arithmetic_type(left.type) && is_arithmetic_type(right.type)) {
            result = resolve_expr_binary_op(binary_op, assign_op_name, stmt.pos, left, right, left_expr, right_expr);
        } else {
            fatal_error(stmt.pos, "Invalid operand types for %s", assign_op_name);
        }
    } else {
        result = resolve_expr_binary_op(binary_op, assign_op_name, stmt.pos, left, right, left_expr, right_expr);
    }
    if (!convert_operand(&result, left.type)) {
        fatal_error(stmt.pos, "Invalid type in assignment. Expected %s, got %s", get_type_name(left.type), get_type_name(result.type));
    }
}

resolve_stmt_init(stmt ^Stmt) {
  #assert(stmt.kind == STMT_INIT);
    type := resolve_init(stmt.pos, stmt.init.type, stmt.init.expr, false, stmt.init.is_undef);
    if (!sym_push_var(stmt.init.name, type)) {
        fatal_error(stmt.pos, "Shadowed definition of local symbol");
    }
}

resolve_static_assert(note Note) {
    if (note.num_args != 1) {
        fatal_error(note.pos, "#static_#assert takes 1 argument")
    }
    operand := resolve_const_expr(note.args[0].expr)
    if (!operand.val.ull) {
        fatal_error(note.pos, "#static_#assert failed")
    }
}

resolve_stmt(stmt ^Stmt, ret_type ^Type, ctx StmtCtx) bool {
  switch (stmt.kind) {
    case STMT_RETURN:
        if (stmt.expr) {
            operand := resolve_expected_expr_rvalue(stmt.expr, ret_type);
            if (!convert_operand(&operand, ret_type)) {
                fatal_error(stmt.pos, "Invalid type in return expression. Expected %s, got %s", get_type_name(ret_type), get_type_name(operand.type));
            }
        } else if (ret_type != type_void) {
            fatal_error(stmt.pos, "Empty return expression for function with non-void return type");
        }
        return true;
    case STMT_BREAK:
        if (!ctx.is_break_legal) {
            fatal_error(stmt.pos, "Illegal break");
        }
        return false;
    case STMT_CONTINUE:
        if (!ctx.is_continue_legal) {
            fatal_error(stmt.pos, "Illegal continue");
        }
        return false;
    case STMT_BLOCK:
        return resolve_stmt_block(stmt.block, ret_type, ctx);
    case STMT_NOTE:
        if (stmt.note.name == assert_name) {
            if (stmt.note.num_args != 1) {
                fatal_error(stmt.pos, "#assert takes 1 argument");
            }
            resolve_cond_expr(stmt.note.args[0].expr);
        } else if (stmt.note.name == static_assert_name) {
            resolve_static_assert(stmt.note);
        } else if (stmt.note.name == foreign_name) {
            // TODO: check args
        } else {
            warning(stmt.pos, "Unknown statement #directive '%s'", stmt.note.name);
        }
        return false;
    case STMT_IF: {
        scope := sym_enter();
        if (stmt.if_stmt.init) {
            resolve_stmt_init(stmt.if_stmt.init);
        }
        if (stmt.if_stmt.cond) {
            resolve_cond_expr(stmt.if_stmt.cond);
        } else if (!is_cond_operand(resolve_name_operand(stmt.pos, stmt.if_stmt.init.init.name))) {
            fatal_error(stmt.pos, "Conditional expression must have scalar type");
        }
        returns := resolve_stmt_block(stmt.if_stmt.then_block, ret_type, ctx);
        for (i := 0; i < stmt.if_stmt.num_elseifs; i++) {
            elseif := stmt.if_stmt.elseifs[i];
            resolve_cond_expr(elseif.cond);
            returns = resolve_stmt_block(elseif.block, ret_type, ctx) && returns;
        }
        if (stmt.if_stmt.else_block.stmts) {
            returns = resolve_stmt_block(stmt.if_stmt.else_block, ret_type, ctx) && returns;
        } else {
            returns = false;
        }
        sym_leave(scope);
        return returns;
    }
    case STMT_WHILE:
    case STMT_DO_WHILE:
        resolve_cond_expr(stmt.while_stmt.cond);
        ctx.is_break_legal = true;
        ctx.is_continue_legal = true;
        resolve_stmt_block(stmt.while_stmt.block, ret_type, ctx);
        return false;
    case STMT_FOR: {
        scope := sym_enter();
        if (stmt.for_stmt.init) {
            resolve_stmt(stmt.for_stmt.init, ret_type, ctx);
        }
        if (stmt.for_stmt.cond) {
            resolve_cond_expr(stmt.for_stmt.cond);
        }
        if (stmt.for_stmt.next) {
            resolve_stmt(stmt.for_stmt.next, ret_type, ctx);
        }
        ctx.is_break_legal = true;
        ctx.is_continue_legal = true;
        resolve_stmt_block(stmt.for_stmt.block, ret_type, ctx);
        sym_leave(scope);
        return false;
    }
    case STMT_SWITCH: {
        operand := resolve_expr_rvalue(stmt.switch_stmt.expr);
        if (!is_integer_type(operand.type)) {
            fatal_error(stmt.pos, "Switch expression must have integer type");
        }
        ctx.is_break_legal = true;
        returns := true;
        has_default := false;
        for (i := 0; i < stmt.switch_stmt.num_cases; i++) {
            switch_case := stmt.switch_stmt.cases[i];
            for (j := 0; j < switch_case.num_patterns; j++) {
                pattern := switch_case.patterns[j];
                start_expr := pattern.start;
                start_operand := resolve_const_expr(start_expr);
                if (!convert_operand(&start_operand, operand.type)) {
                    fatal_error(start_expr.pos, "Invalid type in switch case expression. Expected %s, got %s", get_type_name(operand.type), get_type_name(start_operand.type));
                }
                end_expr := pattern.end;
                if (end_expr) {
                    end_operand := resolve_const_expr(end_expr);
                    if (!convert_operand(&end_operand, operand.type)) {
                        fatal_error(end_expr.pos, "Invalid type in switch case expression. Expected %s, got %s", get_type_name(operand.type), get_type_name(end_operand.type));
                    }
                    convert_operand(&start_operand, type_llong);
                    set_resolved_val(start_expr, start_operand.val);
                    convert_operand(&end_operand, type_llong);
                    set_resolved_val(end_expr, end_operand.val);
                    if (end_operand.val.ll < start_operand.val.ll) {
                        fatal_error(start_expr.pos, "Case range end value cannot be less thn start value");
                    }
                    if (end_operand.val.ll - start_operand.val.ll >= 256) {
                        fatal_error(start_expr.pos, "Case range cannot span more than 256 values");
                    }
                }
            }
            if (switch_case.is_default) {
                if (has_default) {
                    fatal_error(stmt.pos, "Switch statement has multiple default clauses");
                }
                has_default = true;
            }
            if (switch_case.block.num_stmts > 1) {
                last_stmt := switch_case.block.stmts[switch_case.block.num_stmts - 1];
                if (last_stmt.kind == STMT_BREAK) {
                    warning(last_stmt.pos, "Case blocks already end with an implicit break");
                }
            }
            returns = resolve_stmt_block(switch_case.block, ret_type, ctx) && returns;
        }
        return returns && has_default;
    }
    case STMT_ASSIGN:
        resolve_stmt_assign(stmt);
        return false;
    case STMT_INIT:
        resolve_stmt_init(stmt);
        return false;
    case STMT_EXPR:
        resolve_expr(stmt.expr);
        return false;
    case STMT_LABEL:
        define_label(stmt.pos, stmt.label);
        return false;
    case STMT_GOTO:
        reference_label(stmt.pos, stmt.label);
        return false;
    case STMT_CF_RETURN:
        return true;
        
    default:
        #assert(0);
        return false;
    }
}

resolve_func_body(sym ^Sym) {
    decl := sym.decl;
    #assert(decl.kind == DECL_FUNC)
    #assert(sym.state == SYM_RESOLVED)
    if (decl.is_incomplete) {
        return;
    }
    old_package := enter_package(sym.home_package)
    scope := sym_enter()
    for (i usize = 0; i < decl.d_func.num_params; i++) {
        param := decl.d_func.params[i];
        param_type := resolve_typespec(param.type);
        param_type = incomplete_decay(param_type);
        if (is_array_type(param_type)) {
            param_type = type_ptr(param_type.base);
        }
        sym_push_var(param.name, param_type);
    }
    ret_type := incomplete_decay(resolve_typespec(decl.d_func.ret_type));
    #assert(!is_array_type(ret_type));
    returns := resolve_stmt_block(decl.d_func.block, ret_type, (:StmtCtx){0});
    resolve_labels();
    sym_leave(scope);
    if (ret_type != type_void && !returns) {
        fatal_error(decl.pos, "Not all control paths return values");
    }
    leave_package(old_package);
}

resolve_sym(sym ^Sym) {
   if (sym.state == SYM_RESOLVED) {
        return;
    } else if (sym.state == SYM_RESOLVING) {
        fatal_error(sym.decl.pos, "Cyclic dependency");
        return;
    }
    #assert(sym.state == SYM_UNRESOLVED);
    #assert(!sym.reachable);
    if (!is_local_sym(sym)) {
        buf_push(reachable_syms, sym);
        sym.reachable = reachable_phase;
    }
    sym.state = SYM_RESOLVING;
    decl := sym.decl;
    old_package := enter_package(sym.home_package);
    switch (sym.kind) {
    case SYM_TYPE:
        if (decl && decl.kind == DECL_TYPEDEF) {
            sym.type = resolve_typespec_strict(decl.typedef_decl.type, is_decl_foreign(decl));
        } else if (decl.kind == DECL_ENUM) {
            base := decl.enum_decl.type ? resolve_typespec(decl.enum_decl.type) : type_int;
            if (!is_integer_type(base)) {
                fatal_error(decl.pos, "Base type of enum must be integer type");
            }
            sym.type = type_enum(sym, base);
        } else {
            sym.type = type_incomplete(sym);
        }
    case SYM_VAR:
        sym.type = resolve_decl_var(decl)
    case SYM_CONST:
        sym.type = resolve_decl_const(decl, &sym.val)
    case SYM_FUNC:
        sym.type = resolve_decl_func(decl)
    case SYM_NONE: 
        break;
    case SYM_PACKAGE:
        // Do nothing
        break;
    default:
        *(:^int)0 = 0
       #assert(0);
    }
    leave_package(old_package);
    sym.state = SYM_RESOLVED;
    if (decl.is_incomplete || (decl.kind != DECL_STRUCT && decl.kind != DECL_UNION)) {
        buf_push(sorted_syms, sym);
    }
}

finalize_sym(sym ^Sym ) {
   #assert(sym.state == SYM_RESOLVED)
    if (sym.decl && !sym.decl.is_incomplete) {
        if (sym.kind == SYM_TYPE) {
            complete_type(sym.type)
        } else if (sym.kind == SYM_FUNC) {
            resolve_func_body(sym)
        }
    }
}

resolve_name(name ^char) ^Sym {
    sym : ^Sym = sym_get(name)
    if (!sym) {
        return NULL
    }
    resolve_sym(sym)
    return sym
}

try_resolve_package(expr ^Expr) ^Package {
    if (expr.kind == EXPR_NAME) {
        sym := resolve_name(expr.name)
        if (sym && sym.kind == SYM_PACKAGE) {
            return sym.package
        }
    } else if (expr.kind == EXPR_FIELD) {
        package := try_resolve_package(expr.field.expr)
        if (package) {
            sym: ^Sym = get_package_sym(package, expr.field.name)
            if (sym && sym.kind == SYM_PACKAGE) {
                return sym.package
            }
        }
    }
    return NULL
}

resolve_expr_field(expr ^Expr) Operand {
    #assert(expr.kind == EXPR_FIELD);
    package := try_resolve_package(expr.field.expr);
    if (package) {
        old_package := enter_package(package);
        sym := resolve_name(expr.field.name);
        operand := resolve_name_operand(expr.pos, expr.field.name);
        leave_package(old_package);
        set_resolved_sym(expr, sym);
        return operand;
    }
    operand := resolve_expr(expr.field.expr)
    was_const_type := is_const_type(operand.type);
    type := unqualify_type(operand.type);
    complete_type(type);
    if (is_ptr_type(type)) {
        operand = operand_lvalue(type.base);
        was_const_type = is_const_type(operand.type);
        type = unqualify_type(operand.type);
        complete_type(type);
    }
    if (!is_aggregate_type(type)) {    
        fatal_error(expr.pos, "Can only access fields on aggregates or pointers to aggregates");
        return operand_null;
    }
    for (i := 0; i < type.t_aggregate.num_fields; i++) {
        field := type.t_aggregate.fields[i];
        if (field.name == expr.field.name ) {
            field_operand := operand.is_lvalue ? operand_lvalue(field.type) : operand_rvalue(field.type);
            if (was_const_type) {
                field_operand.type = type_const(field_operand.type);
            }
        return field_operand;
      }
    }
    fatal_error(expr.pos, "No field named '%s'", expr.field.name);
    return operand_null;
}

eval_unary_op_ll(op TokenKind, val llong) llong {
    switch (op) {
    case TOKEN_ADD:
        return +val
    case TOKEN_SUB:
        return -val
    case TOKEN_NEG:
        return ~val
    case TOKEN_NOT:
        return !val
    default:
        #assert(0)

    }
    return 0
}

 eval_unary_op_ull(op TokenKind, val ullong) ullong {
    switch (op) {
    case TOKEN_ADD:
        return +val
    case TOKEN_SUB:
        return 0ull - val
    case TOKEN_NEG:
        return ~val
    case TOKEN_NOT:
        return !val
    default:
        #assert(0)

    }
    return 0
}

eval_binary_op_ll(op TokenKind, left llong, right llong) llong {
    switch (op) {
    case TOKEN_MUL:
        return left * right
    case TOKEN_DIV:
        return right != 0 ? left / right : 0
    case TOKEN_MOD:
        return right != 0 ? left % right : 0
    case TOKEN_AND:
        return left & right
    case TOKEN_LSHIFT:
        return left << right
    case TOKEN_RSHIFT:
        return left >> right
    case TOKEN_ADD:
        return left + right
    case TOKEN_SUB:
        return left - right
    case TOKEN_OR:
        return left | right;
    case TOKEN_XOR:
        return left | right;       
    case TOKEN_EQ:
        return left == right
    case TOKEN_NOTEQ:
        return left != right
    case TOKEN_LT:
        return left < right
    case TOKEN_LTEQ:
        return left <= right
    case TOKEN_GT:
        return left > right
    case TOKEN_GTEQ:
        return left >= right
    default:
        #assert(0)

    }
    return 0
}

eval_binary_op_ull(op TokenKind, left ullong, right ullong) ullong {
    switch (op) {
    case TOKEN_MUL:
        return left * right
    case TOKEN_DIV:
        return right != 0 ? left / right : 0
    case TOKEN_MOD:
        return right != 0 ? left % right : 0
    case TOKEN_AND:
        return left & right
    case TOKEN_LSHIFT:
        return left << right
    case TOKEN_RSHIFT:
        return left >> right
    case TOKEN_ADD:
        return left + right
    case TOKEN_SUB:
        return left - right
    case TOKEN_OR:
        return left | right
    case TOKEN_XOR:
        return left | right
    case TOKEN_EQ:
        return left == right
    case TOKEN_NOTEQ:
        return left != right
    case TOKEN_LT:
        return left < right
    case TOKEN_LTEQ:
        return left <= right
    case TOKEN_GT:
        return left > right
    case TOKEN_GTEQ:
        return left >= right
    default:
        #assert(0)
    }
    return 0
}

eval_unary_op(op TokenKind, type ^Type, val Val) Val{
    if (is_integer_type(type)) {
        operand := operand_const(type, val)
        if (is_signed_type(type)) {
            cast_operand(&operand, type_llong)
            operand.val.ll = eval_unary_op_ll(op, operand.val.ll)
        } else {
            cast_operand(&operand, type_ullong)
            operand.val.ll = eval_unary_op_ull(op, operand.val.ull)
        }
        cast_operand(&operand, type)
        return operand.val
    } else {
        return (:Val){0}
    }
}

eval_binary_op(op TokenKind, type ^Type, left Val, right Val) Val{
    if (is_integer_type(type)) {
        left_operand := operand_const(type, left)
        right_operand := operand_const(type, right)
        result_operand Operand 
        if (is_signed_type(type)) {
            cast_operand(&left_operand, type_llong)
            cast_operand(&right_operand, type_llong)
            result_operand = operand_const(type_llong, (:Val){ll = eval_binary_op_ll(op, left_operand.val.ll, right_operand.val.ll)})
        } else {
            cast_operand(&left_operand, type_ullong);
            cast_operand(&right_operand, type_ullong);
            result_operand = operand_const(type_ullong, (:Val){ull = eval_binary_op_ull(op, left_operand.val.ull, right_operand.val.ull)})
        }
        cast_operand(&result_operand, type)
        return result_operand.val
    } else {
        return (:Val){0}
    }
}

resolve_name_operand(pos SrcPos, name ^char) Operand {

    sym : ^Sym = resolve_name(name);

    if (!sym) {
        fatal_error(pos, "Unresolved name '%s'", name)
    }
    if (sym.kind == SYM_VAR) {
        operand : Operand = operand_lvalue(sym.type)
        if (is_array_type(operand.type) && !is_incomplete_array_type(operand.type)) {
            operand = operand_decay(operand);
        }
        return operand;
    } else if (sym.kind == SYM_CONST) {
        return operand_const(sym.type, sym.val);
    } else if (sym.kind == SYM_FUNC) {
        return operand_rvalue(sym.type);
    } else {

        //*(: ^int)0 = 0

        fatal_error(pos, "%s must be a var or const", name);
        return operand_null;
    }
}

resolve_expr_name(expr ^Expr) Operand {
    #assert(expr.kind == EXPR_NAME);
    return resolve_name_operand(expr.pos, expr.name);
}

resolve_unary_op(op TokenKind, operand Operand) Operand {
    promote_operand(&operand)
    if (operand.is_const) {
        return operand_const(operand.type, eval_unary_op(op, operand.type, operand.val))
    } else {
        return operand
    }
}

resolve_expr_unary(expr ^Expr) Operand{
    operand := resolve_expr_rvalue(expr.unary.expr);
    type := operand.type;
    switch (expr.unary.op) {
        case TOKEN_PTR:
         if (!is_ptr_type(type)) {
            fatal_error(expr.pos, "Cannot deref non-ptr type");
        }
        return operand_lvalue(type.base);
    case TOKEN_MUL:
        if (!is_ptr_type(type)) {
            fatal_error(expr.pos, "Cannot deref non-ptr type");
        }
        return operand_lvalue(type.base);
    case TOKEN_ADD:
    case TOKEN_SUB:
        if (!is_arithmetic_type(type)) {
            fatal_error(expr.pos, "Can only use unary %s with arithmetic types", token_kind_name(expr.unary.op));
        }
        return resolve_unary_op(expr.unary.op, operand);
    case TOKEN_NEG:
        if (!is_integer_type(type)) {
            fatal_error(expr.pos, "Can only use ~ with integer types");
        }
        return resolve_unary_op(expr.unary.op, operand);
    case TOKEN_NOT:
        if (!is_scalar_type(type)) {
            fatal_error(expr.pos," Can only use ! with scalar types");
        }
        return resolve_unary_op(expr.unary.op, operand);
    default:
        *(:^int) 0 = 0
        #assert(0);
        
    }
    return (:Operand){0}
}

resolve_binary_op(op TokenKind, left Operand, right Operand) Operand {
    if (left.is_const && right.is_const) {
        return operand_const(left.type, eval_binary_op(op, left.type, left.val, right.val))
    } else {
        return operand_rvalue(left.type)
    }
}

resolve_binary_arithmetic_op(op TokenKind, left Operand, right Operand) Operand {
    unify_arithmetic_operands(&left, &right)
    return resolve_binary_op(op, left, right)
}

compatible_pointer_arith(left ^Type, right ^Type, left_expr ^Expr, right_expr ^Expr) bool {
    if (is_ptr_type(left) && is_ptr_type(right)) {
        left_base := unqualify_type(left.base);
        right_base := unqualify_type(right.base);
        if (left_base == right_base) {
            return true;
        }
        if (left_base == type_void && right_base == type_char) {
            set_pointer_promo_type(left_expr, type_ptr(qualify_type(type_char, left.base)));
            return true;
        }
        if (left_base == type_char && right_base == type_void) {
            set_pointer_promo_type(right_expr, type_ptr(qualify_type(type_char, right.base)));
            return true;
        }
    }
    return false;
}

resolve_expr_binary_op(op TokenKind, op_name ^char, pos SrcPos, left Operand, right Operand, left_expr ^Expr, right_expr ^Expr) Operand {
    switch (op) {
    case TOKEN_MUL:
    case TOKEN_DIV:
        if (!is_arithmetic_type(left.type)) {
            fatal_error(pos, "Left operand of %s must have arithmetic type", op_name);
        }
        if (!is_arithmetic_type(right.type)) {
            fatal_error(pos, "Right operand of %s must have arithmetic type", op_name);
        }
        return resolve_binary_arithmetic_op(op, left, right);
    case TOKEN_MOD:
        if (!is_integer_type(left.type)) {
            fatal_error(pos, "Left operand of %% must have integer type");
        }
        if (!is_integer_type(right.type)) {
            fatal_error(pos, "Right operand of %% must have integer type");
        }
        return resolve_binary_arithmetic_op(op, left, right);
    case TOKEN_ADD:
        if (is_arithmetic_type(left.type) && is_arithmetic_type(right.type)) {
            return resolve_binary_arithmetic_op(op, left, right);
        } else if (is_ptr_type(left.type) && is_integer_type(right.type)) {
            complete_type(left.type.base);
            if (unqualify_type(left.type.base) == type_void) {
                promo_type ^Type = type_ptr(qualify_type(type_char, left.type.base));
                set_pointer_promo_type(left_expr, promo_type);
                left.type = promo_type;
            } else if (type_sizeof(left.type.base) == 0) {
                fatal_error(pos, "Cannot do pointer arithmetic with size 0 base type");
            }
            return operand_rvalue(left.type);
        } else if (is_ptr_type(right.type) && is_integer_type(left.type)) {
            complete_type(right.type.base);
            if (unqualify_type(right.type.base) == type_void) {
                promo_type ^Type = type_ptr(qualify_type(type_char, right.type.base));
                set_pointer_promo_type(right_expr, promo_type);
                right.type = promo_type;
            } else if (type_sizeof(right.type.base) == 0) {
                fatal_error(pos, "Cannot do pointer arithmetic with size 0 base type");
            }
            return operand_rvalue(right.type);
        } else {
            fatal_error(pos, "Operands of + must both have arithmetic type, or pointer and integer type");
        }
    case TOKEN_SUB:
        if (is_arithmetic_type(left.type) && is_arithmetic_type(right.type)) {
            return resolve_binary_arithmetic_op(op, left, right);
        } else if (is_ptr_type(left.type) && is_integer_type(right.type)) {
            left_base ^Type = unqualify_type(left.type.base);
            if (left_base == type_void) {
                promo_type ^Type = type_ptr(qualify_type(type_char, left_base));
                set_pointer_promo_type(left_expr, promo_type);
                left.type = promo_type;
            }
            return operand_rvalue(left.type);
        } else if (is_ptr_type(left.type) && is_ptr_type(right.type)) {
            if (!compatible_pointer_arith(left.type, right.type, left_expr, right_expr)) {
                fatal_error(pos, "Cannot subtract pointers to different types");
            }
            left_base ^Type = left.type.base;
            right_base ^Type = right.type.base;
            if (unqualify_type(left_base) == type_void && unqualify_type(right_base) == type_void) {
                set_pointer_promo_type(left_expr, type_ptr(type_char));
                set_pointer_promo_type(right_expr, type_ptr(type_char));
            }
            return operand_rvalue(type_ssize);
        } else {
            fatal_error(pos, "Operands of - must both have arithmetic type, pointer and integer type, or compatible pointer types");
        }
    case TOKEN_LSHIFT:
    case TOKEN_RSHIFT:
        if (is_integer_type(left.type) && is_integer_type(right.type)) {
            promote_operand(&left);
            promote_operand(&right);
            result_type ^Type = left.type;
            result Operand;
            if (is_signed_type(left.type)) {
                cast_operand(&left, type_llong);
                cast_operand(&right, type_llong);
            } else {
                cast_operand(&left, type_ullong);
                cast_operand(&right, type_ullong);
            }
            result = resolve_binary_op(op, left, right);
            cast_operand(&result, result_type);
            return result;
        } else {
            fatal_error(pos, "Operands of %s must both have integer type", op_name);
        }
    case TOKEN_EQ:
    case TOKEN_NOTEQ:
        if (is_arithmetic_type(left.type) && is_arithmetic_type(right.type)) {
            result Operand = resolve_binary_arithmetic_op(op, left, right);
            cast_operand(&result, type_int);
            return result;
        } else if (is_ptr_type(left.type) && is_ptr_type(right.type)) {
            unqual_left_base ^Type = unqualify_type(left.type.base);
            unqual_right_base ^Type = unqualify_type(right.type.base);
            if (unqual_left_base != unqual_right_base && unqual_left_base != type_void && unqual_right_base != type_void) {
                fatal_error(pos, "Cannot compare pointers to different types");
            }
            return operand_rvalue(type_int);
        } else if ((is_null_ptr(left) && is_ptr_type(right.type)) || (is_null_ptr(right) && is_ptr_type(left.type))) {
            return operand_rvalue(type_int);
        } else {
            fatal_error(pos, "Operands of %s must be arithmetic types or compatible pointer types", op_name);
        }
    case TOKEN_LT:
    case TOKEN_LTEQ:
    case TOKEN_GT:
    case TOKEN_GTEQ:
        if (is_arithmetic_type(left.type) && is_arithmetic_type(right.type)) {
            result Operand = resolve_binary_arithmetic_op(op, left, right);
            cast_operand(&result, type_int);
            return result;
        } else if (is_ptr_type(left.type) && is_ptr_type(right.type)) {
            left_base ^Type = unqualify_type(left.type.base);
            right_base ^Type = unqualify_type(right.type.base);
            if (left_base != right_base) {
                set_pointer_promo_type(right_expr, type_ptr(qualify_type(type_char, left.type.base)));
                set_pointer_promo_type(left_expr, type_ptr(qualify_type(type_char, left.type.base)));
            }
            return operand_rvalue(type_int);
        } else if ((is_null_ptr(left) && is_ptr_type(right.type)) || (is_null_ptr(right) && is_ptr_type(left.type))) {
            return operand_rvalue(type_int);
        } else {
            fatal_error(pos, "Operands of %s must be arithmetic types or compatible pointer types", op_name);
        }
    case TOKEN_AND:
    case TOKEN_XOR:
    case TOKEN_OR:
        if (is_integer_type(left.type) && is_integer_type(right.type)) {
            return resolve_binary_arithmetic_op(op, left, right);
        } else {
            fatal_error(pos, "Operands of %s must have arithmetic types", op_name);
        }
    case TOKEN_AND_AND:
    case TOKEN_OR_OR:
        if (is_scalar_type(left.type) && is_scalar_type(right.type)) {
            if (left.is_const && right.is_const) {
                cast_operand(&left, type_bool);
                cast_operand(&right, type_bool);
                i int
                if (op == TOKEN_AND_AND) {
                    i = left.val.b && right.val.b;
                } else {
                    #assert(op == TOKEN_OR_OR);
                    i = left.val.b || right.val.b;
                }
                return operand_const(type_int, (:Val){i = i});
            } else {
                return operand_rvalue(type_int);
            }
        } else {
            fatal_error(pos, "Operands of %s must have scalar types", op_name);
        }
    default:
        #assert(0)
    }
    return (:Operand){0};
}



resolve_expr_binary(expr ^Expr)  Operand {
    #assert(expr.kind == EXPR_BINARY)
    left := resolve_expr_rvalue(expr.binary.left)
    right := resolve_expr_rvalue(expr.binary.right)
    op := expr.binary.op
    op_name := token_kind_name(op)
    return resolve_expr_binary_op(op, op_name, expr.pos, left, right, expr.binary.left, expr.binary.right)
}

 resolve_expr_compound(expr ^Expr, expected_type ^Type) Operand {
    #assert(expr.kind == EXPR_COMPOUND);
    if (!expected_type && !expr.compound.type) {
        fatal_error(expr.pos, "Implicitly typed compound literals used in context without expected type");
    }
    type ^Type = NULL;
    if (expr.compound.type) {
        type = resolve_typespec(expr.compound.type);
    } else {
        type = expected_type;
    }
    complete_type(type);
    is_const := is_const_type(type);
    type = unqualify_type(type);
    if (type.kind == PTYPE_STRUCT || type.kind == PTYPE_UNION || type.kind == PTYPE_TUPLE) {
        index := 0;
        for (i := 0; i < expr.compound.num_fields; i++) {
            field := expr.compound.fields[i];
            if (field.kind == FIELD_INDEX) {
                fatal_error(field.pos, "Index field initializer not allowed for struct/union compound literal");
            } else if (field.kind == FIELD_NAME) {
                index = aggregate_item_field_index(type, field.name);
                if (index == -1) {
                    fatal_error(field.pos, "Named field in compound literal does not exist");
                }
            }
            if (index >= (:int)type.t_aggregate.num_fields) {
                fatal_error(field.pos, "Field initializer in struct/union compound literal out of range");
            }
            field_type := type.t_aggregate.fields[index].type;
            if (!resolve_typed_init(field.pos, field_type, field.init)) {
                fatal_error(field.pos, "Invalid type in compound literal initializer for aggregate type. Expected %s.", get_type_name(field_type));
            }
            index++;
        }
    } else if (type.kind == PTYPE_ARRAY || type.kind == PTYPE_PTR) {
        index := 0
        max_index := 0
        for (i := 0; i < expr.compound.num_fields; i++) {
            field := expr.compound.fields[i];
            if (field.kind == FIELD_NAME) {
                fatal_error(field.pos, "Named field initializer not allowed for array compound literals");
            } else if (field.kind == FIELD_INDEX) {
                operand := resolve_const_expr(field.index);
                if (!is_integer_type(operand.type)) {
                    fatal_error(field.pos, "Field initializer index expression must have type int");
                }
                if (!cast_operand(&operand, type_int)) {
                    fatal_error(field.pos, "Invalid type in field initializer index. Expected integer type");
                }
                if (operand.val.i < 0) {
                    fatal_error(field.pos, "Field initializer index cannot be negative");
                }
                index = operand.val.i;
            }
            if (type.num_elems && index >= (:int)type.num_elems) {
                fatal_error(field.pos, "Field initializer in array compound literal out of range");
            }
            if (!resolve_typed_init(field.pos, type.base, field.init)) {
                fatal_error(field.pos, "Invalid type in compound literal initializer for array type. Expected %s", get_type_name(type.base));
            }
            max_index = MAX(max_index, index);
            index++;
        }
        if (type.incomplete_elems) {
            type = type_array(type.base, max_index + 1, false);
        }
    } else {
        if (type == type_void) {
            fatal_error(expr.pos, "Anonymous compound literal in context expecting void type");
        }
        #assert(is_scalar_type(type));
        if (expr.compound.num_fields > 1) {
            fatal_error(expr.pos, "Compound literal for scalar type cannot have more than one operand");
        }
        if (expr.compound.num_fields == 1) {
            field := expr.compound.fields[0];
            init := resolve_expected_expr_rvalue(field.init, type);
            if (!convert_operand(&init, type)) {
                fatal_error(field.pos, "Invalid type in compound literal initializer. Expected %s, got %s", get_type_name(type), get_type_name(init.type));
            }
        }
    }
    return operand_lvalue(is_const ? type_const(type) : type);
}

resolve_expr_call_default(cd_func Operand, expr ^Expr) Operand {

  num_params := cd_func.type.t_func.num_params;
    for (i := 0; i < expr.call.num_args; i++) {
        param_type := i < num_params ? cd_func.type.t_func.params[i] : cd_func.type.t_func.varargs_type;
        arg := resolve_expected_expr_rvalue(expr.call.args[i], param_type);
        if (is_array_type(param_type)) {
            param_type = type_ptr(param_type.base);
        }
        if (!convert_operand(&arg, param_type)) {
            fatal_error(expr.call.args[i].pos, "Invalid type in function call argument. Expected %s, got %s", get_type_name(param_type), get_type_name(arg.type));
        }
    }
    return operand_rvalue(cd_func.type.t_func.ret);
} 

resolve_expr_call_intrinsic(ci_func Operand, expr ^Expr, expected_type ^Type) Operand {

    sym := get_resolved_sym(expr.call.expr);
    #assert(sym);
    if (sym.name == str_intern("va_arg")) {
       
        args Operand  = resolve_expr(expr.call.args[0]);
        if (!args.is_lvalue) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of va_arg must be lvalue");
        }
        arg Operand = resolve_expr(expr.call.args[1]);
        if (!arg.is_lvalue) {
            fatal_error(expr.call.args[0].pos, "Argument 2 of va_arg must be lvalue");
        }
        return operand_rvalue(ci_func.type.t_func.ret);
    } else if (sym.name == str_intern("aput")) {
        array Operand = resolve_expr(expr.call.args[0]);
        if (!is_ptr_type(array.type)) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have pointer type", sym.name);
        }
        if (!array.is_lvalue) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must be lvalue", sym.name);
        }
        base_type := unqualify_type(array.type.base);
        if (base_type == type_void) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have non-void base type", sym.name);
        }
        if (!is_aggregate_type(base_type) && base_type.t_aggregate.num_fields != 2) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have aggregate base type with 2 fields", sym.name);
        }
        base_key_type := base_type.t_aggregate.fields[0].type;
        if (type_padding(base_key_type)) {
            fatal_error(expr.call.args[1].pos, "Key type of %s must contain no padding", sym.name);
        }
        key := resolve_expected_expr_rvalue(expr.call.args[1], base_key_type);
        if (!convert_operand(&key, base_key_type)) {
            fatal_error(expr.call.args[1].pos, "Argument 2 of %s not convertible to argument 1's key type", sym.name);
        }
        base_value_type := base_type.t_aggregate.fields[1].type;
        value := resolve_expected_expr_rvalue(expr.call.args[2], base_value_type);
        if (!is_convertible(&value, base_value_type)) {
            fatal_error(expr.call.args[2].pos, "Argument 3 of %s not convertible to argument 1's value type", sym.name);
        }
        return operand_rvalue(ci_func.type.t_func.ret);
    } else if (sym.name == str_intern("ageti") || sym.name == str_intern("adel")) {
        array := resolve_expr(expr.call.args[0]);
        if (!is_ptr_type(array.type)) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have pointer type", sym.name);
        }
        if (unqualify_type(array.type.base) == type_void) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have non-void base type", sym.name);
        }
        base_type := unqualify_type(array.type.base);
        if (base_type == type_void) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have non-void base type", sym.name);
        }
        if (!is_aggregate_type(base_type) && base_type.t_aggregate.num_fields != 2) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have aggregate base type with 2 fields", sym.name);
        }
        base_key_type := base_type.t_aggregate.fields[0].type;
        if (type_padding(base_key_type)) {
            fatal_error(expr.call.args[1].pos, "Key type of %s must contain no padding", sym.name);
        }
        key := resolve_expected_expr_rvalue(expr.call.args[1], base_key_type);
        if (!convert_operand(&key, base_key_type)) {
            fatal_error(expr.call.args[1].pos, "Argument 2 of %s not convertible to argument 1's key type", sym.name);
        }
        return operand_rvalue(ci_func.type.t_func.ret);
    } else if (sym.name == str_intern("agetp")) {
        array := resolve_expr(expr.call.args[0]);
        if (!is_ptr_type(array.type)) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have pointer type", sym.name);
        }
        if (unqualify_type(array.type.base) == type_void) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have non-void base type", sym.name);
        }
        base_type := unqualify_type(array.type.base);
        if (base_type == type_void) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have non-void base type", sym.name);
        }
        if (!is_aggregate_type(base_type) && base_type.t_aggregate.num_fields != 2) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have aggregate base type with 2 fields", sym.name);
        }
        base_key_type := base_type.t_aggregate.fields[0].type;
        if (type_padding(base_key_type)) {
            fatal_error(expr.call.args[1].pos, "Key type of %s must contain no padding", sym.name);
        }
        key := resolve_expected_expr_rvalue(expr.call.args[1], base_key_type);
        if (!convert_operand(&key, base_key_type)) {
            fatal_error(expr.call.args[1].pos, "Argument 2 of %s not convertible to argument 1's key type", sym.name);
        }
        return operand_rvalue(type_ptr(array.type.base.t_aggregate.fields[1].type));
    } else if (sym.name == str_intern("aget")) {
        array := resolve_expr(expr.call.args[0]);
        if (!is_ptr_type(array.type)) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have pointer type", sym.name);
        }
        if (unqualify_type(array.type.base) == type_void) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have non-void base type", sym.name);
        }
        base_type := unqualify_type(array.type.base);
        if (base_type == type_void) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have non-void base type", sym.name);
        }
        if (!is_aggregate_type(base_type) && base_type.t_aggregate.num_fields != 2) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have aggregate base type with 2 fields", sym.name);
        }
        base_key_type := base_type.t_aggregate.fields[0].type;
        if (type_padding(base_key_type)) {
            fatal_error(expr.call.args[1].pos, "Key type of %s must contain no padding", sym.name);
        }
        key := resolve_expected_expr_rvalue(expr.call.args[1], base_key_type);
        if (!convert_operand(&key, base_key_type)) {
            fatal_error(expr.call.args[1].pos, "Argument 2 of %s not convertible to argument 1's key type", sym.name);
        }
        return operand_rvalue(array.type.base.t_aggregate.fields[1].type);
    } else if (sym.name == str_intern("apush") || sym.name == str_intern("aputv") || sym.name == str_intern("agetvi") || sym.name == str_intern("adelv")) {
        array := resolve_expr(expr.call.args[0]);
        if (!is_ptr_type(array.type)) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have pointer type", sym.name);
        }
        if (unqualify_type(array.type.base) == type_void) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have non-void base type", sym.name);
        }
        if (!array.is_lvalue) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must be lvalue", sym.name);
        }
        if (sym.name != str_intern("apush") && type_padding(array.type.base)) {
            fatal_error(expr.call.args[1].pos, "Base type of %s must contain no padding", sym.name);
        }
        elem := resolve_expected_expr_rvalue(expr.call.args[1], array.type.base);
        if (!convert_operand(&elem, array.type.base)) {
            fatal_error(expr.call.args[1].pos, "Argument 2 of %s not convertible to argument 1 base type", sym.name);
        }
        return operand_rvalue(ci_func.type.t_func.ret);
    } else if (sym.name == str_intern("agetvp")) {
        array := resolve_expr(expr.call.args[0]);
        if (!is_ptr_type(array.type)) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have pointer type", sym.name);
        }
        if (unqualify_type(array.type.base) == type_void) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have non-void base type", sym.name);
        }
        if (!array.is_lvalue) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must be lvalue", sym.name);
        }
        if (type_padding(array.type.base)) {
            fatal_error(expr.call.args[1].pos, "Base type of %s must contain no padding", sym.name);
        }
        elem := resolve_expected_expr_rvalue(expr.call.args[1], array.type.base);
        if (!convert_operand(&elem, array.type.base)) {
            fatal_error(expr.call.args[1].pos, "Argument 2 of %s not convertible to argument 1 base type", sym.name);
        }
        return operand_rvalue(array.type);
    } else if (sym.name == str_intern("agetv")) {
        array := resolve_expr(expr.call.args[0]);
        if (!is_ptr_type(array.type)) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have pointer type", sym.name);
        }
        if (unqualify_type(array.type.base) == type_void) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have non-void base type", sym.name);
        }
        if (!array.is_lvalue) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must be lvalue", sym.name);
        }
        if (type_padding(array.type.base)) {
            fatal_error(expr.call.args[1].pos, "Base type of %s must contain no padding", sym.name);
        }
        elem Operand  = resolve_expected_expr_rvalue(expr.call.args[1], array.type.base);
        if (!convert_operand(&elem, array.type.base)) {
            fatal_error(expr.call.args[1].pos, "Argument 2 of %s not convertible to argument 1 base type", sym.name);
        }
        return operand_rvalue(array.type.base);
    } else if (sym.name == str_intern("adefault")) {
        array := resolve_expr(expr.call.args[0]);
        if (!is_ptr_type(array.type)) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have pointer type", sym.name);
        }
        if (unqualify_type(array.type.base) == type_void) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have non-void base type", sym.name);
        }
        if (!array.is_lvalue) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must be lvalue", sym.name);
        }
        base_type := unqualify_type(array.type.base);
        if (base_type == type_void) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have non-void base type", sym.name);
        }
        if (!is_aggregate_type(base_type) && base_type.t_aggregate.num_fields != 2) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have aggregate base type with 2 fields", sym.name);
        }
        base_val_type := base_type.t_aggregate.fields[1].type;
        key := resolve_expected_expr_rvalue(expr.call.args[1], base_val_type);
        if (!convert_operand(&key, base_val_type)) {
            fatal_error(expr.call.args[1].pos, "Argument 2 of %s not convertible to argument 1's value type", sym.name);
        }
        return operand_rvalue(type_void);
    } else if (sym.name == str_intern("afill")) {
        array := resolve_expr(expr.call.args[0]);
        if (!is_ptr_type(array.type)) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have pointer type", sym.name);
        }
        if (unqualify_type(array.type.base) == type_void) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have non-void base type", sym.name);
        }
        if (!array.is_lvalue) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must be lvalue", sym.name);
        }
        elem := resolve_expected_expr_rvalue(expr.call.args[1], array.type.base);
        if (!convert_operand(&elem, array.type.base)) {
            fatal_error(expr.call.args[1].pos, "Argument 2 of %s not convertible to argument 1 base type", sym.name);
        }
        count := resolve_expected_expr_rvalue(expr.call.args[2], type_usize);
        if (!convert_operand(&count, type_usize)) {
            fatal_error(expr.call.args[2].pos, "Argument 3 of %s not convertible to usize", sym.name);
        }
        return operand_rvalue(ci_func.type.t_func.ret);
    } else if (sym.name == str_intern("acat")) {
        #assert(expr.call.num_args == 2);
        dest := resolve_expr(expr.call.args[0]);
        if (!is_ptr_type(dest.type)) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have pointer type", sym.name);
        }
        if (unqualify_type(dest.type.base) == type_void) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have non-void base type", sym.name);
        }
        if (!dest.is_lvalue) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of acat must be lvalue");
        }
        src := resolve_expr_rvalue(expr.call.args[1]);
        if (!is_ptr_type(src.type)) {
            fatal_error(expr.call.args[0].pos, "Argument 2 of %s must have pointer type", sym.name);
        }
        if (unqualify_type(src.type.base) == type_void) {
            fatal_error(expr.call.args[0].pos, "Argument 2 of %s must have non-void base type", sym.name);
        }
        if (dest.type.base != unqualify_type(src.type.base)) {
            fatal_error(expr.call.args[1].pos, "Argument 1 and 2 of acat don't have identical base types");
        }
        return operand_rvalue(ci_func.type.t_func.ret);
    } else if (sym.name == str_intern("acatn")) {
        #assert(expr.call.num_args == 3);
        dest := resolve_expr(expr.call.args[0]);
        src := resolve_expr_rvalue(expr.call.args[1]);
        if (!dest.is_lvalue) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of acat must be lvalue");
        }
        if (dest.type.base != unqualify_type(src.type.base)) {
            fatal_error(expr.call.args[1].pos, "Argument 1 and 2 of acatn don't have identical base types");
        }
        len := resolve_expr_rvalue(expr.call.args[2]);
        if (!convert_operand(&len, type_usize)) {
            fatal_error(expr.call.args[2].pos, "Argument 3 of acatn not convertible to usize");
        }
        return operand_rvalue(ci_func.type.t_func.ret);
    } else if (sym.name == str_intern("anew")) {
        #assert(expr.call.num_args == 1);
        allocator := resolve_expr_rvalue(expr.call.args[0]);
        if (!convert_operand(&allocator, type_allocator_ptr)) {
            fatal_error(expr.call.args[0].pos, "Argument 1 of %s must have type Allocator*", sym.name);
        }
        if (!expected_type || (!is_ptr_type(expected_type) && !is_array_type(expected_type))) {
            fatal_error(expr.pos, "anew can only be used when its inferred type is array or pointer type");
        }
        complete_type(expected_type.base);
        if (type_sizeof(expected_type.base) == 0) {
            fatal_error(expr.pos, "anew base type cannot be incomplete or have size 0");
        }
        return operand_rvalue(type_ptr(expected_type.base));
    } else {
        return resolve_expr_call_default(ci_func, expr);
    }
}

resolve_expr_call(expr ^Expr, expected_type ^Type) Operand {
    
 #assert(expr.kind == EXPR_CALL);
    if (expr.call.expr.kind == EXPR_NAME) {

        sym := resolve_name(expr.call.expr.name);

        if (sym && sym.kind == SYM_TYPE) {
            if (expr.call.num_args != 1) {
                fatal_error(expr.pos, "Type conversion operator takes 1 argument");
            }
            operand := resolve_expr_rvalue(expr.call.args[0]);
            if (!cast_operand(&operand, sym.type)) {
                fatal_error(expr.pos, "Invalid type cast from %s to %s", get_type_name(operand.type), get_type_name(sym.type));
            }
            set_resolved_sym(expr.call.expr, sym);
            return operand;
        }
    }
    call_func := resolve_expr_rvalue(expr.call.expr);
    if (call_func.type.kind != PTYPE_FUNC) {
        fatal_error(expr.pos, "Cannot call non-function value");
    }
    num_params := call_func.type.t_func.num_params;
    if (expr.call.num_args < num_params) {
        fatal_error(expr.pos, "Function call with too few arguments");
    }
    if (expr.call.num_args > num_params && !call_func.type.t_func.has_varargs) {
        fatal_error(expr.pos, "Function call with too many arguments");
    }
    if (call_func.type.t_func.intrinsic) {
        return resolve_expr_call_intrinsic(call_func, expr, expected_type);
    } else {
        return resolve_expr_call_default(call_func, expr);
    }
}

resolve_expr_ternary(expr ^Expr, expected_type ^Type) Operand {
    #assert(expr.kind == EXPR_TERNARY);
    cond := resolve_expr_rvalue(expr.ternary.cond);
    if (!is_scalar_type(cond.type)) {
        fatal_error(expr.pos, "Ternary conditional must have scalar type");
    }
    left := resolve_expected_expr_rvalue(expr.ternary.then_expr, expected_type);
    right := resolve_expected_expr_rvalue(expr.ternary.else_expr, expected_type);
    if (left.type == right.type) {
        return operand_rvalue(left.type);
    } else if (is_arithmetic_type(left.type) && is_arithmetic_type(right.type)) {
        unify_arithmetic_operands(&left, &right);
        if (cond.is_const && left.is_const && right.is_const) {
            return operand_const(left.type, cond.val.i ? left.val : right.val);
        } else {
            return operand_rvalue(left.type);
        }
    } else if (is_ptr_type(left.type) && is_null_ptr(right)) {
        return operand_rvalue(left.type);
    } else if (is_ptr_type(right.type) && is_null_ptr(left)) {
        return operand_rvalue(right.type);
    } else {
        if (is_ptr_type(left.type) && is_ptr_type(right.type)) {
            if (left.type.base == type_void && right.type.base == type_char) {
                return operand_rvalue(right.type);
            } else if (left.type.base == type_char && right.type.base == type_void) {
                return operand_rvalue(left.type);
            }
        }
        fatal_error(expr.pos, "Left and right operands of ternary expression must have arithmetic types or identical types");
    }

    printf("Weird\n")
    exit(-1)
    return operand_null

}

resolve_expr_index(expr ^Expr) Operand{
    #assert(expr.kind == EXPR_INDEX);
    index := resolve_expr_rvalue(expr.index.index);
    if (!is_integer_type(index.type)) {
        fatal_error(expr.pos, "Index must have integer type");
    }
    operand := resolve_expr(expr.index.expr);
    if (is_aggregate_type(operand.type)) {
        if (!index.is_const) {
            fatal_error(expr.pos, "Aggregate field index must be an integer constant");
        }
        convert_operand(&index, type_llong);
        set_resolved_val(expr.index.index, index.val);
        i := index.val.u;
        if (!(0 <= i && i < (:llong)operand.type.t_aggregate.num_fields)) {
            fatal_error(expr.pos, "Aggregate field index out of range");
        }
        operand.type = operand.type.t_aggregate.fields[i].type;
        return operand;
    }
    operand = operand_decay(operand);
    if (!is_ptr_type(operand.type)) {
        fatal_error(expr.pos, "Can only index aggregates, arrays and pointers");
    }
    return operand_lvalue(operand.type.base);
}

resolve_expr_cast(expr ^Expr) Operand {
    #assert(expr.kind == EXPR_CAST)
    type := resolve_typespec(expr.cast.type)
    operand := resolve_expected_expr_rvalue(expr.cast.expr, type)
    if (!cast_operand(&operand, type)) {
        fatal_error(expr.pos, "Invalid type cast from %s to %s", get_type_name(operand.type), get_type_name(type))
    }
    return operand
}

resolve_expr_int(expr ^Expr) Operand {
    #assert(expr.kind == EXPR_INT);
    int_max ullong = type_metrics[PTYPE_INT].max;
    uint_max ullong = type_metrics[PTYPE_UINT].max;
    long_max ullong = type_metrics[PTYPE_LONG].max;
    ulong_max ullong = type_metrics[PTYPE_ULONG].max;
    llong_max ullong = type_metrics[PTYPE_LLONG].max;
    val ullong = expr.int_lit.val;
    operand Operand  = operand_const(type_ullong, (:Val){ull = val});
    type ^Type = type_ullong;
    if (expr.int_lit.mod == MOD_NONE) {
        overflow bool  = false;
        switch (expr.int_lit.suffix) {
        case SUFFIX_NONE:
            type = type_int;
            if (val > int_max) {
                type = type_long;
                if (val > long_max) {
                    type = type_llong;
                    overflow = val > llong_max;
                }
            }
        case SUFFIX_U:
            type = type_uint;
            if (val > uint_max) {
                type = type_ulong;
                if (val > ulong_max) {
                    type = type_ullong;
                }
            }
        case SUFFIX_L:
            type = type_long;
            if (val > long_max) {
                type = type_llong;
                overflow = val > llong_max;
            }
        case SUFFIX_UL:
            type = type_ulong;
            if (val > ulong_max) {
                type = type_ullong;
            }
        case SUFFIX_LL:
            type = type_llong;
            overflow = val > llong_max;
        case SUFFIX_ULL:
            type = type_ullong;
        default:
            #assert(0);
        }
        if (overflow) {
            fatal_error(expr.pos, "Integer literal overflow");
        }
    } else {
        switch (expr.int_lit.suffix) {
        case SUFFIX_NONE:
            type = type_int;
            if (val > int_max) {
                type = type_uint;
                if (val > uint_max) {
                    type = type_long;
                    if (val > long_max) {
                        type = type_ulong;
                        if (val > ulong_max) {
                            type = type_llong;
                            if (val > llong_max) {
                                type = type_ullong;
                            }
                        }
                    }
                }
            }
        case SUFFIX_U:
            type = type_uint;
            if (val > uint_max) {
                type = type_ulong;
                if (val > ulong_max) {
                    type = type_ullong;
                }
            }
        case SUFFIX_L:
            type = type_long;
            if (val > long_max) {
                type = type_ulong;
                if (val > ulong_max) {
                    type = type_llong;
                    if (val > llong_max) {
                        type = type_ullong;
                    }
                }
            }
        case SUFFIX_UL:
            type = type_ulong;
            if (val > ulong_max) {
                type = type_ullong;
            }
        case SUFFIX_LL:
            type = type_llong;
            if (val > llong_max) {
                type = type_ullong;
            }
        case SUFFIX_ULL:
            type = type_ullong;
        default:
            #assert(0);
        }
    }
    cast_operand(&operand, type);
    return operand;
}

resolve_expr_modify(expr ^Expr) Operand {
    operand := resolve_expr(expr.modify.expr)
    type ^Type = operand.type
    complete_type(type)
    if (!operand.is_lvalue) {
        fatal_error(expr.pos, "Cannot modify non-lvalue")
    }
    if (type.nonmodifiable) {
        fatal_error(expr.pos, "Cannot modify non-modifiable type")
    }
    if (!(is_integer_type(type) || type.kind == PTYPE_PTR)) {
        fatal_error(expr.pos, "%s only valid for integer and pointer types", token_kind_name(expr.modify.op))
    }
    return operand_rvalue(type)
}

try_const_cast(operand ^Operand, expr ^Expr) {
    unqual := unqualify_ptr_type(operand.type)
    if (!operand.is_lvalue && unqual != operand.type) {
        set_type_conv(expr, unqual)
        operand.type = unqual
    }
}

resolve_expr_new(expr ^Expr, expected_type ^Type) Operand {
    if (expr.e_new_expr.alloc) {
        alloc := resolve_expr(expr.e_new_expr.alloc);
        if (!convert_operand(&alloc, type_allocator_ptr)) {
            fatal_error(expr.e_new_expr.alloc.pos, "Allocator of new must have type Allocator* or be pointer to struct with leading field of type Allocator");
        }
    }
    if (expr.e_new_expr.len) {
        len := resolve_expr_rvalue(expr.e_new_expr.len);
        if (!is_integer_type(len.type)) {
            fatal_error(expr.e_new_expr.len.pos, "Length argument of new must have integer type");
        }
    }
    expected_base ^Type  = NULL;
    if (is_ptr_type(expected_type)) {
        expected_base = expected_type.base;
    }
    if (!expr.e_new_expr.arg) {
        expected_type = type_decay(expected_type);
        if (!is_ptr_type(expected_type)) {
            fatal_error(expr.pos, "New with void argument must have expected pointer type");
        }
        return operand_rvalue(expected_type);
    } else {
        arg := resolve_expected_expr(expr.e_new_expr.arg, expr.e_new_expr.len ? expected_type : expected_base);
        if (expr.e_new_expr.len) {
            if (!is_ptr_type(arg.type)) {
                fatal_error(expr.e_new_expr.arg.pos, "Argument to new[] must have pointer type");
            }
        } else {
            if (!arg.is_lvalue) {
                fatal_error(expr.e_new_expr.arg.pos, "Argument to new must be lvalue");
            }
        }
        complete_type(arg.type);
        if (type_sizeof(arg.type) == 0) {
            fatal_error(expr.e_new_expr.arg.pos, "Type of argument to new has zero size");
        }
        return operand_rvalue(expr.e_new_expr.len ? arg.type : type_ptr(arg.type));
    }
}

resolve_expected_expr(expr ^Expr, expected_type ^Type) Operand {
   result Operand 
    switch (expr.kind) {
    case EXPR_PAREN:
        result = resolve_expected_expr(expr.paren.expr, expected_type)
    case EXPR_INT:
        result = resolve_expr_int(expr)
    case EXPR_FLOAT:
        result = operand_const(expr.float_lit.suffix == SUFFIX_D ? type_double : type_float, (:Val){0})
    case EXPR_STR:
        result = operand_rvalue(type_array(type_char, pc_strlen(expr.str_lit.val) + 1, false))
    case EXPR_NAME:
        result = resolve_expr_name(expr);
        set_resolved_sym(expr, resolve_name(expr.name))
    case EXPR_CAST:
        result = resolve_expr_cast(expr)
    case EXPR_CALL:
        result = resolve_expr_call(expr, expected_type)
    case EXPR_INDEX:
        result = resolve_expr_index(expr)
    case EXPR_FIELD:
        result = resolve_expr_field(expr)
    case EXPR_COMPOUND:
        result = resolve_expr_compound(expr, expected_type)
    case EXPR_UNARY:
        if (expr.unary.op == TOKEN_AND) {
            operand Operand
            if (expected_type && is_ptr_type(expected_type)) {
                operand = resolve_expected_expr(expr.unary.expr, expected_type.base);
            } else {
                operand = resolve_expr(expr.unary.expr);
            }
            if (!operand.is_lvalue) {
                fatal_error(expr.pos, "Cannot take address of non-lvalue");
            }
            result = operand_rvalue(type_ptr(operand.type));
        } else {
            result = resolve_expr_unary(expr);
        }
    case EXPR_BINARY:
        result = resolve_expr_binary(expr)
    case EXPR_TERNARY:
        result = resolve_expr_ternary(expr, expected_type)
    case EXPR_SIZEOF_EXPR: {
        if (expr.sizeof_expr.kind == EXPR_NAME) {
            sym := resolve_name(expr.sizeof_expr.name);
            if (sym && sym.kind == SYM_TYPE) {
                complete_type(sym.type);
                result = operand_const(type_usize, (:Val){ull = type_sizeof(sym.type)});
                set_resolved_type(expr.sizeof_expr, sym.type);
                set_resolved_sym(expr.sizeof_expr, sym);
                break;
            }
        }
        type := resolve_expr(expr.sizeof_expr).type;
        complete_type(type);
        result = operand_const(type_usize, (:Val){ull = type_sizeof(type)});
    }
    case EXPR_SIZEOF_TYPE: {
        type := resolve_typespec(expr.sizeof_type);
        complete_type(type);
        result = operand_const(type_usize, (:Val){ull = type_sizeof(type)});
    }
    case EXPR_ALIGNOF_EXPR: {
        if (expr.sizeof_expr.kind == EXPR_NAME) {
            sym := resolve_name(expr.alignof_expr.name);
            if (sym && sym.kind == SYM_TYPE) {
                complete_type(sym.type);
                result = operand_const(type_usize, (:Val){ull = type_alignof(sym.type)});
                set_resolved_type(expr.alignof_expr, sym.type);
                set_resolved_sym(expr.alignof_expr, sym);
                break;
            }
        }
        type := resolve_expr(expr.alignof_expr).type;
        complete_type(type);
        result = operand_const(type_usize, (:Val){ull = type_alignof(type)})
    }
    case EXPR_ALIGNOF_TYPE: {
        type := resolve_typespec(expr.alignof_type);
        complete_type(type);
        result = operand_const(type_usize, (:Val){ull = type_alignof(type)})
    }
    case EXPR_TYPEOF_TYPE: {
        type := resolve_typespec_strict(expr.typeof_type, true);
        result = operand_const(type_ullong, (:Val){ull = type.typeid});
    }
    case EXPR_TYPEOF_EXPR: {
        if (expr.typeof_expr.kind == EXPR_NAME) {
            sym := resolve_name(expr.typeof_expr.name);
            if (sym && sym.kind == SYM_TYPE) {
                result = operand_const(type_ullong, (:Val){ull = sym.type.typeid});
                set_resolved_type(expr.typeof_expr, sym.type);
                set_resolved_sym(expr.typeof_expr, sym);
                break;
            }
        }
        type := resolve_expr(expr.typeof_expr).type;
        result = operand_const(type_ullong, (:Val){ull = type.typeid});
    }
    case EXPR_OFFSETOF: {
        type := resolve_typespec(expr.offsetof_field.type);
        complete_type(type);
        if (type.kind != PTYPE_STRUCT && type.kind != PTYPE_UNION) {
            fatal_error(expr.pos, "offsetof can only be used with struct/union types");
        }
        field := aggregate_item_field_index(type, expr.offsetof_field.name);
        if (field < 0) {
            fatal_error(expr.pos, "No field '%s' in type", expr.offsetof_field.name);
        }
        result = operand_const(type_usize, (:Val){ull = type.t_aggregate.fields[field].offset});
    }
    case EXPR_MODIFY:
        result = resolve_expr_modify(expr);
    case EXPR_NEW:
        result = resolve_expr_new(expr, expected_type);
    default:
        #assert(0);
        result = operand_null;
    }
    try_const_cast(&result, expr);
    if (expected_type && unqualify_type(expected_type) == type_any && unqualify_type(result.type) != type_any) {
        set_implicit_any(expr);
        set_resolved_type(expr, type_decay(result.type));
    } else {
        set_resolved_type(expr, result.type);
    }
    return result;
}

resolve_const_expr(expr ^Expr) Operand {
    operand := resolve_expr(expr)

    if (!operand.is_const) {

       //*(:^int)0 = 0
        fatal_error(expr.pos, "Expected constant expression")
    }
    return operand
}

decl_note_names PMap 

init_builtin_syms() {
    #assert(current_package)
    sym_global_type("void", type_void)
    sym_global_type("bool", type_bool)
    sym_global_type("char", type_char)
    sym_global_type("schar", type_schar)
    sym_global_type("uchar", type_uchar)
    sym_global_type("short", type_short)
    sym_global_type("ushort", type_ushort)
    sym_global_type("int", type_int)
    sym_global_type("uint", type_uint)
    sym_global_type("long", type_long)
    sym_global_type("ulong", type_ulong)
    sym_global_type("llong", type_llong)
    sym_global_type("ullong", type_ullong)
    sym_global_type("float", type_float)
    sym_global_type("double", type_double)
}


postinit_builtin() {
    #assert(current_package == builtin_package)
    sym := resolve_name(str_intern("Allocator"))
    if (sym) {
        #assert(sym.kind == SYM_TYPE)
        type_allocator = sym.type
        type_allocator_ptr = type_ptr(type_allocator)
    }
}


add_internal_structs(aggregate ^Aggregate) {
    for(i usize = 0; i < aggregate.num_items; i++){
        item AggregateItem = aggregate.items[i];
        if(item.kind == AGGREGATE_ITEM_SUBAGGREGATE) {
            add_internal_structs(item.subaggregate)
        }
        else if(item.internal_struct) {
            sym_global_decl(item.internal_struct);
            if(item.internal_struct.aggregate) {
                add_internal_structs(item.internal_struct.aggregate)
            }
        }
    }
}

add_package_decls(package ^Package) {
  for (i usize = 0; i < package.num_decls; i++) {
        decl := package.decls[i]
        if(decl.kind == DECL_STRUCT){
        add_internal_structs(decl.aggregate)
        }
        if (decl.kind == DECL_NOTE) {
            if (!map_get(&decl_note_names, decl.note.name)) {
                warning(decl.pos, "Unknown declaration #directive '%s'", decl.note.name)
            }
            if (decl.note.name == declare_note_name) {
                if (decl.note.num_args != 1) {
                    fatal_error(decl.pos, "#declare_note takes 1 argument")
                }
                arg := decl.note.args[0].expr
                if (arg.kind != EXPR_NAME) {
                    fatal_error(decl.pos, "#declare_note argument must be name")
                }
                map_put(&decl_note_names, arg.name, (: ^void)1)
            } else if (decl.note.name == static_assert_name) {
                // TODO: decide how to handle top-level static asserts wrt laziness/tree shaking
                if (!flag_lazy) {
                    resolve_static_assert(decl.note)
                }
            }
        } else if (decl.kind == DECL_IMPORT) {
            // Add to list of imports
        } else {
            sym_global_decl(decl)
        }
    }
}

is_package_dir(search_path ^char, package_path ^char) bool {
    path[PMAX_PATH]char
    path_copy(path, search_path)
    path_join(path, package_path)
    iter DirListIter 
    for (dir_list(&iter, path); iter.valid; dir_list_next(&iter)) {
        ext := path_ext(iter.name)
        if ((ext != iter.name && pc_strcmp(ext, "p") == 0)) {
            dir_list_free(&iter)
            return true
        }
    }
    return false
    
}

copy_package_full_path(dest[PMAX_PATH]char, package_path ^char) bool {
    for (i int = 0; i < num_package_search_paths; i++) {
        if (is_package_dir(package_search_paths[i], package_path)) {
            path_copy(dest, package_search_paths[i])
            path_join(dest, package_path)
            return true
        }
    }
    return false
}


import_package(package_path ^char) ^Package {
    package_path = str_intern(package_path)
    package: ^Package = map_get(&package_map, package_path)
    if (!package) {
        package = xcalloc(1, sizeof(Package))
        package.path = package_path
        if (flag_verbose) {
            printf("Importing %s\n", package_path)
        }
        full_path[PMAX_PATH]char 
        if (!copy_package_full_path(full_path, package_path)) {
            return NULL
        }
        pc_strcpy(package.full_path, full_path)
        add_package(package)
        compile_package(package)
    }
    return package;
}


import_all_package_symbols(package ^Package) {
    // TODO: should have a more general mechanism
    main_name ^char = str_intern("main")
    for (i usize = 0; i < buf_len(package.syms); i++) {
        if (package.syms[i].home_package == package && package.syms[i].name != main_name) {
            sym_global_put(package.syms[i].name, package.syms[i])
        }
    }
}

import_package_symbols(decl ^Decl, package ^Package) {
    for (i usize = 0; i < decl.d_import.num_items; i++) {
        item ImportItem = decl.d_import.items[i]
        sym: ^Sym = get_package_sym(package, item.name)
        if (!sym) {
            fatal_error(decl.pos, "Symbol '%s' does not exist in package '%s'", item.name, package.path)
        }
        sym_global_put(item.rename ? item.rename : item.name, sym)
    }
}

process_package_imports(package ^Package) {
   for (i usize = 0; i < package.num_decls; i++) {
        decl := package.decls[i]
        if (decl.kind == DECL_NOTE) {
            if (decl.note.name == always_name) {
                package.always_reachable = true
            }
        } else if (decl.kind == DECL_IMPORT) {
            path_buf ^char = NULL
            if (decl.d_import.is_relative) {
                buf_printf(path_buf, "%s/", package.path)
            }
            for (k usize = 0; k < decl.d_import.num_names; k++) {
                if (!str_islower(decl.d_import.names[k])) {
                    fatal_error(decl.pos, "Import name must be lower case: '%s'", decl.d_import.names[k])
                }
                buf_printf(path_buf, "%s%s", k == 0 ? "" : "/", decl.d_import.names[k])
            }
            imported_package := import_package(path_buf)
            if (!imported_package) {
                fatal_error(decl.pos, "Failed to import package '%s'", path_buf)
            }
            buf_free(path_buf)
            import_package_symbols(decl, imported_package)
            if (decl.d_import.import_all) {
                import_all_package_symbols(imported_package)
            }
            sym_name :^char = decl.name ? decl.name : decl.d_import.names[decl.d_import.num_names - 1]
            sym := sym_new(SYM_PACKAGE, sym_name, decl)
            sym.package = imported_package
            sym_global_put(sym_name, sym)
        }
    }
}

source_memory_usage usize

parse_package(package ^Package) ^Package {
    decls ^^Decl = NULL;
    iter DirListIter;
    for (dir_list(&iter, package.full_path); iter.valid; dir_list_next(&iter)) {
        if (iter.is_dir || iter.name[0] == '_' || iter.name[0] == '.') {
            continue;
        }
        name[PMAX_PATH]char 
        path_copy(name, iter.name)
        ext := path_ext(name)
        if (ext == name || pc_strcmp(ext, "p") != 0 ) {
            continue;
        }
        index usize = -1
        ext[index] = 0
        if (is_excluded_target_filename(name)) {
            continue;
        }
        path[PMAX_PATH]char
        path_copy(path, iter.base)
        path_join(path, iter.name)
        path_absolute(path)
        code: ^char = read_file(path)
        if (!code) {
            fatal_error((:SrcPos){name = path}, "Failed to read source file")
        }
        source_memory_usage += pc_strlen(code);
        init_stream(str_intern(path), code)
        file_decls: ^Decls = parse_decls()
        for (i usize = 0; i < file_decls.num_decls; i++) {
            buf_push(decls, file_decls.decls[i])
        }
    }
    package.decls = decls
    package.num_decls = (:int)buf_len(decls)
    return package
}

compile_package(package ^Package) bool {
    if (!parse_package(package)) {
        printf("Failed to parse package\n")
        return false
    }

    old_package : ^Package = enter_package(package)
    if (buf_len(package_list) == 1) {
        init_builtin_syms()
    }
    if (builtin_package) {
        import_all_package_symbols(builtin_package)
    }
    add_package_decls(package)
    process_package_imports(package)
    leave_package(old_package)
    return true
}

resolve_package_syms(package ^Package) {
    old_package :^Package = enter_package(package)
    for (i usize = 0; i < buf_len(package.syms); i++) {
        if (package.syms[i].home_package == package) {
            resolve_sym(package.syms[i])
        }
    }
    leave_package(old_package)
}

finalize_reachable_syms() {
    if (flag_verbose) {
        printf("Finalizing reachable symbols\n")
    }
    prev_num_reachable usize = 0
    num_reachable usize = buf_len(reachable_syms)
    for (i usize = 0; i < num_reachable; i++) {
        finalize_sym(reachable_syms[i])
        if (i == num_reachable - 1) {
            if (flag_verbose) {
                printf("New reachable symbols:")
                for (k usize = prev_num_reachable; k < num_reachable; k++) {
                    printf(" %s/%s", reachable_syms[k].home_package.path, reachable_syms[k].name)
                }
                printf("\n")
            }
            prev_num_reachable = num_reachable
            num_reachable = buf_len(reachable_syms)
        }
    }
}

is_intrinsic(sym ^Sym) bool {
    if (!sym || sym.kind != SYM_FUNC) {
        return false
    }
    #assert(is_func_type(sym.type))
    return sym.type.t_func.intrinsic
}
