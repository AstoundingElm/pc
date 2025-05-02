
/*#define CASE(k, t) \
    case k: \
        switch (type.kind) { \
        case PTYPE_BOOL: \
            operand.val.b = (bool)operand.val.t; \
            break; \
        case PTYPE_CHAR: \
            operand.val.c = (char)operand.val.t; \
            break; \
        case PTYPE_UCHAR: \
            operand.val.uc = (unsigned char)operand.val.t; \
            break; \
        case PTYPE_SCHAR: \
            operand.val.sc = (signed char)operand.val.t; \
            break; \
        case PTYPE_SHORT: \
            operand.val.s = (short)operand.val.t; \
            break; \
        case PTYPE_USHORT: \
            operand.val.us = (unsigned short)operand.val.t; \
            break; \
        case PTYPE_INT: \
            operand.val.i = (int)operand.val.t; \
            break; \
        case PTYPE_UINT: \
            operand.val.u = (unsigned)operand.val.t; \
            break; \
        case PTYPE_LONG: \
            operand.val.l = (long)operand.val.t; \
            break; \
        case PTYPE_ULONG: \
            operand.val.ul = (unsigned long)operand.val.t; \
            break; \
        case PTYPE_LLONG: \
            operand.val.ll = (long long)operand.val.t; \
            break; \
        case PTYPE_ULLONG: \
            operand.val.ull = (unsigned long long)operand.val.t; \
            break; \
        case PTYPE_PTR: \
            if (is_ptr_type(operand.type) || is_null_ptr(*operand)) { \
                operand.val.p = (uintptr_t)operand.val.t; \
            } else { \
                operand.is_const = false; \
            } \
            break; \
        case PTYPE_FLOAT: \
        case PTYPE_DOUBLE: \
            break; \
        default: \
            operand.is_const = false; \
            break; \
        } \
        break;

*/


cast_operand(operand ^Operand, type ^Type) bool {
     qual_type := type;
    type = unqualify_type(type);
    operand.type = unqualify_type(operand.type);
    if (operand.type != type) {
        if (!is_castable(operand, type)) {
            return false;
        }
        if (operand.is_const) {
            if (is_floating_type(operand.type)) {
                operand.is_const = !is_integer_type(type);
            } else {
                if (type.kind == PTYPE_ENUM) {
                    type = type.base;
                }
                operand_type := operand.type;
                if (operand_type.kind == PTYPE_ENUM) {
                    operand_type = operand_type.base;
                }
                switch (operand.type.kind) {
                case PTYPE_BOOL: 
                       switch (type.kind) { 
        case PTYPE_BOOL: 
            operand.val.b = (:bool)operand.val.b
        case PTYPE_CHAR: 
            operand.val.c = (:char)operand.val.b
        case PTYPE_UCHAR: 
            operand.val.uc = (:uchar)operand.val.b
        case PTYPE_SCHAR: 
            operand.val.sc = (:schar)operand.val.b
        case PTYPE_SHORT: 
            operand.val.s = (:short)operand.val.b
        case PTYPE_USHORT: 
            operand.val.us = (:ushort)operand.val.b
        case PTYPE_INT: 
        case PTYPE_ENUM:
          
            operand.val.i = (:int)operand.val.b
        case PTYPE_UINT: 
            operand.val.u = (:unsigned)operand.val.b
        case PTYPE_LONG: 
            operand.val.l = (:long)operand.val.b
        case PTYPE_ULONG: 
            operand.val.ul = (:ulong)operand.val.b
        case PTYPE_LLONG: 
            operand.val.ll = (:llong)operand.val.b
        case PTYPE_ULLONG: 
            operand.val.ull = (:ullong)operand.val.b
        case PTYPE_PTR: 
            if (is_ptr_type(operand.type) || is_null_ptr(*operand)) { 
                operand.val.p = (:uintptr)operand.val.b
            } else { 
                operand.is_const = false
            } 
        case PTYPE_FLOAT: 
        case PTYPE_DOUBLE: 
        default: 

            operand.is_const = false
        
    }
case PTYPE_CHAR: 
                       switch (type.kind) { 
        case PTYPE_BOOL: 
            operand.val.b = (:bool)operand.val.i
        case PTYPE_CHAR: 
            operand.val.c = (:char)operand.val.i
        case PTYPE_UCHAR: 
            operand.val.uc = (:uchar)operand.val.i
        case PTYPE_SCHAR: 
            operand.val.sc = (:schar)operand.val.i
        case PTYPE_SHORT: 
            operand.val.s = (:short)operand.val.i
        case PTYPE_USHORT: 
            operand.val.us = (:ushort)operand.val.i
        case PTYPE_INT: 
            case PTYPE_ENUM:
            operand.val.i = (:int)operand.val.i
        case PTYPE_UINT: 
            operand.val.u = (:unsigned)operand.val.i
        case PTYPE_LONG: 
            operand.val.l = (:long)operand.val.i
        case PTYPE_ULONG: 
            operand.val.ul = (:ulong)operand.val.i
        case PTYPE_LLONG: 
            operand.val.ll = (:llong)operand.val.i
        case PTYPE_ULLONG: 
            operand.val.ull = (:ullong)operand.val.i
        case PTYPE_PTR: 
            if (is_ptr_type(operand.type) || is_null_ptr(*operand)) { 
                operand.val.p = (:uintptr)operand.val.i
            } else { 
                operand.is_const = false
            } 
        case PTYPE_FLOAT: 
        case PTYPE_DOUBLE: 
        default: 

            operand.is_const = false
        }
    

case PTYPE_UCHAR: 
                       switch (type.kind) { 
        case PTYPE_BOOL: 
            operand.val.b = (:bool)operand.val.uc
        case PTYPE_CHAR: 
            operand.val.c = (:char)operand.val.uc
        case PTYPE_UCHAR: 
            operand.val.uc = (:uchar)operand.val.uc
        case PTYPE_SCHAR: 
            operand.val.sc = (:schar)operand.val.uc
        case PTYPE_SHORT: 
            operand.val.s = (:short)operand.val.uc
        case PTYPE_USHORT: 
            operand.val.us = (:ushort)operand.val.uc
        case PTYPE_INT: 
            case PTYPE_ENUM:
            operand.val.i = (:int)operand.val.uc
        case PTYPE_UINT: 
            operand.val.u = (:unsigned)operand.val.uc
        case PTYPE_LONG: 
            operand.val.l = (:long)operand.val.uc
        case PTYPE_ULONG: 
            operand.val.ul = (:ulong)operand.val.uc
        case PTYPE_LLONG: 
            operand.val.ll = (:llong)operand.val.uc
        case PTYPE_ULLONG: 
            operand.val.ull = (:ullong)operand.val.uc
        case PTYPE_PTR: 
            if (is_ptr_type(operand.type) || is_null_ptr(*operand)) { 
                operand.val.p = (:uintptr)operand.val.uc
            } else { 
                operand.is_const = false
            } 
        case PTYPE_FLOAT: 
        case PTYPE_DOUBLE: 
        default: 

            operand.is_const = false
        }
    
     case PTYPE_SCHAR: 
                       switch (type.kind) { 
        case PTYPE_BOOL: 
            operand.val.b = (:bool)operand.val.sc
        case PTYPE_CHAR: 
            operand.val.c = (:char)operand.val.sc
        case PTYPE_UCHAR: 
            operand.val.uc = (:uchar)operand.val.sc
        case PTYPE_SCHAR: 
            operand.val.sc = (:schar)operand.val.sc
        case PTYPE_SHORT: 
            operand.val.s = (:short)operand.val.sc
        case PTYPE_USHORT: 
            operand.val.us = (:ushort)operand.val.sc
        case PTYPE_INT: 
            case PTYPE_ENUM:
            operand.val.i = (:int)operand.val.sc
        case PTYPE_UINT: 
            operand.val.u = (:unsigned)operand.val.sc
        case PTYPE_LONG: 
            operand.val.l = (:long)operand.val.sc
        case PTYPE_ULONG: 
            operand.val.ul = (:ulong)operand.val.sc
        case PTYPE_LLONG: 
            operand.val.ll = (:llong)operand.val.sc
        case PTYPE_ULLONG: 
            operand.val.ull = (:ullong)operand.val.sc
        case PTYPE_PTR: 
            if (is_ptr_type(operand.type) || is_null_ptr(*operand)) { 
                operand.val.p = (:uintptr)operand.val.sc
            } else { 
                operand.is_const = false
            } 
        case PTYPE_FLOAT: 
        case PTYPE_DOUBLE: 
        default: 

            operand.is_const = false
        
    }
     case PTYPE_SHORT: 
                       switch (type.kind) { 
        case PTYPE_BOOL: 
            operand.val.b = (:bool)operand.val.s
        case PTYPE_CHAR: 
            operand.val.c = (:char)operand.val.s
        case PTYPE_UCHAR: 
            operand.val.uc = (:uchar)operand.val.s
        case PTYPE_SCHAR: 
            operand.val.sc = (:schar)operand.val.s
        case PTYPE_SHORT: 
            operand.val.s = (:short)operand.val.s
        case PTYPE_USHORT: 
            operand.val.us = (:ushort)operand.val.s
        case PTYPE_INT: 
            case PTYPE_ENUM:

            operand.val.i = (:int)operand.val.s
        case PTYPE_UINT: 
            operand.val.u = (:unsigned)operand.val.s
        case PTYPE_LONG: 
            operand.val.l = (:long)operand.val.s
        case PTYPE_ULONG: 
            operand.val.ul = (:ulong)operand.val.s
        case PTYPE_LLONG: 
            operand.val.ll = (:llong)operand.val.s
        case PTYPE_ULLONG: 
            operand.val.ull = (:ullong)operand.val.s
        case PTYPE_PTR: 
            if (is_ptr_type(operand.type) || is_null_ptr(*operand)) { 
                operand.val.p = (:uintptr)operand.val.s
            } else { 
                operand.is_const = false
            } 
        case PTYPE_FLOAT: 
        case PTYPE_DOUBLE: 
        default: 

            operand.is_const = false
        }
    
     case PTYPE_USHORT: 
                       switch (type.kind) { 
        case PTYPE_BOOL: 
            operand.val.b = (:bool)operand.val.us
        case PTYPE_CHAR: 
            operand.val.c = (:char)operand.val.us
        case PTYPE_UCHAR: 
            operand.val.uc = (:uchar)operand.val.us
        case PTYPE_SCHAR: 
            operand.val.sc = (:schar)operand.val.us
        case PTYPE_SHORT: 
            operand.val.s = (:short)operand.val.us
        case PTYPE_USHORT: 
            operand.val.us = (:ushort)operand.val.us
        case PTYPE_INT: 
            case PTYPE_ENUM:
            operand.val.i = (:int)operand.val.us
        case PTYPE_UINT: 
            operand.val.u = (:unsigned)operand.val.us
        case PTYPE_LONG: 
            operand.val.l = (:long)operand.val.us
        case PTYPE_ULONG: 
            operand.val.ul = (:ulong)operand.val.us
        case PTYPE_LLONG: 
            operand.val.ll = (:llong)operand.val.us
        case PTYPE_ULLONG: 
            operand.val.ull = (:ullong)operand.val.us
        case PTYPE_PTR: 
            if (is_ptr_type(operand.type) || is_null_ptr(*operand)) { 
                operand.val.p = (:uintptr)operand.val.us
            } else { 
                operand.is_const = false
            } 
        case PTYPE_FLOAT: 
        case PTYPE_DOUBLE: 
        default: 

            operand.is_const = false
        }
    case PTYPE_ENUM:
     case PTYPE_INT: 
                       switch (type.kind) { 
        case PTYPE_BOOL: 
            operand.val.b = (:bool)operand.val.i
        case PTYPE_CHAR: 
            operand.val.c = (:char)operand.val.i
        case PTYPE_UCHAR: 
            operand.val.uc = (:uchar)operand.val.i
        case PTYPE_SCHAR: 
            operand.val.sc = (:schar)operand.val.i
        case PTYPE_SHORT: 
            operand.val.s = (:short)operand.val.i
        case PTYPE_USHORT: 
            operand.val.us = (:ushort)operand.val.i
             case PTYPE_ENUM:
        case PTYPE_INT: 
            
            // case PTYPE_ENUM:    operand.is_const = true;
            operand.val.i = (:int)operand.val.i
        case PTYPE_UINT: 
            operand.val.u = (:unsigned)operand.val.i
        case PTYPE_LONG: 
            operand.val.l = (:long)operand.val.i
        case PTYPE_ULONG: 
            operand.val.ul = (:ulong)operand.val.i
        case PTYPE_LLONG: 
            operand.val.ll = (:llong)operand.val.i
        case PTYPE_ULLONG: 
            operand.val.ull = (:ullong)operand.val.i
        case PTYPE_PTR: 
            if (is_ptr_type(operand.type) || is_null_ptr(*operand)) { 
                operand.val.p = (:uintptr)operand.val.i
            } else { 
                operand.is_const = false
            } 
        case PTYPE_FLOAT: 
        case PTYPE_DOUBLE: 
        default: 

            operand.is_const = false
        }
    
     case PTYPE_UINT: 
                       switch (type.kind) { 
        case PTYPE_BOOL: 
            operand.val.b = (:bool)operand.val.u
        case PTYPE_CHAR: 
            operand.val.c = (:char)operand.val.u
        case PTYPE_UCHAR: 
            operand.val.uc = (:uchar)operand.val.u
        case PTYPE_SCHAR: 
            operand.val.sc = (:schar)operand.val.u
        case PTYPE_SHORT: 
            operand.val.s = (:short)operand.val.u
        case PTYPE_USHORT: 
            operand.val.us = (:ushort)operand.val.u
             case PTYPE_ENUM:
        case PTYPE_INT: 
           
            operand.val.i = (:int)operand.val.u
        case PTYPE_UINT: 
            operand.val.u = (:unsigned)operand.val.u
        case PTYPE_LONG: 
            operand.val.l = (:long)operand.val.u
        case PTYPE_ULONG: 
            operand.val.ul = (:ulong)operand.val.u
        case PTYPE_LLONG: 
            operand.val.ll = (:llong)operand.val.u
        case PTYPE_ULLONG: 
            operand.val.ull = (:ullong)operand.val.u
        case PTYPE_PTR: 
            if (is_ptr_type(operand.type) || is_null_ptr(*operand)) { 
                operand.val.p = (:uintptr)operand.val.u
            } else { 
                operand.is_const = false
            } 
        case PTYPE_FLOAT: 
        case PTYPE_DOUBLE: 
        default: 

            operand.is_const = false
        }
    
     case PTYPE_LONG: 
                       switch (type.kind) { 
        case PTYPE_BOOL: 
            operand.val.b = (:bool)operand.val.l
        case PTYPE_CHAR: 
            operand.val.c = (:char)operand.val.l
        case PTYPE_UCHAR: 
            operand.val.uc = (:uchar)operand.val.l
        case PTYPE_SCHAR: 
            operand.val.sc = (:schar)operand.val.l
        case PTYPE_SHORT: 
            operand.val.s = (:short)operand.val.l
        case PTYPE_USHORT: 
            operand.val.us = (:ushort)operand.val.l
        case PTYPE_INT: 
            case PTYPE_ENUM:
            operand.val.i = (:int)operand.val.l
        case PTYPE_UINT: 
            operand.val.u = (:unsigned)operand.val.l
        case PTYPE_LONG: 
            operand.val.l = (:long)operand.val.l
        case PTYPE_ULONG: 
            operand.val.ul = (:ulong)operand.val.l
        case PTYPE_LLONG: 
            operand.val.ll = (:llong)operand.val.l
        case PTYPE_ULLONG: 
            operand.val.ull = (:ullong)operand.val.l
        case PTYPE_PTR: 
            if (is_ptr_type(operand.type) || is_null_ptr(*operand)) { 
                operand.val.p = (:uintptr)operand.val.l
            } else { 
                operand.is_const = false
            } 
        case PTYPE_FLOAT: 
        case PTYPE_DOUBLE: 
        default: 

            operand.is_const = false
        }
    
     case PTYPE_ULONG: 
                       switch (type.kind) { 
        case PTYPE_BOOL: 
            operand.val.b = (:bool)operand.val.ul
        case PTYPE_CHAR: 
            operand.val.c = (:char)operand.val.ul
        case PTYPE_UCHAR: 
            operand.val.uc = (:uchar)operand.val.ul
        case PTYPE_SCHAR: 
            operand.val.sc = (:schar)operand.val.ul
        case PTYPE_SHORT: 
            operand.val.s = (:short)operand.val.ul
        case PTYPE_USHORT: 
            operand.val.us = (:ushort)operand.val.ul
        case PTYPE_INT: 
            case PTYPE_ENUM:
            operand.val.i = (:int)operand.val.ul
        case PTYPE_UINT: 
            operand.val.u = (:unsigned)operand.val.ul
        case PTYPE_LONG: 
            operand.val.l = (:long)operand.val.ul
        case PTYPE_ULONG: 
            operand.val.ul = (:ulong)operand.val.ul
        case PTYPE_LLONG: 
            operand.val.ll = (:llong)operand.val.ul
        case PTYPE_ULLONG: 
            operand.val.ull = (:ullong)operand.val.ul
        case PTYPE_PTR: 
            if (is_ptr_type(operand.type) || is_null_ptr(*operand)) { 
                operand.val.p = (:uintptr)operand.val.ul
            } else { 
                operand.is_const = false
            } 
        case PTYPE_FLOAT: 
        case PTYPE_DOUBLE: 
        default: 

            operand.is_const = false
        }
    
     case PTYPE_LLONG: 
                       switch (type.kind) { 
        case PTYPE_BOOL: 
            operand.val.b = (:bool)operand.val.ll
        case PTYPE_CHAR: 
            operand.val.c = (:char)operand.val.ll
        case PTYPE_UCHAR: 
            operand.val.uc = (:uchar)operand.val.ll
        case PTYPE_SCHAR: 
            operand.val.sc = (:schar)operand.val.ll
        case PTYPE_SHORT: 
            operand.val.s = (:short)operand.val.ll
        case PTYPE_USHORT: 
            operand.val.us = (:ushort)operand.val.ll
        case PTYPE_INT: 
            case PTYPE_ENUM:
            operand.val.i = (:int)operand.val.ll
        case PTYPE_UINT: 
            operand.val.u = (:unsigned)operand.val.ll
        case PTYPE_LONG: 
            operand.val.l = (:long)operand.val.ll
        case PTYPE_ULONG: 
            operand.val.ul = (:ulong)operand.val.ll
        case PTYPE_LLONG: 
            operand.val.ll = (:llong)operand.val.ll
        case PTYPE_ULLONG: 
            operand.val.ull = (:ullong)operand.val.ll
        case PTYPE_PTR: 
            if (is_ptr_type(operand.type) || is_null_ptr(*operand)) { 
                operand.val.p = (:uintptr)operand.val.ll
            } else { 
                operand.is_const = false
            } 
        case PTYPE_FLOAT: 
        case PTYPE_DOUBLE: 
        default: 

            operand.is_const = false
        }
    
     case PTYPE_ULLONG: 
                       switch (type.kind) { 
        case PTYPE_BOOL: 
            operand.val.b = (:bool)operand.val.ull
        case PTYPE_CHAR: 
            operand.val.c = (:char)operand.val.ull
        case PTYPE_UCHAR: 
            operand.val.uc = (:uchar)operand.val.ull
        case PTYPE_SCHAR: 
            operand.val.sc = (:schar)operand.val.ull
        case PTYPE_SHORT: 
            operand.val.s = (:short)operand.val.ull
        case PTYPE_USHORT: 
            operand.val.us = (:ushort)operand.val.ull
        case PTYPE_INT: 
            case PTYPE_ENUM:
            operand.val.i = (:int)operand.val.ull
        case PTYPE_UINT: 
            operand.val.u = (:unsigned)operand.val.ull
        case PTYPE_LONG: 
            operand.val.l = (:long)operand.val.ull
        case PTYPE_ULONG: 
            operand.val.ul = (:ulong)operand.val.ull
        case PTYPE_LLONG: 
            operand.val.ll = (:llong)operand.val.ull
        case PTYPE_ULLONG: 
            operand.val.ull = (:ullong)operand.val.ull
        case PTYPE_PTR: 
            if (is_ptr_type(operand.type) || is_null_ptr(*operand)) { 
                operand.val.p = (:uintptr)operand.val.ull
            } else { 
                operand.is_const = false
            } 
        case PTYPE_FLOAT: 
        case PTYPE_DOUBLE: 
        default: 

            operand.is_const = false
        }
    
     case PTYPE_PTR: 
                       switch (type.kind) { 
        case PTYPE_BOOL: 
            operand.val.b = (:bool)operand.val.p
        case PTYPE_CHAR: 
            operand.val.c = (:char)operand.val.p
        case PTYPE_UCHAR: 
            operand.val.uc = (:uchar)operand.val.p
        case PTYPE_SCHAR: 
            operand.val.sc = (:schar)operand.val.p
        case PTYPE_SHORT: 
            operand.val.s = (:short)operand.val.p
        case PTYPE_USHORT: 
            operand.val.us = (:ushort)operand.val.p
        case PTYPE_INT: 
            case PTYPE_ENUM:
            operand.val.i = (:int)operand.val.p
        case PTYPE_UINT: 
            operand.val.u = (:unsigned)operand.val.p
        case PTYPE_LONG: 
            operand.val.l = (:long)operand.val.p
        case PTYPE_ULONG: 
            operand.val.ul = (:ulong)operand.val.p
        case PTYPE_LLONG: 
            operand.val.ll = (:llong)operand.val.p
        case PTYPE_ULLONG: 
            operand.val.ull = (:ullong)operand.val.p
        case PTYPE_PTR: 
            if (is_ptr_type(operand.type) || is_null_ptr(*operand)) { 
                operand.val.p = (:uintptr)operand.val.p
            } else { 
                operand.is_const = false
            } 
        case PTYPE_FLOAT: 
        case PTYPE_DOUBLE: 
        default: 

            operand.is_const = false
        }
    
                /*
                CASE(TYPE_BOOL, b)
                CASE(TYPE_CHAR, c)
                CASE(TYPE_UCHAR, uc)
                CASE(TYPE_SCHAR, sc)
                CASE(TYPE_SHORT, s)
                CASE(TYPE_USHORT, us)
                CASE(TYPE_INT, i)
                CASE(TYPE_UINT, u)
                CASE(TYPE_LONG, l)
                CASE(TYPE_ULONG, ul)
                CASE(TYPE_LLONG, ll)
                CASE(TYPE_ULLONG, ull)
                CASE(TYPE_PTR, p)*/
                default:
                    //printf("huh?\n")
                    operand.is_const = false
                }
            }
        }
    }
    operand.type = qual_type
    return true
}

